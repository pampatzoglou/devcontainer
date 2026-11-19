# syntax=docker/dockerfile:1
# Unquoted $VARs are pinned version ARGs and $GH; they never contain spaces or globs.
# hadolint global ignore=SC2086
# A general-purpose devcontainer image, published to ghcr.io/pampatzoglou/devcontainer.
# Plain buildx (`task build`; .github/actions/build-push in CI); no devcontainer features are
# installed. The devcontainer settings consumers inherit are the devcontainer.metadata LABEL at
# the end of the final stage.
#
# Every download is checked against the committed <TOOL>_SHA256_<ARCH> ARGs below it, never
# against upstream's sums file at build time. After bumping a version, `task pin` refreshes
# them; a stale hash fails the build by name. The AWS CLI is checked by GPG signature instead
# (it publishes no sums), python by uv, the rust toolchain by rustup.
#
# One stage per tool: fetched in parallel, cached independently; COPY --link keeps a version
# bump from invalidating the other layers.

# ── versions (the manifest) ─────────────────────────────────────────────────
# Bump a version, then `task pin` (hashes) or `task lock` (pre-commit). Take releases that are
# >= 3 days old, matching the Dependabot cooldown.
ARG TASK_VERSION=3.53.1
ARG TASK_SHA256_AMD64=a54a408f6861ff921f6e87774180db31bacd8c1e7c944ca696db9fea49a82fc7
ARG TASK_SHA256_ARM64=e3ad19101493a0112e1f22ae8ccc54bf03e533b1076a0ca1e6c782a09ad2e588
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
ARG KUBESCAPE_VERSION=4.0.20
ARG KUBESCAPE_SHA256_AMD64=25649b3e1212a86bbd467d3e73812218459455c335fad7aaed7fe458782355c5
ARG KUBESCAPE_SHA256_ARM64=f50478243f9d1573cd37a4df68b9df3c8f66472d6016e837f059180198875991
ARG HADOLINT_VERSION=2.14.0
ARG HADOLINT_SHA256_AMD64=6bf226944684f56c84dd014e8b979d27425c0148f61b3bd99bcc6f39e9dc5a47
ARG HADOLINT_SHA256_ARM64=331f1d3511b84a4f1e3d18d52fec284723e4019552f4f47b19322a53ce9a40ed
ARG TRIVY_VERSION=0.76.2
ARG TRIVY_SHA256_AMD64=bc0fc726e017b8927a62b2d3531d7a84ee01769daf5c99ed866dced54089fdbf
ARG TRIVY_SHA256_ARM64=ab9d51f86e6a5fb936f605faff6b593ac51bc378fff4d3e8b9d58358b9c367c3
ARG K6_VERSION=2.4.0
ARG K6_SHA256_AMD64=5a5ecf23529ccf93135bc7e5b0c1cd5126ecf5f2672e22eed1556a0ab74abb87
ARG K6_SHA256_ARM64=7bb415f59d81ad649a86f6da6b3e1bd2e4e64e84909deef13e9bca70608abccb
ARG JDK_VERSION=21.0.12.1+1
ARG JDK_SHA256_AMD64=ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94
ARG JDK_SHA256_ARM64=23e37e026f12f3e706f18938ff611db3032d075b09d0879a25d06718c773e223
ARG NODE_VERSION=22.23.5
ARG NODE_SHA256_AMD64=c54118104acc524633b5abe106bbf44a53126ec8b4e5fa105cb92b5d7de8a1a1
ARG NODE_SHA256_ARM64=8bd3dc69eee8f3f226315a80d7d1d4faccf217a4c8fae500168ac2e38f3bdba3
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
ARG GO_VERSION=1.27.4
ARG GO_SHA256_AMD64=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
ARG GO_SHA256_ARM64=3392582988a273a87ab5043ee1b2c9c17a2c3c00580bf9326c47a2e0aaaeac92
# rustup-init is hash-pinned; the toolchain it installs is checked by rustup against the
# release's channel manifest (fetched over HTTPS from static.rust-lang.org, not pinned here).
ARG RUSTUP_VERSION=1.29.3
ARG RUSTUP_SHA256_AMD64=b1c8cb14e30889e7e2999e6b69e62d9e9b9ffc0f4df8180564d306d9680e6c55
ARG RUSTUP_SHA256_ARM64=9f608c142e0e38a78957d0661ba1dfaf0b6fb37184cfaa4b9a0aa57af6184282
ARG RUST_VERSION=1.100.0
# AWS signs the CLI with GPG and publishes no checksums. keys/aws-cli.asc is the key from the
# AWS CLI install guide; this fingerprint must match it. AWS renews the key in place
# (current expiry 2027-07-01): re-copy it from the guide when it expires.
ARG AWS_CLI_SIGNER_FPR=FB5DB77FD5C118B80511ADA8A6310ACC4672475C

