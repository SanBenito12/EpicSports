// lib/services/sportradar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mlb_game.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

class SportradarService {
  static const String _apiKey = ApiConfig.sportradarApiKey;
  static const String _baseUrl = ApiConfig.mlbApiBaseUrl;
  
  // Control de rate limiting simplificado
  static DateTime? _lastApiCall;
  static const Duration _minimumInterval = Duration(seconds: 2);

  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed < _minimumInterval) {
        await Future.delayed(_minimumInterval - elapsed);
      }
    }
    _lastApiCall = DateTime.now();
  }

  /// Obtener lista de partidos del día (schedule)
  Future<List<MLBGame>> fetchDailySchedule(DateTime date) async {
    try {
      await _waitForRateLimit();
      
      final dateString = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      final url = '$_baseUrl/games/$dateString/schedule.json?api_key=$_apiKey';
      
      debugPrint('🔗 Schedule API: $dateString');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = <MLBGame>[];
        
        if (data['games'] != null) {
          for (var gameData in data['games']) {
            try {
              games.add(MLBGame.fromJson(gameData));
            } catch (e) {
              debugPrint('❌ Error parseando juego del schedule: $e');
            }
          }
        }
        
        debugPrint('✅ Schedule: ${games.length} juegos encontrados');
        return games;
      } else {
        throw 'Error en schedule API: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Error en fetchDailySchedule: $e');
      return [];
    }
  }

  /// Obtener marcadores del día (boxscore)
  Future<Map<String, GameScore>> fetchBoxscores(DateTime date) async {
    try {
      await _waitForRateLimit();
      
      final dateString = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      final url = '$_baseUrl/games/$dateString/boxscore.json?api_key=$_apiKey';
      
      debugPrint('🔗 Boxscore API: $dateString');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final scores = <String, GameScore>{};
        
        if (data['league'] != null && data['league']['games'] != null) {
          for (var gameData in data['league']['games']) {
            try {
              final gameId = gameData['id'];
              final home = gameData['home'];
              final away = gameData['away'];
              
              if (home != null && away != null && 
                  home['runs'] != null && away['runs'] != null) {
                scores[gameId] = GameScore(
                  homeScore: home['runs'],
                  awayScore: away['runs'],
                );
              }
            } catch (e) {
              debugPrint('❌ Error parseando marcador: $e');
            }
          }
        }
        
        debugPrint('✅ Boxscores: ${scores.length} marcadores encontrados');
        return scores;
      } else {
        throw 'Error en boxscore API: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Error en fetchBoxscores: $e');
      return {};
    }
  }

  /// Combinar schedule con boxscores
  List<MLBGame> mergeScheduleWithBoxscores(
    List<MLBGame> schedule, 
    Map<String, GameScore> boxscores,
  ) {
    return schedule.map((game) {
      final score = boxscores[game.id];
      if (score != null) {
        return MLBGame(
          id: game.id,
          status: game.status,
          scheduled: game.scheduled,
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          score: score, // Actualizar marcador
          inning: game.inning,
          inningHalf: game.inningHalf,
          venue: game.venue,
          isLive: game.isLive,
          statusDetail: game.statusDetail,
        );
      }
      return game;
    }).toList();
  }

  /// Método principal: obtener juegos completos del día
  Future<List<MLBGame>> getTodaysGames() async {
    try {
      final today = DateTime.now();
      
      // Paso 1: Obtener schedule
      final schedule = await fetchDailySchedule(today);
      if (schedule.isEmpty) {
        return [];
      }
      
      // Paso 2: Obtener boxscores
      final boxscores = await fetchBoxscores(today);
      
      // Paso 3: Combinar datos
      final games = mergeScheduleWithBoxscores(schedule, boxscores);
      
      debugPrint('✅ Total final: ${games.length} juegos procesados');
      return games;
    } catch (e) {
      debugPrint('❌ Error en getTodaysGames: $e');
      return [];
    }
  }

  /// Filtrar juegos en vivo
  List<MLBGame> getLiveGames(List<MLBGame> games) {
    return games.where((game) => game.status == 'inprogress').toList();
  }

  /// Filtrar juegos terminados
  List<MLBGame> getFinishedGames(List<MLBGame> games) {
    return games.where((game) => game.status == 'closed').toList();
  }

  /// Filtrar juegos programados
  List<MLBGame> getScheduledGames(List<MLBGame> games) {
    return games.where((game) => game.status == 'scheduled').toList();
  }

  /// Test de conexión simple
  Future<bool> testConnection() async {
    try {
      await _waitForRateLimit();
      
      final url = '$_baseUrl/league/hierarchy.json?api_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error en test de conexión: $e');
      return false;
    }
  }

  /// Información del servicio
  Map<String, dynamic> getServiceInfo() {
    return {
      'api_configured': ApiConfig.isConfigured,
      'base_url': _baseUrl,
      'last_call': _lastApiCall?.toIso8601String(),
      'service_active': true,
    };
  }
}