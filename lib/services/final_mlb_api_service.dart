// lib/services/final_mlb_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mlb_game.dart';
import '../config/api_config.dart';
import 'advanced_cache_manager.dart';
import 'package:flutter/foundation.dart';

class FinalMLBApiService {
  static const String _apiKey = ApiConfig.sportradarApiKey;
  static const String _baseUrl = ApiConfig.mlbApiBaseUrl;

  final AdvancedCacheManager _cacheManager = AdvancedCacheManager();

  // Control de rate limiting
  static DateTime? _lastApiCall;
  static int _apiCallsToday = 0;
  static DateTime? _lastCallDate;
  static const int _maxCallsPerDay = 850; // Reservar más llamadas
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
      debugPrint('🔄 Contador de API reseteado para nuevo día');
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
      if (cachedGames != null) {
        debugPrint('✅ Usando datos del cache (${cachedGames.length} juegos)');
        
        // Si hay juegos en vivo, verificar si necesitamos actualización
        final liveGames = cachedGames.where((game) => game.isLive).toList();
        if (liveGames.isNotEmpty && _canMakeApiCall()) {
          // Actualizar solo marcadores en segundo plano
          _updateLiveGameScoresInBackground(liveGames);
        }
        
        return cachedGames;
      }

      // 2. Si no hay cache válido, hacer llamada a API
      if (!_canMakeApiCall()) {
        debugPrint('⚠️ No se pueden hacer llamadas API, usando último cache disponible');
        final lastCache = await _cacheManager.getCachedGamesFromFirestore(dateKey);
        return lastCache ?? [];
      }

      debugPrint('🔗 Obteniendo datos frescos de la API...');
      final games = await _fetchGamesFromApi(dateKey);
      
      // 3. Guardar en cache
      if (games.isNotEmpty) {
        await _cacheManager.cacheGamesToFirestore(dateKey, games);
      }
      
