# syntax=docker/dockerfile:1
# Unquoted $VARs are pinned version ARGs and $GH; they never contain spaces or globs.
# hadolint global ignore=SC2086
# A general-purpose devcontainer image, published to ghcr.io/pampatzoglou/devcontainer.
# Plain buildx (`task build`; .github/actions/build-push in CI); no devcontainer features are
# installed (language toolchains are opt-in features; see README). The devcontainer settings
# consumers inherit are the devcontainer.metadata LABEL at the end of the final stage.
#
# Every download is checked against the committed <TOOL>_SHA256_<ARCH> ARGs below it, never
# against upstream's sums file at build time. After bumping a version, `task pin` refreshes
# them; a stale hash fails the build by name. The AWS CLI is checked by GPG signature instead
# (it publishes no sums), python by uv.
#
# One stage per tool: fetched in parallel, cached independently; COPY --link keeps a version
# bump from invalidating the other layers.

# ── versions (the manifest) ─────────────────────────────────────────────────
# Bump a version, then `task pin` (hashes) or `task lock` (pre-commit). Take releases that are
# >= 3 days old, matching the Dependabot cooldown.
ARG TASK_VERSION=3.53.1
ARG TASK_SHA256_AMD64=a54a408f6861ff921f6e87774180db31bacd8c1e7c944ca696db9fea49a82fc7
ARG TASK_SHA256_ARM64=e3ad19101493a0112e1f22ae8ccc54bf03e533b1076a0ca1e6c782a09ad2e588
ARG JUST_VERSION=1.59.0
ARG JUST_SHA256_AMD64=409044617b6f06517c1035e55ca38c8c856ff8b650e41bc2aa1ef82d5903a23e
ARG JUST_SHA256_ARM64=23871b1702bfd550fb5f901778fd4290ecf2ee034a45a889fbe96d89b188086d
ARG JQ_VERSION=1.8.2
ARG JQ_SHA256_AMD64=b1c22172dd303f3be49e935aa56aa48a8b7a46e0bc838b4997d3bb451495870f
ARG JQ_SHA256_ARM64=8b85c817833814ddca00a144c33705546355afccf0cf39b188f3cdb48b852309
ARG YQ_VERSION=4.54.1
ARG YQ_SHA256_AMD64=8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f
ARG YQ_SHA256_ARM64=189088da0c6429ec5178dfaab1a114805f6cab0b61b165ab236efedf1d57a71b
ARG KUBECTL_VERSION=1.34.3
ARG KUBECTL_SHA256_AMD64=ab60ca5f0fd60c1eb81b52909e67060e3ba0bd27e55a8ac147cbc2172ff14212
ARG KUBECTL_SHA256_ARM64=46913a7aa0327f6cc2e1cc2775d53c4a2af5e52f7fd8dacbfbfd098e757f19e9
ARG HELM_VERSION=4.3.2
ARG HELM_SHA256_AMD64=d1c0278d46beab79582d7e50f5b3dc206944ba8e577cde618513fd07daa53983
ARG HELM_SHA256_ARM64=df31cb61680ef728f82c770e5280dd565617bee6b039d37e85c677288be4bbb0
ARG KIND_VERSION=0.33.0
ARG KIND_SHA256_AMD64=aee6151561422756b764a4ae28e7f44cda5af5a9eead3cc9985112b1de8d8e0d
ARG KIND_SHA256_ARM64=20022bee6cfcd5086cb7234d218e3454e6090022f2a8f55d1fa7fcf42c3867a2
ARG ISTIO_VERSION=1.29.2
ARG ISTIO_SHA256_AMD64=e507d6396349b53dad4198c3c489a512535ce03d5950736cbf66758e91681290
ARG ISTIO_SHA256_ARM64=b83e4fde0f220de00926e3a7e8a4b579c38f08827791cf9d4ab57f04f0124de6
ARG SKAFFOLD_VERSION=2.25.0
ARG SKAFFOLD_SHA256_AMD64=42b9e2e3246c19b78fcc53dd60cc7ded1da8704293886b909a2a02b9bef34d20
ARG SKAFFOLD_SHA256_ARM64=416f5fed2009c2b4adc62ae887ee5fc19ff08cc8a0250b81d8682d55626a75fd
ARG KUBECONFORM_VERSION=0.8.0
ARG KUBECONFORM_SHA256_AMD64=9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883
ARG KUBECONFORM_SHA256_ARM64=1f53fc8e81258197a35e8603054162a5af1de8c5af13746c71ab680d9534ed87
ARG HADOLINT_VERSION=2.14.0
ARG HADOLINT_SHA256_AMD64=6bf226944684f56c84dd014e8b979d27425c0148f61b3bd99bcc6f39e9dc5a47
ARG HADOLINT_SHA256_ARM64=331f1d3511b84a4f1e3d18d52fec284723e4019552f4f47b19322a53ce9a40ed
ARG PROMETHEUS_VERSION=3.16.0
ARG PROMETHEUS_SHA256_AMD64=68727009472a2c02e1ff7f062fd5b3e637285bffc8fc2d340c76fb449d6e0f34
ARG PROMETHEUS_SHA256_ARM64=fd8571b8162f4020232d886f17340bcf92e1722985ae3b4c1d096157826c0fbe
ARG ALERTMANAGER_VERSION=0.35.0
ARG ALERTMANAGER_SHA256_AMD64=6c7752a903c40c8a749e0b29df9240437e4fbb8228068d0af8807377db32addd
ARG ALERTMANAGER_SHA256_ARM64=b7a8a69f849c6f837348b05476195862152f9de8eae338eb36ab29801d341654
ARG TRIVY_VERSION=0.76.2
ARG TRIVY_SHA256_AMD64=bc0fc726e017b8927a62b2d3531d7a84ee01769daf5c99ed866dced54089fdbf
ARG TRIVY_SHA256_ARM64=ab9d51f86e6a5fb936f605faff6b593ac51bc378fff4d3e8b9d58358b9c367c3
ARG K6_VERSION=2.4.0
ARG K6_SHA256_AMD64=5a5ecf23529ccf93135bc7e5b0c1cd5126ecf5f2672e22eed1556a0ab74abb87
ARG K6_SHA256_ARM64=7bb415f59d81ad649a86f6da6b3e1bd2e4e64e84909deef13e9bca70608abccb
ARG UV_VERSION=0.13.7
ARG UV_SHA256_AMD64=c5221ff41b7892bfc223543883600125f6a47fe845093e0f5bdff4f359196d83
ARG UV_SHA256_ARM64=71279f8d3c67241e807b9d8db872d1bf541579fb9f08b7d1eb1682196d1e57dc
ARG PYTHON_VERSION=3.12.16
# installed from pre-commit.lock; `task lock` regenerates it, `task validate` checks it
ARG PRECOMMIT_VERSION=4.6.2

