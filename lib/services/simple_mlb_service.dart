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
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseBoxscoreResponse(data);
      } else {
        debugPrint('❌ Error API: ${response.statusCode} - ${response.body}');
        
        // Si boxscore falla, intentar con schedule
        return await _getScheduleOnly(dateString);
      }
    } catch (e) {
      debugPrint('❌ Error en getTodaysGames: $e');
      return [];
    }
  }

  /// Parsear respuesta de boxscore (incluye marcadores)
  static List<MLBGame> _parseBoxscoreResponse(Map<String, dynamic> data) {
    final games = <MLBGame>[];
    
    try {
      // DEBUG: Imprimir estructura completa
      debugPrint('📡 Estructura de respuesta de API:');
      debugPrint('📡 Keys principales: ${data.keys.toList()}');
      
      // Estructura de respuesta de boxscore
      List<dynamic> gamesData = [];
      
      if (data['league'] != null && data['league']['games'] != null) {
        gamesData = data['league']['games'];
        debugPrint('📊 Usando estructura: data[league][games] con ${gamesData.length} juegos');
      } else if (data['games'] != null) {
        gamesData = data['games'];
        debugPrint('📊 Usando estructura: data[games] con ${gamesData.length} juegos');
      } else {
        // Imprimir toda la estructura para entender el formato
        debugPrint('📊 Estructura desconocida, keys disponibles: ${data.keys.toList()}');
        if (data.isNotEmpty) {
          debugPrint('📊 Primer nivel de datos: ${data.toString().substring(0, data.toString().length > 500 ? 500 : data.toString().length)}...');
        }
      }

      debugPrint('📊 Parseando ${gamesData.length} juegos del boxscore');

      for (int i = 0; i < gamesData.length; i++) {
        try {
          debugPrint('🎮 Parseando juego ${i + 1}/${gamesData.length}');
          final game = _parseGameFromBoxscore(gamesData[i]);
          games.add(game);
        } catch (e) {
          debugPrint('❌ Error parseando juego ${i + 1}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error parseando respuesta boxscore: $e');
    }

    debugPrint('✅ ${games.length} juegos parseados correctamente');
    return games;
  }

  /// Parsear un juego individual del boxscore
  static MLBGame _parseGameFromBoxscore(Map<String, dynamic> gameData) {
    // DEBUG: Imprimir estructura del juego
    debugPrint('🔍 Parseando juego: ${gameData.keys.toList()}');
    
    // Información básica del juego
    final gameId = gameData['id']?.toString() ?? '';
    final status = gameData['status']?.toString() ?? 'scheduled';
    final scheduled = gameData['scheduled']?.toString() ?? DateTime.now().toIso8601String();
    
    debugPrint('📋 ID: $gameId, Estado: $status, Hora: $scheduled');
    
    // Equipos - verificar diferentes estructuras posibles
    Team homeTeam;
    Team awayTeam;
    
    if (gameData['home'] != null) {
      final homeData = gameData['home'] as Map<String, dynamic>;
      debugPrint('🏠 Home team data: ${homeData.keys.toList()}');
      homeTeam = Team.fromJson(homeData);
    } else {
      homeTeam = Team(id: '', name: 'Home Team', market: '', abbreviation: 'HOME');
    }
    
    if (gameData['away'] != null) {
      final awayData = gameData['away'] as Map<String, dynamic>;
      debugPrint('✈️ Away team data: ${awayData.keys.toList()}');
      awayTeam = Team.fromJson(awayData);
    } else {
      awayTeam = Team(id: '', name: 'Away Team', market: '', abbreviation: 'AWAY');
    }
    
    // Venue - verificar diferentes estructuras posibles
    Venue venue;
    if (gameData['venue'] != null) {
      final venueData = gameData['venue'] as Map<String, dynamic>;
      debugPrint('🏟️ Venue data: ${venueData.keys.toList()}');
      venue = Venue.fromJson(venueData);
    } else {
      venue = Venue(id: '', name: 'Stadium', city: 'City', state: 'State');
    }
    
    // Marcadores (la parte importante)
    GameScore? score;
    if (gameData['home'] != null && gameData['away'] != null) {
      final home = gameData['home'] as Map<String, dynamic>;
      final away = gameData['away'] as Map<String, dynamic>;
      
      // Buscar runs en diferentes ubicaciones posibles
      final homeRuns = home['runs'] ?? 
                      home['score']?['runs'] ?? 
                      home['scoring']?['runs'] ??
                      home['total']?['runs'];
      final awayRuns = away['runs'] ?? 
                      away['score']?['runs'] ?? 
                      away['scoring']?['runs'] ??
                      away['total']?['runs'];
      
      debugPrint('🎯 Intentando extraer marcadores: home=$homeRuns, away=$awayRuns');
      
      if (homeRuns != null && awayRuns != null) {
        score = GameScore(
          homeScore: homeRuns is int ? homeRuns : int.tryParse(homeRuns.toString()) ?? 0,
          awayScore: awayRuns is int ? awayRuns : int.tryParse(awayRuns.toString()) ?? 0,
        );
        debugPrint('📊 Marcador encontrado: ${awayTeam.abbreviation} $awayRuns - $homeRuns ${homeTeam.abbreviation}');
      } else {
        debugPrint('❌ No se encontraron marcadores en la estructura de datos');
      }
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
      score: score,
      inning: inning,
      inningHalf: inningHalf,
      venue: venue,
      isLive: isLive,
    );
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
        return _parseScheduleResponse(data);
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
      final gamesData = data['games'] as List<dynamic>? ?? [];
      
      debugPrint('📅 Parseando ${gamesData.length} juegos del schedule');

      for (var gameData in gamesData) {
        try {
          final game = MLBGame.fromJson(gameData);
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

  /// Filtros de juegos
  static List<MLBGame> getLiveGames(List<MLBGame> games) {
    return games.where((game) => game.isLive || game.status == 'inprogress').toList();
  }

  static List<MLBGame> getFinishedGames(List<MLBGame> games) {
    return games.where((game) => game.status == 'closed').toList();
  }

  static List<MLBGame> getScheduledGames(List<MLBGame> games) {
    return games.where((game) => game.status == 'scheduled').toList();
  }

  /// Información del servicio
  static Map<String, dynamic> getServiceInfo() {
    return {
      'service': 'SimpleMLBService',
      'api_configured': _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE',
      'base_url': _baseUrl,
      'last_call': _lastCall?.toIso8601String(),
      'min_interval_seconds': _minInterval.inSeconds,
    };
  }
}