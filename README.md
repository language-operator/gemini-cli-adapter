# gemini-cli-adapter

The **Gemini CLI** runtime for the [Language Operator](https://github.com/language-operator/language-operator),
running as a native Kubernetes workload.

It builds the runtime image and the Helm chart that registers the `gemini-cli`
`LanguageAgentRuntime`. The Gemini CLI TUI runs inside tmux and is fronted by an
xterm.js / WebSocket terminal in the browser, so working with the agent feels like
a real terminal session.

This repo was created from the [`opencode-adapter`](https://github.com/language-operator/opencode-adapter) template.

> **Status:** renamed, not yet wired up. The image installs Gemini CLI and passes the
> runtime contract, but the emitter does not yet translate the operator's config
> (gateway, MCP servers, instructions) — that is
> [#1](https://github.com/language-operator/gemini-cli-adapter/issues/1).

## Architecture

The image is [`coding-runtime`](https://github.com/language-operator/coding-runtime)
plus Gemini CLI. The base owns the OS layer, the web terminal (xterm.js over
a node-pty WebSocket bridge, with a cross-origin guard and a 25s keepalive), `tini`,
and the ETL that turns the operator's `/etc/agent/config.yaml` into a normalized
config. What lives here is the three files that describe Gemini CLI to it:

- **`runtime.json`** — the manifest: where state goes (`GEMINI_CLI_HOME`, under
  `$STATE_DIR/gemini`, so the CLI never writes to the read-only root), the serving
  surface, and how tmux launches the TUI.
- **`emit.mjs`** — the emitter: normalized config → Gemini CLI config. A placeholder
  that writes nothing until #1.
- **`launch-gemini-cli.sh`** — what tmux runs. The base has already set the working
  directory (the cloned repo when the agent sets `spec.repository`, else
  `/workspace`), so it opens that project directly.

One container, running the base entrypoint: resolve the environment, seed config,
serve. Seeding runs in the agent container rather than an init container because
the operator mounts `/tmp` there only, so the two would share no writable path.
tmux keeps the session alive across browser reconnects.

## Install

Prerequisite: the [`language-operator`](https://github.com/language-operator/language-operator)
chart must be installed first — it provides the `LanguageAgentRuntime` CRD.

```bash
helm install gemini-cli oci://ghcr.io/language-operator/charts/gemini-cli \
  --namespace language-operator
```

Then reference it from a `LanguageAgent`:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: my-agent
spec:
  runtime: gemini-cli
```

## Authentication

The runtime sets `auth.enabled: true`, so access is gated entirely by the cluster's
OIDC proxy: when the `LanguageCluster` has auth enabled the operator injects an
oauth2-proxy sidecar in front of the terminal. There is no built-in password — if
the cluster does not enable auth, the terminal is exposed unauthenticated on its
ingress. Gemini CLI reaches the model gateway through config written at startup,
never an interactive OAuth login, which would bypass the gateway.

## Development

```bash
make build      # docker build -t ghcr.io/language-operator/gemini-cli-adapter:latest .
make test       # build, then run the coding-runtime conformance suite
make publish    # build and push the image to ghcr.io
make dev        # build, import into k3s, and upgrade the runtime release (inner loop)

helm lint chart
helm template gemini-cli chart
```

## CI

- `build-image.yaml` — builds and pushes the image to `ghcr.io` on push to `main` and `v*` tags.
- `release-chart.yaml` — packages `chart/` and pushes it to `oci://ghcr.io/language-operator/charts`.
- `test.yaml` — builds the image, runs the `coding-runtime` conformance suite against
  it under the operator's posture (read-only root, uid 1000, all capabilities dropped),
  and lints/templates the chart on every PR. The suite is taken out of the image rather
  than fetched, so the checks always match the runtime being checked, and no failures are
  tolerated.
