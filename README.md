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
| `postCreateCommand` | `pre-commit install --install-hooks` if the repo has a `.pre-commit-config.yaml` |

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
| Kubernetes | kubectl, helm, kind, istioctl, cilium, skaffold, kubeconform, kubescape, kubelogin (`kubectl oidc-login`) |
| Cloud / IaC | terraform, vault, aws |
| Supply chain / lint | trivy, cosign, hadolint, pre-commit |
| Languages | go, rust (clippy, rustfmt, rust-analyzer), node, python (via uv), Temurin JDK 21 |
| General | task, jq, yq, gh, k6, vim |

Versions: the `ARG` block at the top of [`Dockerfile`](Dockerfile).

## Develop

Needs Docker with buildx, [go-task](https://taskfile.dev), `hadolint` and `uv`.

| Task | Does |
|---|---|
| `task audit` | Pre-merge gate: `validate` (lock + hash pins consistent) and `lint` (hadolint, actionlint) |
| `task build` | Build and load for the local platform as `…:dev` (`PLATFORM=linux/amd64` to override) |
| `task pin` | Refresh every `<TOOL>_SHA256_<ARCH>` from upstream's sums, both arches |
| `task lock` | Regenerate `pre-commit.lock` for `PRECOMMIT_VERSION` from a PyPI snapshot 3 days back |

### Bump a tool

1. Edit its `*_VERSION` ARG (take a release at least 3 days old).
2. `task pin` — rewrites the hash ARGs; review the diff.
   (pre-commit: `task lock` instead. AWS CLI: no hashes, verified by GPG — see below.
   Python and Rust are verified by uv / rustup.)
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

CI (`.github/workflows/default.yaml`) runs `scripts/validate.sh`, hadolint and actionlint,
then a native build per arch that Trivy scans for fixable CRITICAL/HIGH vulnerabilities. Only
Ubuntu packages fail the job (the base-image digest fixes those); everything, including the
upstream tool binaries, is uploaded as SARIF to the repo's Security → Code scanning tab.

`release.yaml` builds each arch on its own native runner (`ubuntu-24.04`, `ubuntu-24.04-arm`;
no QEMU) through `.github/actions/build-push`, pushing it untagged by digest with an SPDX
SBOM. `.github/actions/merge-push` then combines the digests into one multi-arch index, tags
it, and `.github/actions/attest-sign` attaches a signed build-provenance attestation and
cosign-signs the index digest, which covers both platforms and their SBOMs. Both workflows
share the per-arch GHA layer cache.

The first push creates the GHCR package as private; make it public in the package settings
if consumers should pull anonymously.