ARG GH_CLI_VERSION=2.104.0
ARG GH_CLI_SHA256_AMD64=98cb101ad87dbbd3f6b2f2bfcbd43197ccd07643140121d8a9cfaa91eadbc24e
ARG GH_CLI_SHA256_ARM64=cb34cefc6f4e77b90731374a2b737516bb8f3033c6ca46aa949e5344f68069e3
ARG TERRAFORM_VERSION=1.17.2
ARG TERRAFORM_SHA256_AMD64=e6f16b2f0b137ee5729caa8c4e79a3bae4ee261acd198a1fcfa8584a6296605b
ARG TERRAFORM_SHA256_ARM64=858e08c181a76b6b223e8c767a8e983922eebe2d062db949a2de66ce040c368c
ARG VAULT_VERSION=2.2.2
ARG VAULT_SHA256_AMD64=5700edf139113609962fe371af7d2a53de8ecb720d545dc39b43de204515d3c4
ARG VAULT_SHA256_ARM64=78634c8672601ad1ca9b27f24e76c54224d12521c59ece957ab8d23976ddca12
ARG CILIUM_CLI_VERSION=0.20.3
ARG CILIUM_CLI_SHA256_AMD64=b987ad0d195310d3fc96553aa7bcd41d1e97b64713ecdfee3eb48dd27e1ec7d7
ARG CILIUM_CLI_SHA256_ARM64=fa1bd66b407ec205e88746fc0b17590a247f255bf71bb9dfb0008b14d158f68d
ARG KUBELOGIN_VERSION=1.36.4
ARG KUBELOGIN_SHA256_AMD64=9e8baeb4905d35a301304af2548324997add512fe94ab20e65993d167212bf85
ARG KUBELOGIN_SHA256_ARM64=669c2d3bcc6766351ad5a7b03971792b4e7a55117b335a12d9858d43a525d9dc
ARG AWS_CLI_VERSION=2.40.3
ARG COSIGN_VERSION=3.1.4
ARG COSIGN_SHA256_AMD64=424e2c97d0b45fd7a6b608a87f090f35633f4c23ece5f092d48bba11aaf4bbfa
ARG COSIGN_SHA256_ARM64=ade83b7aac62e131cacfe96d958948b2150cc9efec46a570a2649b8e27dedad2
# Native binary from the `stable` channel (downloads.claude.ai/claude-code-releases/stable).
ARG CLAUDE_CODE_VERSION=2.1.311
ARG CLAUDE_CODE_SHA256_AMD64=86dc1fcc69498159eaf15f446613e847010f9036bfbbdffd4c49350be8489ada
ARG CLAUDE_CODE_SHA256_ARM64=2e2496c9a8065df93acb0fca2d341f59a6b8777649b2e025ab8c9bcd5eef61f3
# Claude Code plugin marketplace (skills + persona commands), pinned to a commit; bumped by
# hand: gh api repos/pampatzoglou/mentor/commits/main -q .sha
ARG MENTOR_SHA=a43aa19ad0955760c680b1dd3ffe8d6e7eaf4454
# AWS signs the CLI with GPG and publishes no checksums. keys/aws-cli.asc is the key from the
# AWS CLI install guide; this fingerprint must match it. AWS renews the key in place
# (current expiry 2027-07-01): re-copy it from the guide when it expires.
ARG AWS_CLI_SIGNER_FPR=FB5DB77FD5C118B80511ADA8A6310ACC4672475C

