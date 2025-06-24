// lib/services/advanced_cache_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mlb_game.dart';
import 'package:flutter/foundation.dart';

class AdvancedCacheManager {
  static const String _userCacheCollection = 'user_cache';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache en memoria para acceso rápido
  static final Map<String, List<MLBGame>> _memoryCache = {};
  static final Map<String, DateTime> _memoryCacheTimestamps = {};
  static const Duration _memoryCacheExpiry = Duration(minutes: 3);

  // Métodos para cache en memoria
  bool _isMemoryCacheValid(String key) {
    if (!_memoryCache.containsKey(key) || !_memoryCacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final age = DateTime.now().difference(_memoryCacheTimestamps[key]!);
    return age < _memoryCacheExpiry;
  }

  void _setMemoryCache(String key, List<MLBGame> games) {
    _memoryCache[key] = games;
    _memoryCacheTimestamps[key] = DateTime.now();
    debugPrint('💾 Cache en memoria actualizado: $key (${games.length} juegos)');
  }

  List<MLBGame>? _getMemoryCache(String key) {
    if (_isMemoryCacheValid(key)) {
      debugPrint('⚡ Cache en memoria válido: $key');
      return _memoryCache[key];
    }
    return null;
  }

  // Métodos para cache en Firestore
  Future<void> cacheGamesToFirestore(String dateKey, List<MLBGame> games) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final gameData = games.map((game) => {
        'id': game.id,
        'status': game.status,
        'scheduled': game.scheduled,
        'homeTeam': {
          'id': game.homeTeam.id,
          'name': game.homeTeam.name,
          'market': game.homeTeam.market,
          'abbreviation': game.homeTeam.abbreviation,
        },
        'awayTeam': {
          'id': game.awayTeam.id,
          'name': game.awayTeam.name,
          'market': game.awayTeam.market,
          'abbreviation': game.awayTeam.abbreviation,
        },
        'score': game.score != null ? {
          'homeScore': game.score!.homeScore,
          'awayScore': game.score!.awayScore,
        } : null,
        'inning': game.inning,
        'inningHalf': game.inningHalf,
        'venue': {
          'id': game.venue.id,
          'name': game.venue.name,
          'city': game.venue.city,
          'state': game.venue.state,
        },
        'isLive': game.isLive,
        'statusDetail': game.statusDetail,
      }).toList();

      await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .doc(dateKey)
          .set({
        'games': gameData,
        'cached_at': FieldValue.serverTimestamp(),
        'date': dateKey,
      });

      // También actualizar cache en memoria
      _setMemoryCache(dateKey, games);

      debugPrint('✅ ${games.length} juegos guardados en Firestore cache: $dateKey');
    } catch (e) {
      debugPrint('❌ Error guardando cache en Firestore: $e');
    }
  }

  Future<List<MLBGame>?> getCachedGamesFromFirestore(String dateKey) async {
    try {
      // Primero verificar cache en memoria
      final memoryGames = _getMemoryCache(dateKey);
      if (memoryGames != null) {
        return memoryGames;
      }

      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .doc(dateKey)
          .get();

      if (!doc.exists) {
        debugPrint('📭 No hay cache en Firestore para: $dateKey');
        return null;
      }

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp?)?.toDate();
      
      if (cachedAt == null) {
        debugPrint('⚠️ Cache sin timestamp válido para: $dateKey');
        return null;
      }

      // Verificar si el cache está expirado
      final cacheAge = DateTime.now().difference(cachedAt);
      const maxAge = Duration(hours: 1); // Cache válido por 1 hora para datos históricos
      
      if (cacheAge > maxAge) {
        debugPrint('⌛ Cache expirado para: $dateKey (${cacheAge.inMinutes} minutos)');
        // Eliminar cache expirado
        await doc.reference.delete();
        return null;
      }

      final gamesData = data['games'] as List<dynamic>;
      final games = gamesData.map((gameData) {
        final gameMap = Map<String, dynamic>.from(gameData);
        return MLBGame.fromJson(gameMap);
      }).toList();

      // Actualizar cache en memoria
      _setMemoryCache(dateKey, games);

      debugPrint('📦 ${games.length} juegos recuperados del cache Firestore: $dateKey');
      return games;
    } catch (e) {
      debugPrint('❌ Error recuperando cache de Firestore: $e');
      return null;
    }
  }

  Future<bool> isCacheValid(String dateKey) async {
    try {
      // Verificar cache en memoria primero
      if (_isMemoryCacheValid(dateKey)) {
        return true;
      }

      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .doc(dateKey)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp?)?.toDate();
      
      if (cachedAt == null) return false;

      final cacheAge = DateTime.now().difference(cachedAt);
      
      // Para el día actual, cache válido por 5 minutos
      // Para días pasados, cache válido por 1 hora
      final today = DateTime.now();
      final cacheDate = DateTime.tryParse(dateKey.replaceAll('-', '/'));
      final isToday = cacheDate != null && 
                     cacheDate.year == today.year && 
                     cacheDate.month == today.month && 
                     cacheDate.day == today.day;

      final maxAge = isToday ? const Duration(minutes: 5) : const Duration(hours: 1);
      
      return cacheAge <= maxAge;
    } catch (e) {
      debugPrint('❌ Error verificando validez del cache: $e');
      return false;
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String getTodayDateKey() {
    return _getDateKey(DateTime.now());
  }

  // Limpiar cache antiguo (ejecutar periódicamente)
  Future<void> cleanOldCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final oldCaches = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .where('cached_at', isLessThan: cutoffTimestamp)
          .get();

      int deletedCount = 0;
      for (var doc in oldCaches.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      // Limpiar cache en memoria
      _memoryCache.clear();
      _memoryCacheTimestamps.clear();

      debugPrint('🗑️ $deletedCount caches antiguos eliminados');
    } catch (e) {
      debugPrint('❌ Error limpiando cache antiguo: $e');
    }
  }

  // Cache inteligente para juegos específicos
  Future<void> cacheSpecificGame(MLBGame game) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('individual_games')
          .doc(game.id)
          .set({
        'game_data': {
          'id': game.id,
          'status': game.status,
          'scheduled': game.scheduled,
          'homeTeam': {
            'id': game.homeTeam.id,
            'name': game.homeTeam.name,
            'market': game.homeTeam.market,
            'abbreviation': game.homeTeam.abbreviation,
          },
          'awayTeam': {
            'id': game.awayTeam.id,
            'name': game.awayTeam.name,
            'market': game.awayTeam.market,
            'abbreviation': game.awayTeam.abbreviation,
          },
          'score': game.score != null ? {
            'homeScore': game.score!.homeScore,
            'awayScore': game.score!.awayScore,
          } : null,
          'inning': game.inning,
          'inningHalf': game.inningHalf,
          'venue': {
            'id': game.venue.id,
            'name': game.venue.name,
            'city': game.venue.city,
            'state': game.venue.state,
          },
          'isLive': game.isLive,
          'statusDetail': game.statusDetail,
        },
        'cached_at': FieldValue.serverTimestamp(),
        'last_score_update': game.score != null ? FieldValue.serverTimestamp() : null,
      });

      debugPrint('✅ Juego individual cacheado: ${game.id}');
    } catch (e) {
      debugPrint('❌ Error cacheando juego individual: $e');
    }
  }

  Future<MLBGame?> getCachedSpecificGame(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('individual_games')
          .doc(gameId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp?)?.toDate();
      
      if (cachedAt == null) return null;

      // Cache de juegos individuales válido por 2 minutos
      final cacheAge = DateTime.now().difference(cachedAt);
      if (cacheAge > const Duration(minutes: 2)) {
        await doc.reference.delete();
        return null;
      }

      final gameData = data['game_data'] as Map<String, dynamic>;
      return MLBGame.fromJson(gameData);
    } catch (e) {
      debugPrint('❌ Error recuperando juego cacheado: $e');
      return null;
    }
  }

  // Estadísticas del cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final dailyCaches = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .get();

      final individualCaches = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('individual_games')
          .get();

      return {
        'daily_caches': dailyCaches.docs.length,
        'individual_game_caches': individualCaches.docs.length,
        'memory_cache_entries': _memoryCache.length,
        'total_cached_games': dailyCaches.docs.fold<int>(0, (total, doc) {
          final data = doc.data();
          final games = data['games'] as List<dynamic>?;
          return total + (games?.length ?? 0);
        }),
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas del cache: $e');
      return {};
    }
  }

  // Limpiar todo el cache
  Future<void> clearAllCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Limpiar cache en memoria
      _memoryCache.clear();
      _memoryCacheTimestamps.clear();

      // Limpiar cache diario
      final dailyCaches = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .get();

      for (var doc in dailyCaches.docs) {
        await doc.reference.delete();
      }

      // Limpiar cache individual
      final individualCaches = await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('individual_games')
          .get();

      for (var doc in individualCaches.docs) {
        await doc.reference.delete();
      }

      debugPrint('🗑️ Todo el cache ha sido limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando todo el cache: $e');
    }
  }

  // Optimización: Precarga de cache para días futuros
  Future<void> preloadUpcomingDates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final upcoming = [
        _getDateKey(today.add(const Duration(days: 1))),
        _getDateKey(today.add(const Duration(days: 2))),
      ];

      for (String dateKey in upcoming) {
        final isValid = await isCacheValid(dateKey);
        if (!isValid) {
          debugPrint('📅 Marcando $dateKey para precarga');
          // Aquí podrías implementar una cola de precarga
        }
      }
    } catch (e) {
      debugPrint('❌ Error en precarga: $e');
    }
  }

  // Método para invalidar cache específico
  Future<void> invalidateCache(String dateKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remover de memoria
      _memoryCache.remove(dateKey);
      _memoryCacheTimestamps.remove(dateKey);

      // Remover de Firestore
      await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('daily_games')
          .doc(dateKey)
          .delete();

      debugPrint('❌ Cache invalidado para: $dateKey');
    } catch (e) {
      debugPrint('❌ Error invalidando cache: $e');
    }
  }

  // Método para invalidar juego específico
  Future<void> invalidateSpecificGame(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remover de Firestore
      await _firestore
          .collection(_userCacheCollection)
          .doc(user.uid)
          .collection('individual_games')
          .doc(gameId)
          .delete();

      debugPrint('❌ Cache de juego específico invalidado: $gameId');
    } catch (e) {
      debugPrint('❌ Error invalidando cache de juego específico: $e');
    }
  }

  // Método para obtener información detallada del cache
  Map<String, dynamic> getDetailedCacheInfo() {
    try {
      return {
        'memory_cache': {
          'entries': _memoryCache.length,
          'keys': _memoryCache.keys.toList(),
          'total_games': _memoryCache.values.fold<int>(0, (total, games) => total + games.length),
        },
        'timestamps': _memoryCacheTimestamps.map((key, value) => MapEntry(
          key, 
          '${DateTime.now().difference(value).inMinutes} min ago'
        )),
        'cache_active': _memoryCache.isNotEmpty,
        'cache_size': _memoryCache.length,
        'cache_age': _memoryCacheTimestamps.isNotEmpty 
          ? DateTime.now().difference(_memoryCacheTimestamps.values.first).inMinutes
          : null,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo info detallada del cache: $e');
      return {
        'memory_cache': {'entries': 0, 'keys': [], 'total_games': 0},
        'timestamps': {},
        'cache_active': false,
        'cache_size': 0,
        'cache_age': null,
      };
    }
  }
}