// lib/config/api_config.dart
class ApiConfig {
  // IMPORTANTE: Reemplaza este valor con tu API Key real de Sportradar
  // Para obtener tu API Key:
  // 1. Ve a https://developer.sportradar.com/
  // 2. Crea una cuenta o inicia sesión
  // 3. Solicita acceso trial para MLB API v8
  // 4. Copia tu API Key y reemplaza la línea de abajo

  static const String sportradarApiKey =
      'k9ln4pfG2RwsgCCIXG1620hlMwGspvrCcHCqgNdO';

  // URLs base para diferentes APIs
  static const String mlbApiBaseUrl =
      'http://api.sportradar.us/mlb/trial/v8/en';

  // Límites del trial
  static const int maxTrialCalls = 1000;
  static const int callsPerSecond = 1;

  // Configuración de la app
  static const String appName = 'MLB Stats App';
  static const String appVersion = '1.0.0';

  // Validar configuración
  static bool get isConfigured =>
      sportradarApiKey != 'YOUR_SPORTRADAR_API_KEY_HERE' &&
      sportradarApiKey.isNotEmpty;

  // Mensajes de error
  static const String apiKeyNotConfiguredMessage = '''
API Key de Sportradar no configurada.

Para configurar tu API Key:
1. Ve a https://developer.sportradar.com/
2. Crea una cuenta y solicita acceso trial para MLB API v8
3. Copia tu API Key
4. Abre el archivo lib/config/api_config.dart
5. Reemplaza 'YOUR_SPORTRADAR_API_KEY_HERE' con tu API Key real

Nota: El trial incluye 1,000 llamadas totales con límite de 1 llamada por segundo.
''';
}
