// lib/services/game_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/simple_mlb_models.dart'; // ✅ IMPORT CORREGIDO
import 'package:flutter/foundation.dart';

class GameNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Agregar un juego a las notificaciones del usuario
  Future<bool> addGameNotification(MLBGame game) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Crear data para Firestore usando el método toFirestore del modelo
      final gameData = {
        'gameId': game.id,
        'homeTeam': game.homeTeam.name,
        'awayTeam': game.awayTeam.name,
        'scheduled': game.scheduled,
        'status': game.status,
        'homeTeamAbbr': game.homeTeam.abbreviation,
        'awayTeamAbbr': game.awayTeam.abbreviation,
        'venue': game.venue.name,
        'isNotified': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .doc(game.id)
          .set(gameData);

      debugPrint('✅ Notificación agregada para el juego: ${game.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error agregando notificación: $e');
      return false;
    }
  }

  // Remover un juego de las notificaciones del usuario
  Future<bool> removeGameNotification(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .doc(gameId)
          .delete();

      debugPrint('✅ Notificación removida para el juego: $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removiendo notificación: $e');
      return false;
    }
  }

  // Verificar si un juego tiene notificación activada
  Future<bool> isGameNotificationActive(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .doc(gameId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error verificando notificación: $e');
      return false;
    }
  }

  // Obtener todos los juegos con notificación del usuario
  Future<List<String>> getUserNotificationGames() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo notificaciones del usuario: $e');
      return [];
    }
  }

  // Stream para escuchar cambios en las notificaciones del usuario
  Stream<List<String>> getUserNotificationGamesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gameNotifications')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Limpiar notificaciones de juegos pasados (ejecutar diariamente)
  Future<void> cleanExpiredNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = yesterday.toIso8601String();
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .where('scheduled', isLessThan: yesterdayString)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint(
        '✅ ${querySnapshot.docs.length} notificaciones expiradas eliminadas',
      );
    } catch (e) {
      debugPrint('❌ Error limpiando notificaciones expiradas: $e');
    }
  }

  // Obtener información detallada de las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getUserNotificationDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .orderBy('scheduled', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'gameId': doc.id,
          'homeTeam': data['homeTeam'] ?? 'Unknown',
          'awayTeam': data['awayTeam'] ?? 'Unknown',
          'scheduled': data['scheduled'],
          'status': data['status'] ?? 'unknown',
          'venue': data['venue'] ?? 'Unknown',
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo detalles de notificaciones: $e');
      return [];
    }
  }

  // Estadísticas de notificaciones del usuario
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'total': 0,
          'active': 0,
          'scheduled': 0,
          'live': 0,
          'finished': 0,
        };
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .get();

      int total = querySnapshot.docs.length;
      int scheduled = 0;
      int live = 0;
      int finished = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'unknown';
        
        switch (status) {
          case 'scheduled':
            scheduled++;
            break;
          case 'inprogress':
            live++;
            break;
          case 'closed':
            finished++;
            break;
        }
      }

      return {
        'total': total,
        'active': total,
        'scheduled': scheduled,
        'live': live,
        'finished': finished,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas de notificaciones: $e');
      return {
        'total': 0,
        'active': 0,
        'scheduled': 0,
        'live': 0,
        'finished': 0,
      };
    }
  }

  // Método para testing - agregar notificación de prueba
  Future<bool> addTestNotification() async {
    try {
      final testGame = MLBGame(
        id: 'test_game_${DateTime.now().millisecondsSinceEpoch}',
        status: 'scheduled',
        scheduled: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        homeTeam: Team(
          id: 'test_home',
          name: 'Test Home Team',
          market: 'Test City',
          abbreviation: 'THT',
        ),
        awayTeam: Team(
          id: 'test_away',
          name: 'Test Away Team', 
          market: 'Test Town',
          abbreviation: 'TAT',
        ),
        venue: Venue(
          id: 'test_venue',
          name: 'Test Stadium',
          city: 'Test City',
          state: 'Test State',
        ),
        isLive: false,
      );

      return await addGameNotification(testGame);
    } catch (e) {
      debugPrint('❌ Error agregando notificación de prueba: $e');
      return false;
    }
  }

  // Limpiar todas las notificaciones del usuario
  Future<bool> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Todas las notificaciones han sido eliminadas');
      return true;
    } catch (e) {
      debugPrint('❌ Error limpiando todas las notificaciones: $e');
      return false;
    }
  }
}