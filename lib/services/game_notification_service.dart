// lib/services/game_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mlb_game.dart';
import 'package:flutter/foundation.dart';

class GameNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Agregar un juego a las notificaciones del usuario
  Future<bool> addGameNotification(MLBGame game) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gameNotifications')
          .doc(game.id)
          .set(game.toFirestore());

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

      final doc =
          await _firestore
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

      final querySnapshot =
          await _firestore
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
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('gameNotifications')
              .where('scheduled', isLessThan: yesterday.toIso8601String())
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

  // Simular envío de notificación cuando un juego empieza
  Future<void> checkAndSendGameStartNotifications(List<MLBGame> games) async {
    try {
      final userNotifications = await getUserNotificationGames();

      for (var game in games) {
        if (userNotifications.contains(game.id) && game.isLive) {
          await _sendNotification(game);
        }
      }
    } catch (e) {
      debugPrint('❌ Error verificando notificaciones de juegos: $e');
    }
  }

  Future<void> _sendNotification(MLBGame game) async {
    // Aquí implementarías la lógica real de notificaciones push
    // Por ahora solo guardamos un log en Firestore
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'gameId': game.id,
        'title': '¡Juego en vivo!',
        'message':
            '${game.awayTeam.fullName} vs ${game.homeTeam.fullName} ha comenzado',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'game_start',
      });

      debugPrint('📱 Notificación enviada para el juego: ${game.id}');
    } catch (e) {
      debugPrint('❌ Error enviando notificación: $e');
    }
  }
}
