# devcontainer

A general-purpose dev container image for platform work, published (multi-arch,
cosign-signed) to `ghcr.io/pampatzoglou/devcontainer`.

Every tool is pinned to an exact version **and** a committed sha256 per architecture; the
build never trusts upstream's checksum files at build time.

## Use it

In a consuming repo, `.devcontainer/devcontainer.json` (or `.devcontainer.json`):

```jsonc
{
  "image": "ghcr.io/pampatzoglou/devcontainer:<version>",
  // Only if the repo needs a Docker daemon (kind, image builds). Makes the container
  // --privileged: anything inside is effectively root on the Docker VM.
  "features": { "ghcr.io/devcontainers/features/docker-in-docker:2.17.0": {} }
}
```

The settings below travel in the image's `devcontainer.metadata` label; override any of them
in the consuming file. No features are baked in, so `--privileged` is opt-in per repo. Pin
the feature to an exact version and let Dependabot's `devcontainers` ecosystem bump it; 2.17.0
is the last 2.x, and majors 3 and 4 need a kind test before moving.

| Inherited setting | Effect |
|---|---|
| `remoteUser: vscode` | Non-root user (uid 1000) |
| `remoteEnv` | Host SSH agent and VS Code git credential helper disabled; `core.fileMode=false` |
| `portsAttributes` 8000 / 8250 | kubelogin and vault OIDC callbacks |
| `postCreateCommand` | `pre-commit install --install-hooks` if the repo has a `.pre-commit-config.yaml`; enables the bundled Claude Code plugins in user settings |
| `customizations.vscode.extensions` | `anthropic.claude-code` |

The label is at the end of the [`Dockerfile`](Dockerfile), with the credential trade-offs
explained above it.

Verify a pulled image (signature, and build provenance), or read its SPDX SBOM:

```sh
gh attestation verify oci://ghcr.io/pampatzoglou/devcontainer:<version> --owner pampatzoglou
cosign verify ghcr.io/pampatzoglou/devcontainer:<version> \
  --certificate-identity-regexp '^https://github.com/pampatzoglou/devcontainer/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
docker buildx imagetools inspect ghcr.io/pampatzoglou/devcontainer:<version> \
  --format '{{ json (index .SBOM "linux/amd64").SPDX }}'
```

## What's inside

| Area | Tools |
|---|---|
| Kubernetes | kubectl, helm, kind, istioctl, cilium, skaffold, kubeconform, kubelogin (`kubectl oidc-login`) |
| Cloud / IaC | terraform, vault, aws |
| Observability | promtool, amtool |
| Supply chain / lint | trivy, cosign, hadolint, pre-commit |
| Languages | python (via uv) |
| AI | claude (Claude Code, native binary; auto-updater off) with the mentor plugins |
| General | task, just, direnv, jq, yq, gh, k6, vim |

`direnv` is hooked into bash and zsh, and the `mkhl.direnv` VS Code extension applies the
same environment to editor processes. A repo's `.envrc` loads after `direnv allow` (once per
checkout; nothing from a clone runs unapproved).

Versions: the `ARG` block at the top of [`Dockerfile`](Dockerfile).

### Language toolchains

Go, Rust, Node and Java are not baked in; add the ones a repo needs as features in its
`devcontainer.json`, next to `docker-in-docker`:

```jsonc
{
  "image": "ghcr.io/pampatzoglou/devcontainer:<version>",
  "features": {
    // Go toolchain + gopls etc.; pin the Go version the repo's go.mod expects.
    "ghcr.io/devcontainers/features/go:1.4.1": { "version": "1.27.4" },
    // rustup + toolchain; add components the repo's CI uses.
    "ghcr.io/devcontainers/features/rust:1.6.1": {
      "version": "1.100.0",
      "profile": "minimal",
      "components": "clippy,rustfmt,rust-analyzer"
    },
    // Node via nvm; "lts" or an exact version.
    "ghcr.io/devcontainers/features/node:2.1.2": { "version": "22.23.5" },
    // JDK via SDKMAN; Temurin 21.
    "ghcr.io/devcontainers/features/java:1.8.3": { "version": "21", "jdkDistro": "tem" }
  }
}
```

Pin each feature to an exact version, as with docker-in-docker; Dependabot's `devcontainers`
ecosystem bumps them in the consuming repo. Features download their toolchains at container
build time with the feature's own verification, not this image's committed-sha256 pins.

### Optional tools

kubescape isn't baked in either. It has no official feature; the maintained generic
`gh-release` feature installs it from the GitHub release (no checksum verification):

```jsonc
"features": {
  "ghcr.io/devcontainers-extra/features/gh-release:1.0.26": {
    "repo": "kubescape/kubescape",
    "binaryNames": "kubescape",
    "version": "4.0.20",
    "assetRegex": "^kubescape_.*\\.tar\\.gz$"
  }
}
```

Tested on this image, amd64 and arm64: the feature picks the right `linux_<arch>` tarball and
`kubescape version` reports 4.0.20. At install time it also downloads its helper, nanolayer.

### Claude Code

