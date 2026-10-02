#!/bin/sh
# What tmux runs. The base already starts tmux in the working directory, so the
# CLI opens straight into the project. GEMINI_CLI_HOME is set from runtime.json,
# which keeps Gemini CLI's own state off the read-only root filesystem.
#
# Resuming a slept agent's conversation, and the config this reads, arrive with
# the runtime bootstrap (#1).
set -eu

exec gemini "$@"
