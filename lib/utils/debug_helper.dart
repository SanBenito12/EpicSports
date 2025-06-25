// lib/utils/debug_helper.dart
import 'package:flutter/foundation.dart';

/// 🐛 HELPER PARA DEBUGGING Y ANÁLISIS DE RESPUESTAS API
class DebugHelper {
  /// 📊 ANALIZAR ESTRUCTURA DE RESPUESTA JSON
  static void analyzeApiResponse(Map<String, dynamic> data, {String prefix = ''}) {
    if (!kDebugMode) return; // Solo en modo debug
    
    debugPrint('$prefix📊 ANÁLISIS DE ESTRUCTURA JSON:');
    debugPrint('$prefix└── Keys principales: ${data.keys.toList()}');
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Map<String, dynamic>) {
        debugPrint('$prefix├── $key: Map (${value.length} keys)');
        if (value.isNotEmpty) {
          debugPrint('$prefix│   └── Sub-keys: ${value.keys.toList()}');
        }
      } else if (value is List) {
        debugPrint('$prefix├── $key: List (${value.length} elementos)');
        if (value.isNotEmpty && value.first is Map) {
          final firstItem = value.first as Map<String, dynamic>;
          debugPrint('$prefix│   └── Primer elemento keys: ${firstItem.keys.toList()}');
        }
      } else {
        debugPrint('$prefix├── $key: ${value.runtimeType} = ${value.toString().length > 50 ? '${value.toString().substring(0, 50)}...' : value}');
      }
    }
  }

  /// 🔍 BUSCAR GAMES EN DIFERENTES ESTRUCTURAS
  static List<dynamic> findGamesInResponse(Map<String, dynamic> data) {
    final searchPaths = [
      ['league', 'games'],
      ['games'],
      ['schedules', '0', 'games'],
      ['schedule', 'games'],
      ['data', 'games'],
      ['response', 'games'],
    ];

    for (final path in searchPaths) {
      try {
        dynamic current = data;
        for (final segment in path) {
          if (current is Map<String, dynamic>) {
            current = current[segment];
          } else if (current is List && segment == '0') {
            current = current.isNotEmpty ? current[0] : null;
          } else {
            current = null;
            break;
          }
        }
        
        if (current is List && current.isNotEmpty) {
          debugPrint('✅ Encontrados ${current.length} juegos en: ${path.join(' -> ')}');
          return current;
        }
      } catch (e) {
        debugPrint('❌ Error buscando en ${path.join(' -> ')}: $e');
      }
    }

    debugPrint('❌ No se encontraron juegos en ninguna estructura conocida');
    return [];
  }

  /// 🎮 ANALIZAR ESTRUCTURA DE UN JUEGO INDIVIDUAL
  static void analyzeGameStructure(Map<String, dynamic> gameData, int index) {
    if (!kDebugMode) return;
    
    debugPrint('🎮 JUEGO $index ESTRUCTURA:');
    debugPrint('   ├── Keys: ${gameData.keys.toList()}');
    
    // Analizar equipos
    ['home', 'away'].forEach((teamKey) {
      if (gameData[teamKey] is Map) {
        final team = gameData[teamKey] as Map<String, dynamic>;
        debugPrint('   ├── $teamKey team keys: ${team.keys.toList()}');
        
        // Buscar información específica del equipo
        final teamInfo = {
          'name': team['name'] ?? team['full_name'] ?? team['team_name'],
          'abbr': team['abbr'] ?? team['abbreviation'] ?? team['alias'],
          'market': team['market'] ?? team['city'],
          'runs': team['runs'] ?? team['score']?['runs'],
        };
        debugPrint('   │   └── Info: $teamInfo');
      }
    });
    
    // Analizar venue
    if (gameData['venue'] is Map) {
      final venue = gameData['venue'] as Map<String, dynamic>;
      debugPrint('   ├── venue keys: ${venue.keys.toList()}');
    }
    
    // Analizar marcadores/scoring
    if (gameData['scoring'] is Map) {
      final scoring = gameData['scoring'] as Map<String, dynamic>;
      debugPrint('   ├── scoring keys: ${scoring.keys.toList()}');
    }
    
    // Info básica
    debugPrint('   └── Básico: id=${gameData['id']}, status=${gameData['status']}, scheduled=${gameData['scheduled']}');
  }

  /// 📋 CREAR REPORTE DE DEBUGGING
  static String createDebugReport(Map<String, dynamic> apiResponse, List<dynamic> games) {
    final report = StringBuffer();
    final now = DateTime.now();
    
    report.writeln('🐛 REPORTE DE DEBUGGING MLB API');
    report.writeln('📅 Fecha: ${now.toString()}');
    report.writeln('=' * 50);
    
    // Información de la respuesta
    report.writeln('\n📡 RESPUESTA API:');
    report.writeln('   Keys principales: ${apiResponse.keys.toList()}');
    report.writeln('   Tamaño total: ${apiResponse.toString().length} caracteres');
    
    // Información de juegos encontrados
    report.writeln('\n🎮 JUEGOS ENCONTRADOS:');
    report.writeln('   Total: ${games.length}');
    
    if (games.isNotEmpty) {
      report.writeln('   Primer juego keys: ${(games.first as Map<String, dynamic>).keys.toList()}');
      
      // Análisis por estado
      final statuses = <String, int>{};
      for (final game in games) {
        final status = (game as Map<String, dynamic>)['status']?.toString() ?? 'unknown';
        statuses[status] = (statuses[status] ?? 0) + 1;
      }
      report.writeln('   Estados: $statuses');
    }
    
    // Sugerencias
    report.writeln('\n💡 SUGERENCIAS:');
    if (games.isEmpty) {
      report.writeln('   - Verificar que la API key sea válida');
      report.writeln('   - Comprobar que el endpoint sea correcto');
      report.writeln('   - Revisar la estructura de respuesta arriba');
    } else {
      report.writeln('   - Los juegos se están parseando correctamente');
      report.writeln('   - Verificar que los marcadores se estén extrayendo bien');
    }
    
    return report.toString();
  }

  /// 🧪 GENERAR DATOS DE EJEMPLO PARA TESTING
  static Map<String, dynamic> generateTestApiResponse() {
    return {
      'league': {
        'games': [
          {
            'id': 'test_game_1',
            'status': 'scheduled',
            'scheduled': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
            'home': {
              'id': 'home_1',
              'name': 'Yankees',
              'market': 'New York',
              'abbr': 'NYY',
            },
            'away': {
              'id': 'away_1',
              'name': 'Red Sox',
              'market': 'Boston',
              'abbr': 'BOS',
            },
            'venue': {
              'id': 'venue_1',
              'name': 'Yankee Stadium',
              'city': 'New York',
              'state': 'NY',
            }
          },
          {
            'id': 'test_game_2',
            'status': 'inprogress',
            'scheduled': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
            'inning': '7',
            'home': {
              'id': 'home_2',
              'name': 'Dodgers',
              'market': 'Los Angeles',
              'abbr': 'LAD',
              'runs': 5,
            },
            'away': {
              'id': 'away_2',
              'name': 'Giants',
              'market': 'San Francisco',
              'abbr': 'SF',
              'runs': 3,
            },
            'venue': {
              'id': 'venue_2',
              'name': 'Dodger Stadium',
              'city': 'Los Angeles',
              'state': 'CA',
            }
          }
        ]
      }
    };
  }

  /// 📊 VALIDAR CALIDAD DE DATOS
  static Map<String, dynamic> validateDataQuality(List<dynamic> games) {
    final stats = {
      'total_games': games.length,
      'games_with_teams': 0,
      'games_with_scores': 0,
      'games_with_venues': 0,
      'live_games': 0,
      'scheduled_games': 0,
      'finished_games': 0,
      'missing_data': <String>[],
    };

    for (final game in games) {
      final gameMap = game as Map<String, dynamic>;
      
      // Verificar equipos
      if (gameMap['home'] != null && gameMap['away'] != null) {
        stats['games_with_teams'] = (stats['games_with_teams'] as int) + 1;
      } else {
        (stats['missing_data'] as List<String>).add('${gameMap['id']}: teams');
      }
      
      // Verificar marcadores
      final homeRuns = gameMap['home']?['runs'];
      final awayRuns = gameMap['away']?['runs'];
      if (homeRuns != null && awayRuns != null) {
        stats['games_with_scores'] = (stats['games_with_scores'] as int) + 1;
      }
      
      // Verificar venue
      if (gameMap['venue'] != null) {
        stats['games_with_venues'] = (stats['games_with_venues'] as int) + 1;
      } else {
        (stats['missing_data'] as List<String>).add('${gameMap['id']}: venue');
      }
      
      // Contar por estado
      final status = gameMap['status']?.toString().toLowerCase() ?? '';
      if (status.contains('progress') || status == 'live') {
        stats['live_games'] = (stats['live_games'] as int) + 1;
      } else if (status == 'scheduled') {
        stats['scheduled_games'] = (stats['scheduled_games'] as int) + 1;
      } else if (status == 'closed' || status == 'complete') {
        stats['finished_games'] = (stats['finished_games'] as int) + 1;
      }
    }

    return stats;
  }

  /// 🎯 LOG SIMPLIFICADO PARA DEBUGGING RÁPIDO
  static void quickLog(String message, {String level = 'INFO'}) {
    if (!kDebugMode) return;
    
    final emoji = {
      'INFO': 'ℹ️',
      'SUCCESS': '✅',
      'WARNING': '⚠️',
      'ERROR': '❌',
      'DEBUG': '🐛',
    };
    
    debugPrint('${emoji[level] ?? '📝'} $message');
  }
}