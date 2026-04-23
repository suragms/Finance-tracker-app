const bool kNoApiMode = bool.fromEnvironment(
  'NO_API_MODE',
  defaultValue: false,
);

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.moneyflow.app',
);

// Backward-compatible alias for existing callers.
const String kApiBase = kApiBaseUrl;