# ── base ────────────────────────────────────────────────────────────────────
# Tag + multi-arch index digest, written out literally so Dependabot can bump both
# (docker ecosystem, /). Upstream's `ubuntu-24.04` tag is abandoned (last built
# 2025-10-16); `<version>-ubuntu24.04` is the maintained one.
FROM mcr.microsoft.com/devcontainers/base:3.0.13-ubuntu24.04@sha256:48be4adec1c1ecbe030064700aef85382f5205786a8f82937fc44a7473717eae AS base

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
  s=$(curl -K /etc/fetch.curlrc "$base/$sums")
  if [[ -n $field ]]; then                  # multi-hash table (yq)
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

FROM fetcher AS kubescape
ARG KUBESCAPE_VERSION
ARG KUBESCAPE_SHA256_AMD64
ARG KUBESCAPE_SHA256_ARM64
RUN f=$(fetch KUBESCAPE $GH/kubescape/kubescape/releases/download/v$KUBESCAPE_VERSION kubescape_${KUBESCAPE_VERSION}_linux_$TARGETARCH checksums.sha256) \
 && install -m755 "$f" /out/kubescape

FROM fetcher AS hadolint
ARG HADOLINT_VERSION
ARG HADOLINT_SHA256_AMD64
ARG HADOLINT_SHA256_ARM64
RUN n=hadolint-linux-$(arch-of x86_64 arm64) \
 && f=$(fetch HADOLINT $GH/hadolint/hadolint/releases/download/v$HADOLINT_VERSION $n $n.sha256) \
 && install -m755 "$f" /out/hadolint

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

FROM fetcher AS jdk
ARG JDK_VERSION
ARG JDK_SHA256_AMD64
ARG JDK_SHA256_ARM64
RUN n=OpenJDK21U-jdk_$(arch-of x64 aarch64)_linux_hotspot_${JDK_VERSION/+/_}.tar.gz \
 && f=$(fetch JDK "$GH/adoptium/temurin21-binaries/releases/download/jdk-${JDK_VERSION/+/%2B}" $n $n.sha256.txt) \
 && tar -xzf "$f" -C /out --strip-components=1

