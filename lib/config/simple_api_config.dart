// lib/config/simple_api_config.dart
class SimpleApiConfig {
  // IMPORTANTE: Reemplaza este valor con tu API Key real de Sportradar
  // Para obtener tu API Key:
  // 1. Ve a https://developer.sportradar.com/
  // 2. Crea una cuenta o inicia sesión
  // 3. Solicita acceso trial para MLB API v8
  // 4. Copia tu API Key y reemplaza la línea de abajo

  static const String sportradarApiKey = 'k9ln4pfG2RwsgCCIXG1620hlMwGspvrCcHCqgNdO';

  // URLs base para la API
  static const String mlbApiBaseUrl = 'http://api.sportradar.us/mlb/trial/v8/en';

  // Límites del trial
  static const int maxTrialCalls = 1000;
  static const int callsPerSecond = 1;

  // Configuración de la app
  static const String appName = 'EpicSports MLB';
  static const String appVersion = '1.0.0';

  // Validar configuración
  static bool get isConfigured =>
      sportradarApiKey != 'YOUR_SPORTRADAR_API_KEY_HERE' &&
      sportradarApiKey.isNotEmpty &&
      sportradarApiKey.length > 10;

  // Mensaje de error si no está configurado
  static const String apiKeyNotConfiguredMessage = '''
⚠️ API Key de Sportradar no configurada correctamente.

Para configurar tu API Key:
1. Ve a https://developer.sportradar.com/
2. Crea una cuenta y solicita acceso trial para MLB API v8
3. Copia tu API Key
4. Abre el archivo lib/config/simple_api_config.dart
5. Reemplaza el valor de 'sportradarApiKey' con tu API Key real

Nota: El trial incluye 1,000 llamadas totales con límite de 1 llamada por segundo.
''';

  // Información de debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'api_key_configured': isConfigured,
      'api_key_length': sportradarApiKey.length,
      'api_key_preview': sportradarApiKey.length > 10 
          ? '${sportradarApiKey.substring(0, 8)}...'
          : 'No configurada',
      'base_url': mlbApiBaseUrl,
      'max_calls': maxTrialCalls,
      'rate_limit': '$callsPerSecond llamada(s) por segundo',
    };
  }

  // URLs de endpoints específicos
  static String getTodayScheduleUrl() {
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    return '$mlbApiBaseUrl/games/$dateStr/schedule.json?api_key=$sportradarApiKey';
  }

  static String getTodayBoxscoreUrl() {
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    return '$mlbApiBaseUrl/games/$dateStr/boxscore.json?api_key=$sportradarApiKey';
  }

  static String getTestUrl() {
    return '$mlbApiBaseUrl/league/hierarchy.json?api_key=$sportradarApiKey';
  }

  // Validación de respuesta de API
  static bool isValidApiResponse(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'API Key inválida o expirada';
      case 403:
        return 'Acceso denegado - verifica tu suscripción';
      case 429:
        return 'Límite de llamadas excedido';
      case 404:
        return 'Endpoint no encontrado';
      case 500:
        return 'Error interno del servidor de Sportradar';
      case 503:
        return 'Servicio temporalmente no disponible';
      default:
        return 'Error HTTP: $statusCode';
    }
  }
}