`claude` is on the `PATH`, and the VS Code extension is installed. All of its state, login
included, is under `CLAUDE_CONFIG_DIR=/home/vscode/.claude`. A rebuild wipes that unless the
consuming repo mounts a volume there (mounts can't be inherited from the image):

```jsonc
"mounts": [
  "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The [mentor](https://github.com/pampatzoglou/mentor) plugins ship in the image and are on by
default: `mentor` (the `mentor:*` skills) and `personas` (the `/personas:*` commands). They
work like `/plugin marketplace add pampatzoglou/mentor` plus both installs, except they're
pinned to the commit in `MENTOR_SHA`:

- The checkout is at `/opt/claude-marketplaces/mentor`, and
  `/etc/claude-code/managed-settings.json` declares it as a marketplace. Nothing is cloned at
  runtime, and the plugins don't auto-update.
- The `claude-plugins` step of the image's `postCreateCommand` enables both in user settings
  (`~/.claude/settings.json`). It only adds entries that aren't there yet, so if you turn one
  off yourself, it stays off after a rebuild.

A repo opts out in its committed `.claude/settings.json`, which takes precedence over user
settings:

```json
{ "enabledPlugins": { "personas@mentor": false } }
```

### Egress firewall (opt-in)

For running an agent unattended (e.g. `claude --dangerously-skip-permissions`), restrict the
container's outbound traffic to GitHub, the Claude and VS Code endpoints, and whatever you list:

```jsonc
"runArgs": ["--cap-add=NET_ADMIN", "--cap-add=NET_RAW"],
// Extra domains / IPv4 CIDRs the repo needs: Vault, cluster API, registries, …
"postStartCommand": "sudo /usr/local/bin/init-firewall vault.example.com 10.0.0.0/8"
```

On first run it **removes `vscode`'s passwordless sudo** (otherwise anything inside could just
`sudo iptables -F`) and **freezes the allowlist** to those arguments; only `init-firewall`
itself stays sudo-able, and only with the same arguments. To change the list, edit
`devcontainer.json` and rebuild. Re-run it by hand to re-resolve domains whose IPs rotated.

Trade-offs: no `sudo apt install` once it's on; DNS stays open (tunnelling possible); IPv6 is
blocked outright; it flushes all iptables rules, so it doesn't combine with docker-in-docker.
Details are in the header of [`image/init-firewall.sh`](image/init-firewall.sh), which is
adapted from [Anthropic's reference devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer).

## Develop

Needs Docker with buildx, [go-task](https://taskfile.dev), `hadolint` and `uv`.

| Task | Does |
|---|---|
| `task audit` | Pre-merge gate: `validate` (lock + hash pins consistent) and `lint` (hadolint, actionlint, shellcheck) |
| `task build` | Build and load for the local platform as `…:dev` (`PLATFORM=linux/amd64` to override) |
| `task pin` | Refresh every `<TOOL>_SHA256_<ARCH>` from upstream's sums, both arches |
| `task lock` | Regenerate `pre-commit.lock` for `PRECOMMIT_VERSION` from a PyPI snapshot 3 days back |

### Bump a tool

1. Edit its `*_VERSION` ARG (take a release at least 3 days old; for Claude Code, the
   `stable` channel: `curl -fsSL https://downloads.claude.ai/claude-code-releases/stable`;
   for the mentor plugins, `MENTOR_SHA`: `gh api repos/pampatzoglou/mentor/commits/main -q .sha`).
2. `task pin` — rewrites the hash ARGs; review the diff.
   (pre-commit: `task lock` instead. AWS CLI: no hashes, verified by GPG — see below.
   Python is verified by uv.)
3. `task audit && task build`, then open a PR.

Dependabot bumps the base image digest, the docker-in-docker feature and the GitHub Actions;
tool ARGs are bumped by hand.

### AWS CLI signing key

`keys/aws-cli.asc` is the public key from the
[AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html);
the build checks it against `AWS_CLI_SIGNER_FPR`. It expires 2027-07-01 — re-copy it from the
guide when AWS renews it.

## Release

| Trigger | Tags pushed |
|---|---|
| push to `main` | `latest`, `sha-<short>` |
| tag `vX.Y.Z` | `X.Y.Z`, `X.Y` |

Pin consumers to `X.Y.Z` (or a digest), not `latest`.

CI (`.github/workflows/default.yaml`) runs `scripts/validate.sh`, hadolint, actionlint and
shellcheck,
then a native build per arch that Trivy scans for fixable CRITICAL/HIGH vulnerabilities. Only
Ubuntu packages fail the job (the base-image digest fixes those); everything, including the
upstream tool binaries, is uploaded as SARIF to the repo's Security → Code scanning tab.

`release.yaml` builds each arch on its own native runner (`ubuntu-24.04`, `ubuntu-24.04-arm`;
no QEMU) through `.github/actions/build-push`, pushing it untagged by digest with an SPDX
SBOM. `.github/actions/merge-push` then combines the digests into one multi-arch index, tags
it, and `.github/actions/attest-sign` attaches a signed build-provenance attestation and
cosign-signs the index digest, which covers both platforms and their SBOMs. Both workflows
share the per-arch GHA layer cache.
