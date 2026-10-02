# -----------------------------------------------------------------------------
# Gemini CLI adapter.
#
# The OS layer, the web terminal, tini, and the /etc/agent/config.yaml ETL all
# live in coding-runtime. What is left here is Gemini CLI plus the three
# files that describe it to the base: a manifest, an emitter, and a launcher.
#
# The base is pinned by tag *and* digest. Never :latest, and never a `main`
# build — metadata-action stamps those with the version literal `main`, which no
# `requires.codingRuntime` range can satisfy, so every boot would warn about a
# version mismatch that is not real.
# -----------------------------------------------------------------------------
ARG BASE=ghcr.io/language-operator/coding-runtime:0.1.4@sha256:2f31ef9b04e72bec3a4bb79db59a82a4aa74f89538cfc118d75e0a852734b0aa
ARG GEMINI_CLI_VERSION=0.62.0

FROM ${BASE}
ARG GEMINI_CLI_VERSION

# Gemini CLI (TUI), installed as the `gemini` binary. Pinned — do not track
# `latest`, so runtime behaviour is reproducible.
USER root
RUN npm install -g --no-audit --no-fund "@google/gemini-cli@${GEMINI_CLI_VERSION}" \
    && npm cache clean --force

# runtime.json  — what this adapter is: config dir, serving surface, tmux launch.
# emit.mjs      — normalized operator config -> Gemini CLI settings.json.
# launch-gemini-cli — what tmux runs inside the terminal.
COPY runtime.json /etc/coding-runtime/runtime.json
COPY emit.mjs /opt/adapter/emit.mjs
COPY --chmod=755 launch-gemini-cli.sh /usr/local/bin/launch-gemini-cli

# The operator pins the agent container to uid 1000 with no override, and the
# base already has a matching passwd entry. Do not create a user here.
USER node
