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

        if (data['games'] != null) {
          for (var gameData in data['games']) {
            try {
              final game = MLBGame.fromJson(gameData);
              games.add(game);
            } catch (e) {
              debugPrint('❌ Error parseando juego: $e');
            }
          }
        }

        debugPrint('✅ ${games.length} juegos obtenidos para hoy');
        return games;
      } else if (response.statusCode == 401) {
        throw 'API Key inválida. Verifica tu clave de Sportradar.';
      } else if (response.statusCode == 429) {
        throw 'Límite de llamadas excedido. Intenta de nuevo en un momento.';
      } else {
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
        return MLBGame.fromJson(data['game'] ?? data);
      } else {
        debugPrint(
          '❌ Error obteniendo detalles del juego: ${response.statusCode}',
        );
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
}
