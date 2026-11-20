#!/usr/bin/env bash
# init-firewall [DOMAIN|CIDR]... — default-deny egress for running an agent unattended.
# Adapted from anthropics/claude-code's .devcontainer/init-firewall.sh.
#
# Opt-in per repo (needs NET_ADMIN/NET_RAW; see README):
#   "runArgs": ["--cap-add=NET_ADMIN", "--cap-add=NET_RAW"],
#   "postStartCommand": "sudo /usr/local/bin/init-firewall vault.example.com 10.0.0.0/8"
#
# Allowed out: DNS, loopback, the host's /24 (Docker Desktop's gateway), GitHub's published
# ranges, the Claude/VS Code endpoints below, and the DOMAIN/CIDR arguments. Everything else,
# IPv6 included, is rejected.
#
# Lockdown, on first run:
#   - vscode's blanket sudo (/etc/sudoers.d/vscode, from the base image) is removed. Without
#     that, anything in here could `sudo iptables -F`. Only this script stays sudo-able.
#   - the allowlist is frozen to that run's arguments. Later runs (every container start, or
#     by hand to re-resolve rotated IPs) must pass the same ones, so the agent cannot widen
#     it. Changing it means editing devcontainer.json and rebuilding the container.
#
# Known gaps: DNS (port 53) is open to any resolver, so DNS tunnelling is possible; domains
# are resolved once, so a CDN rotating IPs breaks access until the next run. Flushes every
# iptables rule, so it does not combine with docker-in-docker.
set -euo pipefail
IFS=$'\n\t'

state=/etc/init-firewall
defaults=(
  api.anthropic.com
  claude.ai
  platform.claude.com
  console.anthropic.com
  sentry.io
  marketplace.visualstudio.com
  vscode.blob.core.windows.net
  update.code.visualstudio.com
)
domain_re='^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'
ipv4_re='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
cidr_re='^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'

die() { echo "init-firewall: $*" >&2; exit 1; }

[[ $(id -u) == 0 ]] || die "must run as root (sudo /usr/local/bin/init-firewall)"

# Arguments are attacker-reachable through sudo: accept only plain domains and IPv4 CIDRs.
for a in "$@"; do
  [[ $a =~ $domain_re || $a =~ $cidr_re ]] || die "not a lowercase domain or IPv4 CIDR: '$a'"
done

# ── freeze the allowlist ──────────────────────────────────────────────────────
requested=$(printf '%s\n' "$@" | sort -u)
if [[ -f $state/allow ]]; then
  [[ $requested == "$(cat "$state/allow")" ]] \
    || die "allowlist is fixed for this container ($state/allow); rebuild to change it"
else
  install -d -m 755 "$state"
  printf '%s\n' "$requested" > "$state/allow"
  chmod 444 "$state/allow"
fi

if [[ -f /etc/sudoers.d/vscode ]]; then
  rm -f /etc/sudoers.d/vscode
  echo "init-firewall: removed vscode's blanket sudo; only init-firewall stays sudo-able"
fi

# ── resolve everything first ──────────────────────────────────────────────────
# Before touching the rules: on a re-run the current ones (DROP policy) still allow GitHub and
# DNS, and egress never opens while this runs.
allowed=()

meta=$(curl -fsS --connect-timeout 10 https://api.github.com/meta) \
  || die "could not fetch https://api.github.com/meta"
jq -e '.web and .api and .git' >/dev/null <<<"$meta" || die "GitHub meta missing web/api/git"
while read -r cidr; do
  [[ $cidr =~ $cidr_re ]] || die "unexpected range in GitHub meta: '$cidr'"
  allowed+=("$cidr")
done < <(jq -r '(.web + .api + .git)[] | select(contains(":") | not)' <<<"$meta" | aggregate -q)

add_domain() {
  local ips ip
  ips=$(dig +short A "$1" | grep -E "$ipv4_re" || true)
  if [[ -z $ips ]]; then
    echo "init-firewall: warning: $1 did not resolve; not allowed" >&2
    return
  fi
  while read -r ip; do allowed+=("$ip"); done <<<"$ips"
}
for d in "${defaults[@]}"; do add_domain "$d"; done
for a in "$@"; do
  if [[ $a =~ $cidr_re ]]; then allowed+=("$a"); else add_domain "$a"; fi
done

gw=$(ip -4 route show default | awk '{print $3; exit}')
[[ $gw =~ $ipv4_re ]] || die "could not detect the default gateway"

# ── reset, keeping Docker's embedded DNS (127.0.0.11) NAT rules ───────────────
docker_dns=$(iptables-save -t nat | grep '127\.0\.0\.11' || true)
for t in filter nat mangle; do iptables -t "$t" -F; iptables -t "$t" -X; done
ipset destroy allowed 2>/dev/null || true
if [[ -n $docker_dns ]]; then
  iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
  iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
  while IFS= read -r rule; do
    IFS=' ' read -ra parts <<<"$rule"
    iptables -t nat "${parts[@]}"
  done <<<"$docker_dns"
fi

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ── allowlist ─────────────────────────────────────────────────────────────────
ipset create allowed hash:net
for e in "${allowed[@]}"; do ipset add allowed "$e" -exist; done

iptables -A OUTPUT -d "${gw%.*}.0/24" -j ACCEPT
iptables -A INPUT -s "${gw%.*}.0/24" -j ACCEPT

iptables -A OUTPUT -m set --match-set allowed dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# IPv6 has no allowlist: loopback only. Absent v6 support means nothing to close.
if ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A INPUT -i lo -j ACCEPT
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT DROP
fi

# ── verify ────────────────────────────────────────────────────────────────────
if curl -fsS --connect-timeout 5 -o /dev/null https://example.com 2>/dev/null; then
  die "verification failed: https://example.com is reachable"
fi
curl -sS --connect-timeout 5 -o /dev/null https://api.github.com/zen \
  || die "verification failed: https://api.github.com is unreachable"
curl -sS --connect-timeout 5 -o /dev/null https://api.anthropic.com \
  || die "verification failed: https://api.anthropic.com is unreachable"
echo "init-firewall: egress restricted ($(ipset list allowed | grep -c '^[0-9]') entries)"