# ── base ────────────────────────────────────────────────────────────────────
# Tag + multi-arch index digest, written out literally so Dependabot can bump both
# (docker ecosystem, /). Upstream's `ubuntu-24.04` tag is abandoned (last built
# 2025-10-16); `<version>-ubuntu24.04` is the maintained one.
FROM mcr.microsoft.com/devcontainers/base:3.0.14-ubuntu24.04@sha256:88171bb581e19bbb45db77a16a3a5475e2f9ddce025b044c2e5a69a6a1e24fa1 AS base

# ── shared fetch stage ──────────────────────────────────────────────────────
FROM base AS fetcher
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG TARGETARCH
ARG PIN_MODE
ENV TARGETARCH=${TARGETARCH} GH=https://github.com PIN_MODE=${PIN_MODE}
WORKDIR /out

# Every download: HTTPS only (redirects too, e.g. GitHub → its object store), TLS >= 1.2,
# retried on transient errors (5xx included).
COPY <<'EOF' /etc/fetch.curlrc
fail
silent
show-error
location
proto = "=https"
proto-redir = "=https"
tlsv1.2
retry = 3
retry-all-errors
EOF

# fetch <NAME> <base-url> <asset> <sums-asset> [sha256-field] -> path of a verified download.
# <sums-asset> may be a full https:// URL when it lives outside <base-url>; a *.json one is a
# release manifest whose .platforms[<sha256-field>].checksum holds the hash (claude-code).
# Checks the download against the committed ${NAME}_SHA256_<ARCH> ARG only: the upstream sums
# file is not read, so a release swapped after pinning (asset and sums together) fails here.
# PIN_MODE=1 (`task pin`) instead reads the hash from the sums file, checks the
# download against it, and records it in /pins/<ARG name> for the task to write back.
COPY --chmod=755 <<'EOF' /usr/local/bin/fetch
#!/usr/bin/env bash
set -euo pipefail
tool=$1 base=$2 name=$3 sums=$4 field=${5:-}
var=${tool}_SHA256_${TARGETARCH^^}
out=$(mktemp -d)/$name
curl -K /etc/fetch.curlrc -o "$out" "$base/$name"
if [[ ${PIN_MODE:-} == 1 ]]; then
  [[ $sums == https://* ]] || sums=$base/$sums
  s=$(curl -K /etc/fetch.curlrc "$sums")
  if [[ $sums == *.json ]]; then             # release manifest (claude-code)
    want=$(jq -r --arg p "$field" '.platforms[$p].checksum // empty' <<<"$s")
  elif [[ -n $field ]]; then                 # multi-hash table (yq)
    want=$(awk -v n="$name" -v f="$field" '$1==n {print $f}' <<<"$s")
  elif [[ $s =~ ^[0-9a-f]{64}$ ]]; then      # bare hash (kubectl)
    want=$s
  else                                       # "<hash> [*][./]<name>" lines
    want=$(awk -v n="$name" '{sub(/^\*/,"",$2); sub(/^\.\//,"",$2)} $2==n {print $1}' <<<"$s")
  fi
  [[ $want =~ ^[0-9a-f]{64}$ ]] || { echo "fetch: no sha256 for $name in $sums" >&2; exit 1; }
  mkdir -p /pins && echo "$want" > "/pins/$var"
else
  want=${!var:-}
  [[ $want =~ ^[0-9a-f]{64}$ ]] || { echo "fetch: $var is not set; run task pin" >&2; exit 1; }
fi
echo "$want  $out" | sha256sum -c --quiet - >&2 \
  || { echo "fetch: $name does not match $var (version bumped? run task pin)" >&2; exit 1; }
echo "$out"
EOF

# arch-of <amd64-name> <arm64-name>
COPY --chmod=755 <<'EOF' /usr/local/bin/arch-of
#!/bin/sh
case "$TARGETARCH" in amd64) echo "$1" ;; arm64) echo "$2" ;; *) echo "unsupported arch: $TARGETARCH" >&2; exit 1 ;; esac
EOF

