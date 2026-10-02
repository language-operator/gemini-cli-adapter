/**
 * Gemini CLI emitter.
 *
 * Gemini CLI reads its user settings from $GEMINI_CLI_HOME/.gemini/settings.json,
 * and runtime.json points GEMINI_CLI_HOME at ${STATE_DIR}/gemini. That file also
 * holds the user's own choices (theme, editor, ...), so only the exact paths
 * below are owned, never the `security` object as a whole.
 *
 * For now this only gets the TUI past the two dialogs that would otherwise stand
 * between the terminal and the prompt. Translating the operator's config —
 * the gateway (GEMINI_API_KEY / GOOGLE_GEMINI_BASE_URL), `mcpServers`, and
 * standing instructions as GEMINI.md — is the runtime bootstrap, issue #1.
 */

export function emit(config) {
  const configDir = `${config.paths.stateDir}/gemini/.gemini`;

  return [
    {
      path: `${configDir}/settings.json`,
      owns: ['security.folderTrust.enabled', 'security.auth.selectedType'],
      values: {
        // The workspace is the one the operator provisioned for this agent, so
        // there is nobody to ask whether to trust it; the trust dialog would only
        // block the terminal.
        'security.folderTrust.enabled': false,
        // API-key auth only, so the TUI never offers "Sign in with Google": an
        // OAuth login would go around the cluster's model gateway.
        'security.auth.selectedType': 'gemini-api-key',
      },
    },
  ];
}

export default emit;
