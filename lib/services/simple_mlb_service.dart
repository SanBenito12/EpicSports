// lib/services/simple_mlb_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/simple_mlb_models.dart';

class SimpleMLBService {
  // IMPORTANTE: Reemplaza con tu API Key real
  static const String _apiKey = 'k9ln4pfG2RwsgCCIXG1620hlMwGspvrCcHCqgNdO';
  static const String _baseUrl = 'http://api.sportradar.us/mlb/trial/v8/en';
  
  // Control básico de rate limiting
  static DateTime? _lastCall;
  static const Duration _minInterval = Duration(seconds: 2);

  /// Método principal: obtener partidos del día con marcadores
  static Future<List<MLBGame>> getTodaysGames() async {
    try {
      // Control de rate limiting
      await _waitForRateLimit();
      
      final today = DateTime.now();
      final dateString = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
      
      debugPrint('🔗 Obteniendo partidos para: $dateString');
      
      // Intentar primero el endpoint de boxscore (tiene todo lo que necesitamos)
      final boxscoreUrl = '$_baseUrl/games/$dateString/boxscore.json?api_key=$_apiKey';
      
      final response = await http.get(
        Uri.parse(boxscoreUrl),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('📡 Respuesta API: ${response.statusCode}');
      debugPrint('📡 Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📡 Keys principales de respuesta: ${data.keys.toList()}');
        final games = _parseBoxscoreResponse(data);
        
        // 🎯 NUEVO: Ordenar juegos por hora programada
        final sortedGames = _sortGamesByScheduledTime(games);
        debugPrint('📅 Juegos ordenados por hora: ${sortedGames.length} total');
        
        return sortedGames;
      } else {
        debugPrint('❌ Error API: ${response.statusCode} - ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        
        // Si boxscore falla, intentar con schedule
        final scheduleGames = await _getScheduleOnly(dateString);
        return _sortGamesByScheduledTime(scheduleGames);
      }
    } catch (e) {
      debugPrint('❌ Error en getTodaysGames: $e');
      return [];
    }
  }

  /// Parsear respuesta de boxscore (incluye marcadores) - CORREGIDO
  static List<MLBGame> _parseBoxscoreResponse(Map<String, dynamic> data) {
    final games = <MLBGame>[];
    
    try {
      // DEBUG: Imprimir estructura completa
      debugPrint('📡 Estructura de respuesta de API:');
      debugPrint('📡 Keys principales: ${data.keys.toList()}');
      
      // 🔧 CORRECCIÓN: La estructura real de SportsRadar boxscore
      List<dynamic> gamesData = [];
      
      // Opción 1: Si viene directo en un array de games
      if (data['games'] != null) {
        gamesData = data['games'] as List<dynamic>;
        debugPrint('📊 Usando estructura: data[games] con ${gamesData.length} juegos');
      }
      // Opción 2: Si viene dentro de league
      else if (data['league'] != null && data['league']['games'] != null) {
        gamesData = data['league']['games'] as List<dynamic>;
        debugPrint('📊 Usando estructura: data[league][games] con ${gamesData.length} juegos');
      }
      // Opción 3: Si cada juego viene como objeto individual
      else if (data.containsKey('game')) {
        // Un solo juego
        gamesData = [data['game']];
        debugPrint('📊 Usando estructura: data[game] - un solo juego');
      }
      // Opción 4: Buscar cualquier key que contenga array de juegos
      else {
        for (var key in data.keys) {
          if (data[key] is List && (data[key] as List).isNotEmpty) {
            final firstItem = (data[key] as List).first;
            if (firstItem is Map && firstItem.containsKey('id')) {
              gamesData = data[key] as List<dynamic>;
              debugPrint('📊 Encontrado array de juegos en key: $key con ${gamesData.length} elementos');
              break;
            }
          }
        }
      }

      if (gamesData.isEmpty) {
        debugPrint('⚠️ No se encontraron juegos en la respuesta');
        debugPrint('📊 Estructura disponible: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}...');
        return games;
      }

      debugPrint('📊 Parseando ${gamesData.length} juegos del boxscore');

      for (int i = 0; i < gamesData.length; i++) {
        try {
          debugPrint('🎮 Parseando juego ${i + 1}/${gamesData.length}');
          final gameData = gamesData[i] as Map<String, dynamic>;
          
          // 🔧 CORRECCIÓN CLAVE: Verificar si el juego está dentro de una key "game"
          Map<String, dynamic> actualGameData;
          if (gameData.containsKey('game')) {
            actualGameData = gameData['game'] as Map<String, dynamic>;
            debugPrint('🎮 Juego encontrado dentro de key "game"');
          } else {
            actualGameData = gameData;
            debugPrint('🎮 Juego está en el nivel principal');
          }
          
          final game = _parseGameFromBoxscore(actualGameData);
          games.add(game);
        } catch (e) {
          debugPrint('❌ Error parseando juego ${i + 1}: $e');
          // Continúa con el siguiente juego
        }
      }
    } catch (e) {
      debugPrint('❌ Error parseando respuesta boxscore: $e');
    }

    debugPrint('✅ ${games.length} juegos parseados correctamente');
    return games;
  }

  /// Parsear un juego individual del boxscore - MEJORADO
  static MLBGame _parseGameFromBoxscore(Map<String, dynamic> gameData) {
    // DEBUG: Imprimir estructura del juego
    debugPrint('🔍 Keys del juego: ${gameData.keys.toList()}');
    
    // Información básica del juego
    final gameId = gameData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final status = gameData['status']?.toString() ?? 'scheduled';
    final scheduled = gameData['scheduled']?.toString() ?? DateTime.now().toIso8601String();
    
    debugPrint('📋 ID: $gameId, Estado: $status, Hora: $scheduled');
    
    // 🔧 CORRECCIÓN: Parsing mejorado de equipos
    Team homeTeam;
    Team awayTeam;
    GameScore? gameScore;
    
    if (gameData['home'] != null && gameData['away'] != null) {
      final homeData = gameData['home'] as Map<String, dynamic>;
      final awayData = gameData['away'] as Map<String, dynamic>;
      
      debugPrint('🏠 Home team keys: ${homeData.keys.toList()}');
      debugPrint('✈️ Away team keys: ${awayData.keys.toList()}');
      
      // Crear equipos usando el constructor manual (ya que fromJson existe pero puede tener estructura diferente)
      homeTeam = Team(
        id: homeData['id']?.toString() ?? '',
        name: homeData['name']?.toString() ?? homeData['full_name']?.toString() ?? 'Home Team',
        market: homeData['market']?.toString() ?? homeData['city']?.toString() ?? '',
        abbreviation: homeData['abbr']?.toString() ?? homeData['abbreviation']?.toString() ?? 'HOME',
      );
      
      awayTeam = Team(
        id: awayData['id']?.toString() ?? '',
        name: awayData['name']?.toString() ?? awayData['full_name']?.toString() ?? 'Away Team',
        market: awayData['market']?.toString() ?? awayData['city']?.toString() ?? '',
        abbreviation: awayData['abbr']?.toString() ?? awayData['abbreviation']?.toString() ?? 'AWAY',
      );
      
      // 🎯 CORRECCIÓN PRINCIPAL: Buscar marcadores de manera más robusta
      final homeRuns = _extractRuns(homeData, 'home');
      final awayRuns = _extractRuns(awayData, 'away');
      
      if (homeRuns != null && awayRuns != null) {
        gameScore = GameScore(homeScore: homeRuns, awayScore: awayRuns);
        debugPrint('📊 ✅ MARCADOR ENCONTRADO: ${awayTeam.abbreviation} $awayRuns - $homeRuns ${homeTeam.abbreviation}');
      } else {
        debugPrint('📊 ❌ No se encontraron marcadores válidos');
        debugPrint('🔍 Home runs data: ${homeData['runs']} (${homeData['runs'].runtimeType})');
        debugPrint('🔍 Away runs data: ${awayData['runs']} (${awayData['runs'].runtimeType})');
      }
    } else {
      // Datos por defecto si no hay información de equipos
      homeTeam = Team(id: '', name: 'Home Team', market: '', abbreviation: 'HOME');
      awayTeam = Team(id: '', name: 'Away Team', market: '', abbreviation: 'AWAY');
      debugPrint('⚠️ Usando equipos por defecto - no se encontraron datos de equipos');
    }
    
    // Venue usando constructor manual
    Venue venue;
    if (gameData['venue'] != null) {
      final venueData = gameData['venue'] as Map<String, dynamic>;
      venue = Venue(
        id: venueData['id']?.toString() ?? '',
        name: venueData['name']?.toString() ?? venueData['venue_name']?.toString() ?? 'Stadium',
        city: venueData['city']?.toString() ?? venueData['location']?.toString() ?? '',
        state: venueData['state']?.toString() ?? venueData['province']?.toString() ?? '',
      );
    } else {
      venue = Venue(id: '', name: 'Stadium', city: 'City', state: 'State');
    }
    
    // Estado del juego
    final isLive = status == 'inprogress';
    final inning = gameData['inning']?.toString();
    final inningHalf = gameData['inning_half']?.toString();

    debugPrint('✅ Juego parseado: ${awayTeam.name} @ ${homeTeam.name} en ${venue.name}');
    
    return MLBGame(
      id: gameId,
      status: status,
      scheduled: scheduled,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      score: gameScore,
      inning: inning,
      inningHalf: inningHalf,
      venue: venue,
      isLive: isLive,
    );
  }

  /// 🎯 FUNCIÓN NUEVA: Extraer runs de manera robusta
  static int? _extractRuns(Map<String, dynamic> teamData, String teamType) {
    // Lista de posibles ubicaciones donde pueden estar las runs
    final possibleKeys = [
      'runs',           // Ubicación más común
      'score',          // Algunas veces está aquí
      'total_runs',     // Alternativa
      'final_score',    // Para juegos terminados
    ];
    
    for (String key in possibleKeys) {
      if (teamData.containsKey(key)) {
        final value = teamData[key];
        
        // Si es un número directo
        if (value is int) {
          debugPrint('🎯 [$teamType] Runs encontradas en "$key": $value');
          return value;
        }
        
        // Si es string que puede convertirse a número
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            debugPrint('🎯 [$teamType] Runs parseadas de string "$key": $parsed');
            return parsed;
          }
        }
        
        // Si es un objeto anidado, buscar runs dentro
        if (value is Map<String, dynamic>) {
          for (String subKey in ['runs', 'total', 'score']) {
            if (value.containsKey(subKey)) {
              final subValue = value[subKey];
              if (subValue is int) {
                debugPrint('🎯 [$teamType] Runs encontradas en "$key.$subKey": $subValue');
                return subValue;
              }
              if (subValue is String) {
                final parsed = int.tryParse(subValue);
                if (parsed != null) {
                  debugPrint('🎯 [$teamType] Runs parseadas de "$key.$subKey": $parsed');
                  return parsed;
                }
              }
            }
          }
        }
      }
    }
    