# ── tools ───────────────────────────────────────────────────────────────────
FROM fetcher AS task
ARG TASK_VERSION
ARG TASK_SHA256_AMD64
ARG TASK_SHA256_ARM64
RUN f=$(fetch TASK $GH/go-task/task/releases/download/v$TASK_VERSION task_linux_$TARGETARCH.tar.gz task_checksums.txt) \
 && tar -xzf "$f" -C /out task

FROM fetcher AS just
ARG JUST_VERSION
ARG JUST_SHA256_AMD64
ARG JUST_SHA256_ARM64
RUN n=just-$JUST_VERSION-$(arch-of x86_64 aarch64)-unknown-linux-musl.tar.gz \
 && f=$(fetch JUST $GH/casey/just/releases/download/$JUST_VERSION $n SHA256SUMS) \
 && tar -xzf "$f" -C /out just

FROM fetcher AS jq
ARG JQ_VERSION
ARG JQ_SHA256_AMD64
ARG JQ_SHA256_ARM64
RUN f=$(fetch JQ $GH/jqlang/jq/releases/download/jq-$JQ_VERSION jq-linux-$TARGETARCH sha256sum.txt) \
 && install -m755 "$f" /out/jq

FROM fetcher AS yq
ARG YQ_VERSION
ARG YQ_SHA256_AMD64
ARG YQ_SHA256_ARM64
# field 19 = SHA-256 per the release's checksums_hashes_order
RUN f=$(fetch YQ $GH/mikefarah/yq/releases/download/v$YQ_VERSION yq_linux_$TARGETARCH checksums 19) \
 && install -m755 "$f" /out/yq

FROM fetcher AS kubectl
ARG KUBECTL_VERSION
ARG KUBECTL_SHA256_AMD64
ARG KUBECTL_SHA256_ARM64
RUN f=$(fetch KUBECTL https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/$TARGETARCH kubectl kubectl.sha256) \
 && install -m755 "$f" /out/kubectl