FROM fetcher AS node
ARG NODE_VERSION
ARG NODE_SHA256_AMD64
ARG NODE_SHA256_ARM64
RUN n=node-v$NODE_VERSION-linux-$(arch-of x64 arm64) \
 && f=$(fetch NODE https://nodejs.org/dist/v$NODE_VERSION $n.tar.gz SHASUMS256.txt) \
 && tar -xzf "$f" -C /out --strip-components=1 $n/bin $n/include $n/lib $n/share

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

FROM fetcher AS go
ARG GO_VERSION
ARG GO_SHA256_AMD64
ARG GO_SHA256_ARM64
RUN n=go$GO_VERSION.linux-$TARGETARCH.tar.gz \
 && f=$(fetch GO https://dl.google.com/go $n $n.sha256) \
 && tar -xzf "$f" -C /out --strip-components=1

FROM fetcher AS rustup
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256_AMD64
ARG RUSTUP_SHA256_ARM64
RUN f=$(fetch RUSTUP "https://static.rust-lang.org/rustup/archive/$RUSTUP_VERSION/$(arch-of x86_64 aarch64)-unknown-linux-gnu" rustup-init rustup-init.sha256) \
 && install -m755 "$f" /out/rustup-init

# Minimal profile + the components editors and CI use; rust-analyzer from rustup (checked
# against the manifest) rather than an editor fetching its own copy at runtime.
FROM fetcher AS rust
ARG RUST_VERSION
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo
COPY --from=rustup /out/rustup-init /tmp/rustup-init
RUN /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain "$RUST_VERSION" \
      --component clippy,rustfmt,rust-analyzer

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
COPY --from=jq /pins/ /
COPY --from=yq /pins/ /
COPY --from=kubectl /pins/ /
COPY --from=helm /pins/ /
COPY --from=kind /pins/ /
COPY --from=istioctl /pins/ /
COPY --from=skaffold /pins/ /
COPY --from=kubeconform /pins/ /
COPY --from=kubescape /pins/ /
COPY --from=hadolint /pins/ /
COPY --from=trivy /pins/ /
COPY --from=k6 /pins/ /
COPY --from=jdk /pins/ /
COPY --from=node /pins/ /
COPY --from=uv /pins/ /
COPY --from=gh /pins/ /
COPY --from=terraform /pins/ /
COPY --from=vault /pins/ /
COPY --from=cilium /pins/ /
COPY --from=kubelogin /pins/ /
COPY --from=cosign /pins/ /
COPY --from=go /pins/ /
COPY --from=rustup /pins/ /

# ── final ───────────────────────────────────────────────────────────────────
FROM base AS devcontainer
# The base ships nano and vim-tiny; full vim from Ubuntu's archive (apt checks its signed
# index). Unversioned on purpose: the archive drops superseded versions, so a pin would break
# the build at the next security update; the digest-pinned base fixes the package set.
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends vim \
 && rm -rf /var/lib/apt/lists/*
COPY --link --from=task        /out/ /usr/local/bin/
COPY --link --from=jq          /out/ /usr/local/bin/
COPY --link --from=yq          /out/ /usr/local/bin/
COPY --link --from=kubectl     /out/ /usr/local/bin/
COPY --link --from=helm        /out/ /usr/local/bin/
COPY --link --from=kind        /out/ /usr/local/bin/
COPY --link --from=istioctl    /out/ /usr/local/bin/
COPY --link --from=skaffold    /out/ /usr/local/bin/
COPY --link --from=kubeconform /out/ /usr/local/bin/
COPY --link --from=kubescape   /out/ /usr/local/bin/
COPY --link --from=hadolint    /out/ /usr/local/bin/
COPY --link --from=trivy       /out/ /usr/local/bin/
COPY --link --from=k6          /out/ /usr/local/bin/
COPY --link --from=jdk         /out/ /opt/java/openjdk/
COPY --link --from=node        /out/ /usr/local/
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
COPY --link --from=go          /out/ /usr/local/go/
# Owned by vscode (uid 1000): cargo install, rustup component add and the registry cache
# write here.
COPY --link --from=rust --chown=1000:1000 /usr/local/rustup/ /usr/local/rustup/
COPY --link --from=rust --chown=1000:1000 /usr/local/cargo/ /usr/local/cargo/
ENV JAVA_HOME=/opt/java/openjdk PATH=/opt/java/openjdk/bin:$PATH
# GOTOOLCHAIN=local: use this Go, never download the toolchain a go.mod asks for.
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo GOTOOLCHAIN=local \
    PATH=/usr/local/cargo/bin:/usr/local/go/bin:/home/vscode/go/bin:$PATH
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python UV_PYTHON_DOWNLOADS=never

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
# postCreateCommand: repos without a pre-commit config are skipped, not failed.
LABEL devcontainer.metadata='[{ \
  "remoteUser": "vscode", \
  "portsAttributes": { \
    "8000": { "label": "kubelogin OIDC callback", "requireLocalPort": true, "onAutoForward": "silent" }, \
    "8250": { "label": "vault OIDC callback", "requireLocalPort": true, "onAutoForward": "silent" } \
  }, \
  "postCreateCommand": "if [ -f .pre-commit-config.yaml ]; then pre-commit install --install-hooks; else echo \"no .pre-commit-config.yaml; skipping pre-commit install\"; fi", \
  "remoteEnv": { \
    "SSH_AUTH_SOCK": "", \
    "GIT_CONFIG_NOSYSTEM": "1", \
    "GIT_CONFIG_COUNT": "1", \
    "GIT_CONFIG_KEY_0": "core.fileMode", \
    "GIT_CONFIG_VALUE_0": "false" \
  }, \
  "customizations": { \
    "vscode": { \
      "settings": { "git.terminalAuthentication": false, "github.gitAuthentication": false } \
    } \
  } \
}]'