    debugPrint('❌ [$teamType] No se encontraron runs en ninguna ubicación');
    debugPrint('🔍 [$teamType] Keys disponibles: ${teamData.keys.toList()}');
    
    return null;
  }

  /// Obtener partidos de ayer para testing
  static Future<List<MLBGame>> getYesterdayGames() async {
    try {
      await _waitForRateLimit();
      
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateString = '${yesterday.year}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.day.toString().padLeft(2, '0')}';
      
      debugPrint('🔗 Obteniendo partidos de ayer: $dateString');
      
      final boxscoreUrl = '$_baseUrl/games/$dateString/boxscore.json?api_key=$_apiKey';
      
      final response = await http.get(
        Uri.parse(boxscoreUrl),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('📡 Respuesta API ayer: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = _parseBoxscoreResponse(data);
        // También ordenar los juegos de ayer por hora
        return _sortGamesByScheduledTime(games);
      } else {
        debugPrint('❌ Error API ayer: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo juegos de ayer: $e');
      return [];
    }
  }

  /// 🎯 NUEVA FUNCIÓN: Ordenar juegos por hora programada
  static List<MLBGame> _sortGamesByScheduledTime(List<MLBGame> games) {
    if (games.isEmpty) return games;

    try {
      // Crear lista con información de ordenamiento
      final gamesWithTime = games.map((game) {
        DateTime? scheduledTime;
        try {
          scheduledTime = DateTime.parse(game.scheduled);
        } catch (e) {
          // Si no se puede parsear, usar hora por defecto para que aparezca al final
          scheduledTime = DateTime.now().add(const Duration(hours: 24));
          debugPrint('⚠️ No se pudo parsear hora para juego ${game.id}: ${game.scheduled}');
        }
        return {'game': game, 'time': scheduledTime};
      }).toList();

      // Ordenar por hora
      gamesWithTime.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeA.compareTo(timeB);
      });

      // Extraer solo los juegos ordenados
      final sortedGames = gamesWithTime.map((item) => item['game'] as MLBGame).toList();

      // Debug: Mostrar orden final
      debugPrint('📅 Orden final de juegos:');
      for (int i = 0; i < sortedGames.length; i++) {
        final game = sortedGames[i];
        debugPrint('  ${i + 1}. ${game.formattedTime} - ${game.awayTeam.abbreviation} @ ${game.homeTeam.abbreviation}');
      }

      return sortedGames;
    } catch (e) {
      debugPrint('❌ Error ordenando juegos: $e');
      // Si hay error en el ordenamiento, devolver lista original
      return games;
    }
  }

  /// Fallback: obtener solo schedule si boxscore falla
  static Future<List<MLBGame>> _getScheduleOnly(String dateString) async {
    try {
      await _waitForRateLimit();
      
      final scheduleUrl = '$_baseUrl/games/$dateString/schedule.json?api_key=$_apiKey';
      
      final response = await http.get(
        Uri.parse(scheduleUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = _parseScheduleResponse(data);
        // También ordenar los juegos del schedule por hora
        return _sortGamesByScheduledTime(games);
      } else {
        debugPrint('❌ Error schedule API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error en schedule fallback: $e');
      return [];
    }
  }

  /// Parsear respuesta de schedule (sin marcadores)
  static List<MLBGame> _parseScheduleResponse(Map<String, dynamic> data) {
    final games = <MLBGame>[];
    
    try {
      List<dynamic> gamesData = [];
      
      if (data['games'] != null) {
        gamesData = data['games'] as List<dynamic>;
      } else if (data['league'] != null && data['league']['games'] != null) {
        gamesData = data['league']['games'] as List<dynamic>;
      }
      
      debugPrint('📅 Parseando ${gamesData.length} juegos del schedule');

      for (var gameData in gamesData) {
        try {
          // Usar constructor manual en lugar de fromJson para mayor control
          final game = _parseGameFromBoxscore(gameData as Map<String, dynamic>);
          games.add(game);
        } catch (e) {
          debugPrint('❌ Error parseando juego del schedule: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error parseando respuesta schedule: $e');
    }

    return games;
  }

  /// Control de rate limiting
  static Future<void> _waitForRateLimit() async {
    if (_lastCall != null) {
      final elapsed = DateTime.now().difference(_lastCall!);
      if (elapsed < _minInterval) {
        final waitTime = _minInterval - elapsed;
        debugPrint('⏳ Esperando ${waitTime.inMilliseconds}ms para rate limiting');
        await Future.delayed(waitTime);
      }
    }
    _lastCall = DateTime.now();
  }

  /// Test de conexión simple
  static Future<bool> testConnection() async {
    try {
      await _waitForRateLimit();
      
      final testUrl = '$_baseUrl/league/hierarchy.json?api_key=$_apiKey';
      final response = await http.get(Uri.parse(testUrl));
      
      final isConnected = response.statusCode == 200;
      debugPrint(isConnected ? '✅ Test de conexión exitoso' : '❌ Test de conexión falló: ${response.statusCode}');
      
      return isConnected;
    } catch (e) {
      debugPrint('❌ Error en test de conexión: $e');
      return false;
    }
  }

  /// Método de debug: Obtener respuesta RAW de la API
  static Future<String> getDebugApiResponse() async {
    try {
      await _waitForRateLimit();
      
      final today = DateTime.now();
      final dateString = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
      final boxscoreUrl = '$_baseUrl/games/$dateString/boxscore.json?api_key=$_apiKey';
      
      final response = await http.get(Uri.parse(boxscoreUrl));
      
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Filtros de juegos (mantienen el orden por hora)
  static List<MLBGame> getLiveGames(List<MLBGame> games) {
    // Filtrar juegos en vivo manteniendo el orden original
    return games.where((game) => game.isLive || game.status == 'inprogress').toList();
  }

  static List<MLBGame> getFinishedGames(List<MLBGame> games) {
    // Filtrar juegos terminados manteniendo el orden original
    return games.where((game) => game.status == 'closed').toList();
  }

  static List<MLBGame> getScheduledGames(List<MLBGame> games) {
    // Filtrar juegos programados manteniendo el orden original
    return games.where((game) => game.status == 'scheduled').toList();
  }

  /// 🎯 NUEVA FUNCIÓN: Filtros con reordenamiento específico (opcional)
  static List<MLBGame> getLiveGamesSorted(List<MLBGame> games) {
    final liveGames = games.where((game) => game.isLive || game.status == 'inprogress').toList();
    return _sortGamesByScheduledTime(liveGames);
  }

  static List<MLBGame> getFinishedGamesSorted(List<MLBGame> games) {
    final finishedGames = games.where((game) => game.status == 'closed').toList();
    return _sortGamesByScheduledTime(finishedGames);
  }

  static List<MLBGame> getScheduledGamesSorted(List<MLBGame> games) {
    final scheduledGames = games.where((game) => game.status == 'scheduled').toList();
    return _sortGamesByScheduledTime(scheduledGames);
  }

  /// Información del servicio
  static Map<String, dynamic> getServiceInfo() {
    return {
      'service': 'SimpleMLBService',
      'api_configured': _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE',
      'api_key_preview': _apiKey.length > 10 ? '${_apiKey.substring(0, 8)}...' : 'No configurada',
      'base_url': _baseUrl,
      'last_call': _lastCall?.toIso8601String(),
      'min_interval_seconds': _minInterval.inSeconds,
    };
  }
}