FROM fetcher AS helm
ARG HELM_VERSION
ARG HELM_SHA256_AMD64
ARG HELM_SHA256_ARM64
RUN n=helm-v$HELM_VERSION-linux-$TARGETARCH.tar.gz \
 && f=$(fetch HELM https://get.helm.sh $n $n.sha256sum) \
 && tar -xzf "$f" -C /out --strip-components=1 linux-$TARGETARCH/helm

FROM fetcher AS kind
ARG KIND_VERSION
ARG KIND_SHA256_AMD64
ARG KIND_SHA256_ARM64
RUN f=$(fetch KIND $GH/kubernetes-sigs/kind/releases/download/v$KIND_VERSION kind-linux-$TARGETARCH kind-linux-$TARGETARCH.sha256sum) \
 && install -m755 "$f" /out/kind

FROM fetcher AS istioctl
ARG ISTIO_VERSION
ARG ISTIO_SHA256_AMD64
ARG ISTIO_SHA256_ARM64
RUN n=istioctl-$ISTIO_VERSION-linux-$TARGETARCH.tar.gz \
 && f=$(fetch ISTIO $GH/istio/istio/releases/download/$ISTIO_VERSION $n $n.sha256) \
 && tar -xzf "$f" -C /out istioctl

FROM fetcher AS skaffold
ARG SKAFFOLD_VERSION
ARG SKAFFOLD_SHA256_AMD64
ARG SKAFFOLD_SHA256_ARM64
RUN f=$(fetch SKAFFOLD $GH/GoogleContainerTools/skaffold/releases/download/v$SKAFFOLD_VERSION skaffold-linux-$TARGETARCH skaffold-linux-$TARGETARCH.sha256) \
 && install -m755 "$f" /out/skaffold

FROM fetcher AS kubeconform
ARG KUBECONFORM_VERSION
ARG KUBECONFORM_SHA256_AMD64
ARG KUBECONFORM_SHA256_ARM64
RUN f=$(fetch KUBECONFORM $GH/yannh/kubeconform/releases/download/v$KUBECONFORM_VERSION kubeconform-linux-$TARGETARCH.tar.gz CHECKSUMS) \
 && tar -xzf "$f" -C /out kubeconform

FROM fetcher AS hadolint
ARG HADOLINT_VERSION
ARG HADOLINT_SHA256_AMD64
ARG HADOLINT_SHA256_ARM64
RUN n=hadolint-linux-$(arch-of x86_64 arm64) \
 && f=$(fetch HADOLINT $GH/hadolint/hadolint/releases/download/v$HADOLINT_VERSION $n $n.sha256) \
 && install -m755 "$f" /out/hadolint

# promtool only (rule/config checks and rule unit tests), not the server.
FROM fetcher AS promtool
ARG PROMETHEUS_VERSION
ARG PROMETHEUS_SHA256_AMD64
ARG PROMETHEUS_SHA256_ARM64
RUN n=prometheus-$PROMETHEUS_VERSION.linux-$TARGETARCH \
 && f=$(fetch PROMETHEUS $GH/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION $n.tar.gz sha256sums.txt) \
 && tar -xzf "$f" -C /out --strip-components=1 $n/promtool

# amtool only (config checks, routing tests, silences), not the server.
FROM fetcher AS amtool
ARG ALERTMANAGER_VERSION
ARG ALERTMANAGER_SHA256_AMD64
ARG ALERTMANAGER_SHA256_ARM64
RUN n=alertmanager-$ALERTMANAGER_VERSION.linux-$TARGETARCH \
 && f=$(fetch ALERTMANAGER $GH/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION $n.tar.gz sha256sums.txt) \
 && tar -xzf "$f" -C /out --strip-components=1 $n/amtool

FROM fetcher AS trivy
ARG TRIVY_VERSION
ARG TRIVY_SHA256_AMD64
ARG TRIVY_SHA256_ARM64
RUN n=trivy_${TRIVY_VERSION}_Linux-$(arch-of 64bit ARM64).tar.gz \
 && f=$(fetch TRIVY $GH/aquasecurity/trivy/releases/download/v$TRIVY_VERSION $n trivy_${TRIVY_VERSION}_checksums.txt) \
 && tar -xzf "$f" -C /out trivy

FROM fetcher AS k6
ARG K6_VERSION
ARG K6_SHA256_AMD64
ARG K6_SHA256_ARM64
RUN n=k6-v$K6_VERSION-linux-$TARGETARCH \
 && f=$(fetch K6 $GH/grafana/k6/releases/download/v$K6_VERSION $n.tar.gz k6-v$K6_VERSION-checksums.txt) \
 && tar -xzf "$f" -C /out --strip-components=1 $n/k6

FROM fetcher AS uv
ARG UV_VERSION
ARG UV_SHA256_AMD64
ARG UV_SHA256_ARM64
RUN n=uv-$(arch-of x86_64 aarch64)-unknown-linux-gnu \
 && f=$(fetch UV $GH/astral-sh/uv/releases/download/$UV_VERSION $n.tar.gz $n.tar.gz.sha256) \
 && tar -xzf "$f" -C /out --strip-components=1

# uv-managed CPython (sha256-checked by uv) + pre-commit in its own venv, installed only from
# pre-commit.lock: every package pinned and hash-checked (--require-hashes), no resolution at
# build time. PRECOMMIT_VERSION is not read here; `task validate` checks the lock matches it.
# Install dirs live at their final paths: the bin entries are absolute symlinks into them.
FROM fetcher AS python
ARG PYTHON_VERSION
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python UV_PYTHON_BIN_DIR=/out/bin
COPY --from=uv /out/ /out/bin/
RUN --mount=type=bind,source=pre-commit.lock,target=/tmp/pre-commit.lock \
    /out/bin/uv python install --default "$PYTHON_VERSION" \
 && /out/bin/uv venv --python "$PYTHON_VERSION" /opt/uv/tools/pre-commit \
 && /out/bin/uv pip install --python /opt/uv/tools/pre-commit/bin/python \
      --require-hashes --no-deps -r /tmp/pre-commit.lock \
 && ln -s /opt/uv/tools/pre-commit/bin/pre-commit /out/bin/pre-commit

# ── devcontainer-only tools ─────────────────────────────────────────────────
FROM fetcher AS gh
ARG GH_CLI_VERSION
ARG GH_CLI_SHA256_AMD64
ARG GH_CLI_SHA256_ARM64
RUN n=gh_${GH_CLI_VERSION}_linux_$TARGETARCH \
 && f=$(fetch GH_CLI $GH/cli/cli/releases/download/v$GH_CLI_VERSION $n.tar.gz gh_${GH_CLI_VERSION}_checksums.txt) \
 && tar -xzf "$f" -C /out --strip-components=2 $n/bin/gh

FROM fetcher AS terraform
ARG TERRAFORM_VERSION
ARG TERRAFORM_SHA256_AMD64
ARG TERRAFORM_SHA256_ARM64
RUN f=$(fetch TERRAFORM https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION terraform_${TERRAFORM_VERSION}_linux_$TARGETARCH.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS) \
 && unzip -q "$f" terraform -d /out

FROM fetcher AS vault
ARG VAULT_VERSION
ARG VAULT_SHA256_AMD64
ARG VAULT_SHA256_ARM64
RUN f=$(fetch VAULT https://releases.hashicorp.com/vault/$VAULT_VERSION vault_${VAULT_VERSION}_linux_$TARGETARCH.zip vault_${VAULT_VERSION}_SHA256SUMS) \
 && unzip -q "$f" vault -d /out

FROM fetcher AS cilium
ARG CILIUM_CLI_VERSION
ARG CILIUM_CLI_SHA256_AMD64
ARG CILIUM_CLI_SHA256_ARM64
RUN n=cilium-linux-$TARGETARCH.tar.gz \
 && f=$(fetch CILIUM_CLI $GH/cilium/cilium-cli/releases/download/v$CILIUM_CLI_VERSION $n $n.sha256sum) \
 && tar -xzf "$f" -C /out cilium

# Installed as the kubectl plugin `kubectl oidc-login`, the name kubeconfig exec entries use.
FROM fetcher AS kubelogin
ARG KUBELOGIN_VERSION
ARG KUBELOGIN_SHA256_AMD64
ARG KUBELOGIN_SHA256_ARM64
RUN n=kubelogin_linux_$TARGETARCH.zip \
 && f=$(fetch KUBELOGIN $GH/int128/kubelogin/releases/download/v$KUBELOGIN_VERSION $n $n.sha256) \
 && unzip -q "$f" kubelogin -d /tmp/kubelogin \
 && install -m755 /tmp/kubelogin/kubelogin /out/kubectl-oidc_login

FROM fetcher AS cosign
ARG COSIGN_VERSION
ARG COSIGN_SHA256_AMD64
ARG COSIGN_SHA256_ARM64
RUN f=$(fetch COSIGN $GH/sigstore/cosign/releases/download/v$COSIGN_VERSION cosign-linux-$TARGETARCH cosign_checksums.txt) \
 && install -m755 "$f" /out/cosign

# A single self-contained binary; no Node. The auto-updater is off in the final stage, so
# this pin is the version that runs.
FROM fetcher AS claude
ARG CLAUDE_CODE_VERSION
ARG CLAUDE_CODE_SHA256_AMD64
ARG CLAUDE_CODE_SHA256_ARM64
RUN b=https://downloads.claude.ai/claude-code-releases/$CLAUDE_CODE_VERSION \
 && p=$(arch-of linux-x64 linux-arm64) \
 && f=$(fetch CLAUDE_CODE $b/$p claude $b/manifest.json $p) \
 && install -m755 "$f" /out/claude

# The exact commit, fetched by SHA (git verifies the object graph against it) and checked
# again after checkout. Shipped as a `directory` marketplace that managed settings declare, so
# Claude Code loads the plugins in place: no clone at runtime, and no auto-update.
FROM fetcher AS mentor
ARG MENTOR_SHA
# (`task validate` rejects anything but a full 40-hex SHA.)
RUN git init -q /out \
 && git -C /out fetch -q --depth 1 https://github.com/pampatzoglou/mentor.git "$MENTOR_SHA" \
 && git -C /out -c advice.detachedHead=false checkout -q FETCH_HEAD \
 && test "$(git -C /out rev-parse HEAD)" = "$MENTOR_SHA" \
 && rm -rf /out/.git

# gpgv against a keyring holding only the pinned key: a signature by any other key fails.
FROM fetcher AS aws
ARG AWS_CLI_VERSION
ARG AWS_CLI_SIGNER_FPR
COPY keys/aws-cli.asc /tmp/aws-cli.asc
RUN n=awscli-exe-linux-$(arch-of x86_64 aarch64)-$AWS_CLI_VERSION.zip \
 && gpg --batch --with-colons --import-options show-only --import /tmp/aws-cli.asc > /tmp/aws-cli.key \
 && fpr=$(awk -F: '$1=="fpr" {print $10; exit}' /tmp/aws-cli.key) \
 && if [[ $fpr != "$AWS_CLI_SIGNER_FPR" ]]; then echo "aws-cli.asc is $fpr, want $AWS_CLI_SIGNER_FPR" >&2; exit 1; fi \
 && gpg --dearmor < /tmp/aws-cli.asc > /tmp/aws-cli.gpg \
 && curl -K /etc/fetch.curlrc -o /tmp/$n https://awscli.amazonaws.com/$n \
 && curl -K /etc/fetch.curlrc -o /tmp/$n.sig https://awscli.amazonaws.com/$n.sig \
 && gpgv --keyring /tmp/aws-cli.gpg /tmp/$n.sig /tmp/$n \
 && unzip -q /tmp/$n -d /tmp \
 && /tmp/aws/install --install-dir /opt/aws-cli --bin-dir /out

# ── pin mode output (`task pin`): one file per hash ARG ──────────
FROM scratch AS pins
COPY --from=task /pins/ /
COPY --from=just /pins/ /
COPY --from=jq /pins/ /
COPY --from=yq /pins/ /
COPY --from=kubectl /pins/ /
COPY --from=helm /pins/ /
COPY --from=kind /pins/ /
COPY --from=istioctl /pins/ /
COPY --from=skaffold /pins/ /
COPY --from=kubeconform /pins/ /
COPY --from=hadolint /pins/ /
COPY --from=promtool /pins/ /
COPY --from=amtool /pins/ /
COPY --from=trivy /pins/ /
COPY --from=k6 /pins/ /
COPY --from=uv /pins/ /
COPY --from=gh /pins/ /
COPY --from=terraform /pins/ /
COPY --from=vault /pins/ /
COPY --from=cilium /pins/ /
COPY --from=kubelogin /pins/ /
COPY --from=cosign /pins/ /
COPY --from=claude /pins/ /

# ── final ───────────────────────────────────────────────────────────────────
FROM base AS devcontainer
# The base ships nano and vim-tiny; full vim from Ubuntu's archive (apt checks its signed
# index). Unversioned on purpose: the archive drops superseded versions, so a pin would break
# the build at the next security update; the digest-pinned base fixes the package set.
# ipset, dnsutils (dig) and aggregate are for the opt-in egress firewall (init-firewall);
# iptables and iproute2 ship in the base. direnv from the archive too: upstream publishes no
# checksums to pin against.
# linux-libc-dev (kernel headers, pulled in by the base's libc6-dev) is listed so apt upgrades
# it from the security archive: every kernel CVE lands on it, failing the Trivy gate until
# upstream rebuilds the base. Drop it once the base ships the fixed version.
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends vim direnv ipset dnsutils aggregate \
      linux-libc-dev \
 && rm -rf /var/lib/apt/lists/*
# direnv hooks for every interactive shell. An .envrc still needs `direnv allow` once per
# checkout: nothing in a cloned repo runs unapproved. Single quotes: written literally, expanded
# by each shell at startup.
# hadolint ignore=SC2016
RUN echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc \
 && echo 'eval "$(direnv hook zsh)"' >> /etc/zsh/zshrc
COPY --link --from=task        /out/ /usr/local/bin/
COPY --link --from=just        /out/ /usr/local/bin/
COPY --link --from=jq          /out/ /usr/local/bin/
COPY --link --from=yq          /out/ /usr/local/bin/
COPY --link --from=kubectl     /out/ /usr/local/bin/
COPY --link --from=helm        /out/ /usr/local/bin/
COPY --link --from=kind        /out/ /usr/local/bin/
COPY --link --from=istioctl    /out/ /usr/local/bin/
COPY --link --from=skaffold    /out/ /usr/local/bin/
COPY --link --from=kubeconform /out/ /usr/local/bin/
COPY --link --from=hadolint    /out/ /usr/local/bin/
COPY --link --from=promtool    /out/ /usr/local/bin/
COPY --link --from=amtool      /out/ /usr/local/bin/
COPY --link --from=trivy       /out/ /usr/local/bin/
COPY --link --from=k6          /out/ /usr/local/bin/
COPY --link --from=python      /opt/uv/ /opt/uv/
COPY --link --from=python      /out/bin/ /usr/local/bin/
COPY --link --from=gh          /out/ /usr/local/bin/
COPY --link --from=terraform   /out/ /usr/local/bin/
COPY --link --from=vault       /out/ /usr/local/bin/
COPY --link --from=cilium      /out/ /usr/local/bin/
COPY --link --from=kubelogin   /out/ /usr/local/bin/
COPY --link --from=aws         /opt/aws-cli/ /opt/aws-cli/
COPY --link --from=aws         /out/ /usr/local/bin/
COPY --link --from=cosign      /out/ /usr/local/bin/
COPY --link --from=claude      /out/ /usr/local/bin/
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python UV_PYTHON_DOWNLOADS=never

# Claude Code. CLAUDE_CONFIG_DIR puts all its state (auth included, which otherwise lands in
# ~/.claude.json) under one directory, so a single volume keeps it across rebuilds; the dir
# exists here, owned by vscode, so a fresh named volume mounted over it inherits that owner.
# DISABLE_AUTOUPDATER: the binary is root-owned and pinned; bump CLAUDE_CODE_VERSION instead.
ENV CLAUDE_CONFIG_DIR=/home/vscode/.claude DISABLE_AUTOUPDATER=1
RUN install -d -m 700 -o vscode -g vscode /home/vscode/.claude

# Plugins from the pinned mentor marketplace, on by default with a per-repo opt-out. Managed
# settings only declare the marketplace; enabling it there would stop repos disabling it.
# claude-default-plugins (postCreateCommand) enables the plugins in user settings instead,
# which a repo's .claude/settings.json overrides.
COPY --link --from=mentor /out/ /opt/claude-marketplaces/mentor/
COPY <<'EOF' /etc/claude-code/managed-settings.json
{
  "extraKnownMarketplaces": {
    "mentor": {
      "source": { "source": "directory", "path": "/opt/claude-marketplaces/mentor" }
    }
  }
}
EOF

COPY --chmod=755 image/claude-default-plugins.sh /usr/local/bin/claude-default-plugins

# Opt-in egress firewall; see the script header and the README. vscode may run it (and only
# it) through sudo once its blanket sudo rule is gone, which the script removes on first run.
COPY --chmod=755 image/init-firewall.sh /usr/local/bin/init-firewall
COPY --chmod=440 <<'EOF' /etc/sudoers.d/vscode-firewall
vscode ALL=(root) NOPASSWD: /usr/local/bin/init-firewall
EOF

# ── devcontainer metadata ───────────────────────────────────────────────────
# Consumers inherit these by referencing the image; their own devcontainer.json overrides them.
# No features here: docker-in-docker (and the --privileged it brings) is opt-in per repo.
#
# portsAttributes: OIDC login callbacks. The host browser is redirected to localhost:<port>,
# where the CLI in here listens on loopback; VS Code auto-forwards it, and requireLocalPort
# fails visibly rather than map to another port the IdP's redirect URI would not match.
# `aws sso login` picks a random port that auto-forward covers. Zed can't forward to the
# container's loopback: use device-code logins there (`--grant-type=device-code` in the
# kubeconfig exec args for kubectl oidc-login; `aws sso login --use-device-code`).
#
# remoteEnv: no host credentials by default. VS Code forwards the host SSH agent and a git
# credential helper into every dev container, with no per-repo switch to turn that off.
#   SSH_AUTH_SOCK=""       ssh/git see no agent. The forwarded socket still exists under /tmp,
#                          so this prevents accidental use, not a determined process; the hard
#                          boundary is host-side per-use confirmation (1Password SSH agent, or
#                          `ssh-add -c`).
#   GIT_CONFIG_NOSYSTEM=1  git ignores /etc/gitconfig, where VS Code registers its credential
#                          helper (the image ships no /etc/gitconfig of its own).
#   core.fileMode=false    Docker Desktop's file sharing reports every bind-mounted file as
#                          executable; with this off git uses the index's modes. Set through
#                          GIT_CONFIG_* so the shared .git/config is untouched. A new script
#                          added from in here needs `git add --chmod=+x`.
# git.terminalAuthentication / github.gitAuthentication: no VS Code askpass bridge.
# Consequences: commits signed through the host agent and pushes don't work in here. Push from
# the host, or from inside with a scoped token: `gh auth login` then `gh auth setup-git`.
# Cloud and cluster logins are OIDC (aws sso, vault oidc, kubectl oidc-login): short-lived
# tokens obtained inside the container, nothing forwarded.
#
# postCreateCommand: repos without a pre-commit config are skipped, not failed. A consuming
# repo's own postCreateCommand runs as well, not instead (lifecycle commands from every
# metadata layer run).
LABEL devcontainer.metadata='[{ \
  "remoteUser": "vscode", \
  "portsAttributes": { \
    "8000": { "label": "kubelogin OIDC callback", "requireLocalPort": true, "onAutoForward": "silent" }, \
    "8250": { "label": "vault OIDC callback", "requireLocalPort": true, "onAutoForward": "silent" } \
  }, \
  "postCreateCommand": { \
    "pre-commit": "if [ -f .pre-commit-config.yaml ]; then pre-commit install --install-hooks; else echo \"no .pre-commit-config.yaml; skipping pre-commit install\"; fi", \
    "claude-plugins": "claude-default-plugins" \
  }, \
  "remoteEnv": { \
    "SSH_AUTH_SOCK": "", \
    "GIT_CONFIG_NOSYSTEM": "1", \
    "GIT_CONFIG_COUNT": "1", \
    "GIT_CONFIG_KEY_0": "core.fileMode", \
    "GIT_CONFIG_VALUE_0": "false" \
  }, \
  "customizations": { \
    "vscode": { \
      "extensions": ["anthropic.claude-code", "mkhl.direnv"], \
      "settings": { "git.terminalAuthentication": false, "github.gitAuthentication": false } \
    } \
  } \
}]'
