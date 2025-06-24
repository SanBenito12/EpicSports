// lib/services/final_mlb_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mlb_game.dart';
import '../config/api_config.dart';
import 'advanced_cache_manager.dart';

class FinalMLBApiService {
  static const String _apiKey = ApiConfig.sportradarApiKey;
  static const String _baseUrl = ApiConfig.mlbApiBaseUrl;

  final AdvancedCacheManager _cacheManager = AdvancedCacheManager();

  // Control de rate limiting
  static DateTime? _lastApiCall;
  static int _apiCallsToday = 0;
  static DateTime? _lastCallDate;
  static const int _maxCallsPerDay = 850;
  static const Duration _minimumInterval = Duration(seconds: 1);

  // Estado de conexión
  static bool _isConnected = true;
  static String? _lastError;

  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed < _minimumInterval) {
        await Future.delayed(_minimumInterval - elapsed);
      }
    }
    _lastApiCall = DateTime.now();
    
    // Resetear contador diario
    final today = DateTime.now();
    if (_lastCallDate == null || 
        _lastCallDate!.day != today.day || 
        _lastCallDate!.month != today.month || 
        _lastCallDate!.year != today.year) {
      _apiCallsToday = 0;
      _lastCallDate = today;
    }
    
    _apiCallsToday++;
  }

  bool _canMakeApiCall() {
    return _apiCallsToday < _maxCallsPerDay && _isConnected;
  }

  Future<List<MLBGame>> getTodaysGames() async {
    final dateKey = _cacheManager.getTodayDateKey();
    
    try {
      // 1. Verificar cache primero
      final cachedGames = await _cacheManager.getCachedGamesFromFirestore(dateKey);
      if (cachedGames != null && cachedGames.isNotEmpty) {
        print('📦 Usando cache: ${cachedGames.length} juegos');
        
        // Si hay juegos en vivo, intentar actualizar marcadores
        final liveGames = cachedGames.where((game) => game.isLive).toList();
        if (liveGames.isNotEmpty && _canMakeApiCall()) {
          _updateLiveGameScoresInBackground(liveGames);
        }
        
        return cachedGames;
      }

      // 2. Si no hay cache válido, hacer llamada a API
      if (!_canMakeApiCall()) {
        print('⚠️ Límite de API alcanzado, usando último cache');
        final lastCache = await _cacheManager.getCachedGamesFromFirestore(dateKey);
        return lastCache ?? [];
      }

      print('🔗 Obteniendo datos frescos de la API...');
      final games = await _fetchGamesFromApi(dateKey);
      
      // 3. Guardar en cache
      if (games.isNotEmpty) {
        await _cacheManager.cacheGamesToFirestore(dateKey, games);
      }
      
      return games;
    } catch (e) {
      print('❌ Error en getTodaysGames: $e');
      _lastError = e.toString();
      
      // En caso de error, intentar devolver cache aunque sea viejo
      final fallbackCache = await _cacheManager.getCachedGamesFromFirestore(dateKey);
      return fallbackCache ?? [];
    }
  }

  Future<List<MLBGame>> _fetchGamesFromApi(String dateKey) async {
    await _waitForRateLimit();

    final now = DateTime.now();
    final dateString = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    final url = '$_baseUrl/games/$dateString/schedule.json?api_key=$_apiKey';

    print('🔗 API Call: ${url.split('?')[0]}');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      _isConnected = true;
      _lastError = null;
      
      final data = json.decode(response.body);
      final games = <MLBGame>[];

      if (data['games'] != null) {
        for (var gameData in data['games']) {
          try {
            var game = MLBGame.fromJson(gameData);
            
            // Si el juego está completado pero no tiene marcador, intentar obtenerlo
            if (game.isCompleted && game.score == null && _canMakeApiCall()) {
              final detailedGame = await _getGameDetails(game.id);
              if (detailedGame != null && detailedGame.score != null) {
                game = detailedGame;
              }
            }
            
            games.add(game);
          } catch (e) {
            print('❌ Error parseando juego: $e');
          }
        }
      }

      print('✅ ${games.length} juegos obtenidos');
      return games;
    } else {
      _handleApiError(response.statusCode, response.body);
      throw 'Error API: ${response.statusCode}';
    }
  }

  void _handleApiError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 401:
        _lastError = 'API Key inválida';
        _isConnected = false;
        break;
      case 429:
        _lastError = 'Límite de llamadas excedido';
        break;
      case 503:
        _lastError = 'Servicio temporalmente no disponible';
        _isConnected = false;
        break;
      default:
        _lastError = 'Error HTTP: $statusCode';
    }
  }

  // Actualización inteligente solo para juegos en vivo
  Future<void> _updateLiveGameScoresInBackground(List<MLBGame> liveGames) async {
    Future.delayed(Duration.zero, () async {
      try {
        for (var game in liveGames) {
          if (!_canMakeApiCall()) break;
          
          final updatedGame = await _getGameDetails(game.id);
          if (updatedGame != null) {
            await _cacheManager.cacheSpecificGame(updatedGame);
          }
          
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('❌ Error actualizando marcadores: $e');
      }
    });
  }

  Future<MLBGame?> _getGameDetails(String gameId) async {
    try {
      // Verificar cache específico primero
      final cachedGame = await _cacheManager.getCachedSpecificGame(gameId);
      if (cachedGame != null) {
        return cachedGame;
      }

      if (!_canMakeApiCall()) {
        return null;
      }

      await _waitForRateLimit();

      // Intentar boxscore para obtener marcadores completos
      final boxscoreUrl = '$_baseUrl/games/$gameId/boxscore.json?api_key=$_apiKey';
      
      final response = await http.get(Uri.parse(boxscoreUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        Map<String, dynamic> gameData;
        if (data['game'] != null) {
          gameData = data['game'];
        } else {
          gameData = data;
        }
        
        final game = MLBGame.fromJson(gameData);
        
        // Cachear inmediatamente
        await _cacheManager.cacheSpecificGame(game);
        
        return game;
      } else {
        // Si boxscore falla, intentar con summary
        if (_canMakeApiCall()) {
          await _waitForRateLimit();
          
          final summaryUrl = '$_baseUrl/games/$gameId/summary.json?api_key=$_apiKey';
          final summaryResponse = await http.get(Uri.parse(summaryUrl));
          
          if (summaryResponse.statusCode == 200) {
            final summaryData = json.decode(summaryResponse.body);
            
            Map<String, dynamic> summaryGameData;
            if (summaryData['game'] != null) {
              summaryGameData = summaryData['game'];
            } else {
              summaryGameData = summaryData;
            }
            
            final summaryGame = MLBGame.fromJson(summaryGameData);
            await _cacheManager.cacheSpecificGame(summaryGame);
            
            return summaryGame;
          }
        }
        
        _handleApiError(response.statusCode, response.body);
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo detalles del juego: $e');
      return null;
    }
  }

  // Método optimizado para obtener solo juegos en vivo
  Future<List<MLBGame>> getLiveGames() async {
    final allGames = await getTodaysGames();
    return allGames.where((game) => game.isLive).toList();
  }

  // Stream optimizado
  Stream<List<MLBGame>> getOptimizedGamesStream() async* {
    while (true) {
      try {
        final games = await getTodaysGames();
        yield games;

        // Intervalo dinámico basado en condiciones
        Duration waitTime = _calculateOptimalWaitTime(games);
        
        await Future.delayed(waitTime);
      } catch (e) {
        print('❌ Error en stream: $e');
        yield [];
        await Future.delayed(Duration(minutes: 5));
      }
    }
  }

  Duration _calculateOptimalWaitTime(List<MLBGame> games) {
    final hasLiveGames = games.any((game) => game.isLive);
    
    if (hasLiveGames) {
      return Duration(minutes: 3);
    } else if (_apiCallsToday > (_maxCallsPerDay * 0.8)) {
      return Duration(minutes: 30);
    } else {
      return Duration(minutes: 15);
    }
  }

  // Métodos de gestión de cache
  Future<void> clearCache() async {
    await _cacheManager.clearAllCache();
    print('🗑️ Cache limpiado');
  }

  Future<void> invalidateTodayCache() async {
    final dateKey = _cacheManager.getTodayDateKey();
    await _cacheManager.invalidateCache(dateKey);
  }

  // Información del estado del servicio
  Map<String, dynamic> getServiceStatus() {
    try {
      final cacheInfo = _cacheManager.getDetailedCacheInfo();
      return {
        'api_calls_today': _apiCallsToday,
        'remaining_calls': _maxCallsPerDay - _apiCallsToday,
        'can_make_api_call': _canMakeApiCall(),
        'is_connected': _isConnected,
        'last_error': _lastError,
        'last_api_call': _lastApiCall?.toIso8601String(),
        'cache_info': cacheInfo,
        'cacheActive': cacheInfo['cache_active'] ?? false,
        'cacheSize': cacheInfo['cache_size'] ?? 0,
        'cacheAge': cacheInfo['cache_age'],
        'apiCallsToday': _apiCallsToday,
        'remainingCalls': _maxCallsPerDay - _apiCallsToday,
        'canMakeApiCall': _canMakeApiCall(),
      };
    } catch (e) {
      return {
        'api_calls_today': _apiCallsToday,
        'remaining_calls': _maxCallsPerDay - _apiCallsToday,
        'can_make_api_call': _canMakeApiCall(),
        'is_connected': _isConnected,
        'last_error': _lastError ?? e.toString(),
        'cacheActive': false,
        'cacheSize': 0,
        'apiCallsToday': _apiCallsToday,
        'remainingCalls': _maxCallsPerDay - _apiCallsToday,
        'canMakeApiCall': _canMakeApiCall(),
      };
    }
  }

  // Test de conexión optimizado
  Future<bool> testApiConnection() async {
    try {
      if (!_canMakeApiCall()) {
        return _isConnected;
      }

      await _waitForRateLimit();
      
      final url = '$_baseUrl/league/hierarchy.json?api_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      final isConnected = response.statusCode == 200;
      _isConnected = isConnected;
      
      if (isConnected) {
        _lastError = null;
        print('✅ Test de conexión exitoso');
      } else {
        _handleApiError(response.statusCode, response.body);
      }
      
      return isConnected;
    } catch (e) {
      print('❌ Error en test de conexión: $e');
      _lastError = e.toString();
      _isConnected = false;
      return false;
    }
  }

  bool isApiKeyConfigured() {
    return ApiConfig.isConfigured;
  }

  // Método para forzar actualización de un juego específico
  Future<MLBGame?> forceUpdateGame(String gameId) async {
    if (!_canMakeApiCall()) {
      return null;
    }

    try {
      await _cacheManager.invalidateSpecificGame(gameId);
      final updatedGame = await _getGameDetails(gameId);
      return updatedGame;
    } catch (e) {
      print('❌ Error en actualización forzosa: $e');
      return null;
    }
  }
}