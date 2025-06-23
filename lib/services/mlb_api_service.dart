// lib/services/mlb_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mlb_game.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

class MLBApiService {
  static const String _apiKey = ApiConfig.sportradarApiKey;
  static const String _baseUrl = ApiConfig.mlbApiBaseUrl;

  // Límite de 1 llamada por segundo en el trial
  static DateTime? _lastApiCall;

  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed.inMilliseconds < 1000) {
        await Future.delayed(
          Duration(milliseconds: 1000 - elapsed.inMilliseconds),
        );
      }
    }
    _lastApiCall = DateTime.now();
  }

  Future<List<MLBGame>> getTodaysGames() async {
    try {
      await _waitForRateLimit();

      final now = DateTime.now();
      final dateString =
          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

      final url = '$_baseUrl/games/$dateString/schedule.json?api_key=$_apiKey';

      debugPrint('🔗 Consultando API: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = <MLBGame>[];

        debugPrint('📊 Estructura de respuesta API: ${data.keys.toList()}');

        if (data['games'] != null) {
          for (var gameData in data['games']) {
            try {
              debugPrint('🏟️ Parseando juego: ${gameData['id']}');
              
              // Para juegos en vivo o completados, intentar obtener información detallada
              final status = gameData['status'];
              MLBGame game;
              
              if (status == 'inprogress' || status == 'closed') {
                // Intentar obtener detalles del juego para marcadores en vivo
                final detailedGame = await getGameDetails(gameData['id']);
                game = detailedGame ?? MLBGame.fromJson(gameData);
              } else {
                game = MLBGame.fromJson(gameData);
              }
              
              games.add(game);
              debugPrint('✅ Juego agregado: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
              
              if (game.score != null) {
                debugPrint('📊 Marcador: ${game.score!.awayScore} - ${game.score!.homeScore}');
              }
              
            } catch (e) {
              debugPrint('❌ Error parseando juego: $e');
              debugPrint('🔍 Datos del juego problemático: $gameData');
            }
          }
        }

        debugPrint('✅ Total de ${games.length} juegos obtenidos para hoy');
        return games;
      } else if (response.statusCode == 401) {
        throw 'API Key inválida. Verifica tu clave de Sportradar.';
      } else if (response.statusCode == 429) {
        throw 'Límite de llamadas excedido. Intenta de nuevo en un momento.';
      } else {
        debugPrint('❌ Error HTTP: ${response.statusCode}');
        debugPrint('❌ Respuesta: ${response.body}');
        throw 'Error al obtener datos: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Error en getTodaysGames: $e');
      throw 'Error de conexión: $e';
    }
  }

  Future<MLBGame?> getGameDetails(String gameId) async {
    try {
      await _waitForRateLimit();

      final url = '$_baseUrl/games/$gameId/summary.json?api_key=$_apiKey';

      debugPrint('🔗 Obteniendo detalles del juego: $gameId');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📊 Estructura de summary: ${data.keys.toList()}');
        
        // La API de summary puede tener diferentes estructuras
        Map<String, dynamic> gameData;
        
        if (data['game'] != null) {
          gameData = data['game'];
        } else {
          gameData = data;
        }
        
        return MLBGame.fromJson(gameData);
      } else {
        debugPrint('❌ Error obteniendo detalles del juego: ${response.statusCode}');
        debugPrint('❌ Respuesta: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error en getGameDetails: $e');
      return null;
    }
  }

  Future<List<MLBGame>> getLiveGames() async {
    try {
      final allGames = await getTodaysGames();
      return allGames.where((game) => game.isLive).toList();
    } catch (e) {
      debugPrint('❌ Error en getLiveGames: $e');
      return [];
    }
  }

  // Método específico para obtener solo marcadores actualizados
  Future<List<MLBGame>> getUpdatedScores(List<String> gameIds) async {
    final updatedGames = <MLBGame>[];
    
    for (String gameId in gameIds) {
      try {
        final game = await getGameDetails(gameId);
        if (game != null) {
          updatedGames.add(game);
        }
      } catch (e) {
        debugPrint('❌ Error actualizando marcador para $gameId: $e');
      }
    }
    
    return updatedGames;
  }

  // Método para obtener juegos con polling (cada 30 segundos para juegos en vivo)
  Stream<List<MLBGame>> getGamesStream() async* {
    while (true) {
      try {
        final games = await getTodaysGames();
        yield games;

        // Si hay juegos en vivo, actualizar cada 30 segundos, sino cada 5 minutos
        final hasLiveGames = games.any((game) => game.isLive);
        await Future.delayed(Duration(seconds: hasLiveGames ? 30 : 300));
      } catch (e) {
        debugPrint('❌ Error en stream: $e');
        await Future.delayed(const Duration(minutes: 1));
      }
    }
  }

  // Validar que la API Key esté configurada
  bool isApiKeyConfigured() {
    return ApiConfig.isConfigured;
  }

  // Método para hacer una llamada de prueba a la API
  Future<bool> testApiConnection() async {
    try {
      await _waitForRateLimit();
      
      final url = '$_baseUrl/league/hierarchy.json?api_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      debugPrint('🔗 Test API Connection: ${response.statusCode}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error en test de conexión: $e');
      return false;
    }
  }
}