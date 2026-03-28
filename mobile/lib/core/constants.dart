/// Base URL del backend.
/// - Android emulator: usa 10.0.2.2 (mappa a localhost del host)
/// - iOS Simulator: usa localhost
/// - Dispositivo fisico: inserisci l'IP del tuo PC sulla rete locale
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
