const kBackendUrlFromBuild = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8080',
);

const kBackendPrefKey = 'backend_url';
const kJwtPrefKey = 'jwt_token';
const kActiveGameSessionPrefKey = 'active_game_session_id';