      return games;
    } catch (e) {
      debugPrint('❌ Error en getTodaysGames: $e');
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

    debugPrint('🔗 API Call #$_apiCallsToday: $url');

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
              debugPrint('🔄 Obteniendo marcador para juego completado: ${game.id}');
              final detailedGame = await _getGameDetails(game.id);
              if (detailedGame != null && detailedGame.score != null) {
                game = detailedGame;
                debugPrint('✅ Marcador obtenido: ${game.score}');
              }
            }
            
            games.add(game);
          } catch (e) {
            debugPrint('❌ Error parseando juego: $e');
          }
        }
      }

      debugPrint('✅ ${games.length} juegos obtenidos de la API');
      debugPrint('📊 Llamadas restantes hoy: ${_maxCallsPerDay - _apiCallsToday}');
      
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
        debugPrint('⚠️ Rate limit alcanzado');
        break;
      case 503:
        _lastError = 'Servicio temporalmente no disponible';
        _isConnected = false;
        break;
      default:
        _lastError = 'Error HTTP: $statusCode';
        debugPrint('❌ Error API: $statusCode - $responseBody');
    }
  }

  // Actualización inteligente solo para juegos en vivo
  Future<void> _updateLiveGameScoresInBackground(List<MLBGame> liveGames) async {
    // No bloquear la UI, ejecutar en background
    Future.delayed(Duration.zero, () async {
      try {
        for (var game in liveGames) {
          if (!_canMakeApiCall()) break;
          
          final updatedGame = await _getGameDetails(game.id);
          if (updatedGame != null) {
            await _cacheManager.cacheSpecificGame(updatedGame);
            debugPrint('🔄 Marcador actualizado para ${game.id}');
          }
          
          // Esperar entre llamadas para juegos en vivo
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('❌ Error actualizando marcadores en background: $e');
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
        debugPrint('⚠️ No se pueden hacer más llamadas para detalles');
        return null;
      }

      await _waitForRateLimit();

      // Intentar primero con boxscore para obtener marcadores completos
      final boxscoreUrl = '$_baseUrl/games/$gameId/boxscore.json?api_key=$_apiKey';
      debugPrint('🔗 Intentando boxscore para $gameId');
      
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
        debugPrint('❌ Error en boxscore: ${response.statusCode}, intentando summary...');
        
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
      debugPrint('❌ Error obteniendo detalles del juego: $e');
      return null;
    }
  }

  // Método optimizado para obtener solo juegos en vivo
  Future<List<MLBGame>> getLiveGames() async {
    final allGames = await getTodaysGames();
    return allGames.where((game) => game.isLive).toList();
  }

  // Stream ultra-optimizado
  Stream<List<MLBGame>> getOptimizedGamesStream() async* {
    while (true) {
      try {
        final games = await getTodaysGames();
        yield games;

        // Intervalo dinámico basado en condiciones
        Duration waitTime = _calculateOptimalWaitTime(games);
        
        debugPrint('⏱️ Próxima actualización en ${waitTime.inMinutes} minutos');
        await Future.delayed(waitTime);
      } catch (e) {
        debugPrint('❌ Error en stream optimizado: $e');
        yield [];
        await Future.delayed(Duration(minutes: 5));
      }
    }
  }

  Duration _calculateOptimalWaitTime(List<MLBGame> games) {
    final now = DateTime.now();
    final hasLiveGames = games.any((game) => game.isLive);
    
    // Contar juegos que empiezan pronto
    final upcomingGames = games.where((game) {
      final scheduledTime = game.scheduledTime;
      if (scheduledTime == null) return false;
      final timeDiff = scheduledTime.difference(now);
      return timeDiff.inMinutes > 0 && timeDiff.inMinutes <= 60;
    }).length;

    // Lógica de intervalo inteligente
    if (hasLiveGames) {
      // Juegos en vivo: actualizar frecuentemente pero sin exceso
      return Duration(minutes: 3);
    } else if (upcomingGames > 0) {
      // Juegos próximos: actualizaciones moderadas
      return Duration(minutes: 8);
    } else if (_apiCallsToday > (_maxCallsPerDay * 0.8)) {
      // Si estamos cerca del límite diario: ser muy conservadores
      return Duration(minutes: 30);
    } else {
      // Solo juegos programados: actualizaciones espaciadas
      return Duration(minutes: 15);
    }
  }

  // Métodos de gestión de cache
  Future<void> clearCache() async {
    await _cacheManager.clearAllCache();
    debugPrint('🗑️ Cache completamente limpiado');
  }

  Future<void> invalidateTodayCache() async {
    final dateKey = _cacheManager.getTodayDateKey();
    await _cacheManager.invalidateCache(dateKey);
    debugPrint('❌ Cache de hoy invalidado');
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
        // Extraer valores específicos para el banner
        'cacheActive': cacheInfo['cache_active'] ?? false,
        'cacheSize': cacheInfo['cache_size'] ?? 0,
        'cacheAge': cacheInfo['cache_age'],
        'apiCallsToday': _apiCallsToday,
        'remainingCalls': _maxCallsPerDay - _apiCallsToday,
        'canMakeApiCall': _canMakeApiCall(),
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estado del servicio: $e');
      return {
        'api_calls_today': _apiCallsToday,
        'remaining_calls': _maxCallsPerDay - _apiCallsToday,
        'can_make_api_call': _canMakeApiCall(),
        'is_connected': _isConnected,
        'last_error': _lastError ?? e.toString(),
        'last_api_call': _lastApiCall?.toIso8601String(),
        'cache_info': {},
        'cacheActive': false,
        'cacheSize': 0,
        'cacheAge': null,
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
        debugPrint('⚠️ No se puede hacer test - límite alcanzado');
        return _isConnected;
      }

      await _waitForRateLimit();
      
      final url = '$_baseUrl/league/hierarchy.json?api_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      final isConnected = response.statusCode == 200;
      _isConnected = isConnected;
      
      if (isConnected) {
        _lastError = null;
        debugPrint('✅ Test de conexión exitoso');
      } else {
        _handleApiError(response.statusCode, response.body);
      }
      
      return isConnected;
    } catch (e) {
      debugPrint('❌ Error en test de conexión: $e');
      _lastError = e.toString();
      _isConnected = false;
      return false;
    }
  }

  // Limpieza automática de cache antiguo
  Future<void> performMaintenanceTasks() async {
    try {
      await _cacheManager.cleanOldCache();
      await _cacheManager.preloadUpcomingDates();
      debugPrint('🧹 Tareas de mantenimiento completadas');
    } catch (e) {
      debugPrint('❌ Error en tareas de mantenimiento: $e');
    }
  }

  // Estadísticas detalladas
  Future<Map<String, dynamic>> getDetailedStats() async {
    final cacheStats = await _cacheManager.getCacheStats();
    return {
      ...getServiceStatus(),
      'cache_stats': cacheStats,
      'efficiency': {
        'cache_hit_potential': cacheStats['daily_caches'] ?? 0 > 0,
        'api_usage_percentage': (_apiCallsToday / _maxCallsPerDay * 100).toStringAsFixed(1),
        'is_optimized': _apiCallsToday < 100, // Menos de 100 llamadas es óptimo
      }
    };
  }

  bool isApiKeyConfigured() {
    return ApiConfig.isConfigured;
  }

  // Método para forzar actualización de un juego específico
  Future<MLBGame?> forceUpdateGame(String gameId) async {
    if (!_canMakeApiCall()) {
      debugPrint('⚠️ No se puede forzar actualización - límite alcanzado');
      return null;
    }

    try {
      // Invalidar cache específico usando el método público del cache manager
      await _cacheManager.invalidateSpecificGame(gameId);

      // Obtener datos frescos
      final updatedGame = await _getGameDetails(gameId);
      debugPrint('🔄 Juego $gameId actualizado forzosamente');
      return updatedGame;
    } catch (e) {
      debugPrint('❌ Error en actualización forzosa: $e');
      return null;
    }
  }
}