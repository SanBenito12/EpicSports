// lib/services/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/mlb_game.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    try {
      // 1. Solicitar permisos
      await _requestPermissions();
      
      // 2. Configurar notificaciones locales
      await _initializeLocalNotifications();
      
      // 3. Configurar Firebase Messaging
      await _initializeFirebaseMessaging();
      
      // 4. Obtener token FCM
      await _getFCMToken();
      
      debugPrint('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  // Solicitar permisos de notificación
  static Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('🔔 Permisos de notificación: ${settings.authorizationStatus}');
  }

  // Configurar notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    await _createNotificationChannel();
  }

  // Crear canal de notificaciones Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'mlb_games_channel',
      'Partidos MLB',
      description: 'Notificaciones de partidos de béisbol',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Configurar Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Manejar mensaje cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando se toca una notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app se abrió desde una notificación
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Obtener token FCM
  static Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        debugPrint('📱 FCM Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM token: $e');
    }
  }

  // Guardar token en Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Token FCM guardado en Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error guardando token: $e');
    }
  }

  // Manejar mensaje en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Mensaje en primer plano: ${message.notification?.title}');
    
    // Mostrar notificación local
    _showLocalNotification(
      title: message.notification?.title ?? 'Partido MLB',
      body: message.notification?.body ?? 'Un partido está por comenzar',
      payload: message.data['gameId'],
    );
  }

  // Manejar tap en notificación
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notificación tocada: ${message.data}');
    // Aquí puedes navegar a la pantalla del juego específico
  }

  // Callback cuando se toca notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificación local tocada: ${response.payload}');
    // Aquí puedes navegar a la pantalla del juego específico
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mlb_games_channel',
      'Partidos MLB',
      channelDescription: 'Notificaciones de partidos de béisbol',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // 🧪 NOTIFICACIÓN DE PRUEBA
  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: '🏟️ ¡Bienvenido a EpicSports!',
      body: 'Las notificaciones están funcionando correctamente. ¡Disfruta los partidos!',
      payload: 'test_notification',
    );
    debugPrint('🧪 Notificación de prueba enviada');
  }

  // Notificación cuando empieza un partido
  static Future<void> notifyGameStarting(MLBGame game) async {
    await _showLocalNotification(
      title: '🔴 ¡Partido en vivo!',
      body: '${game.awayTeam.name} vs ${game.homeTeam.name} ha comenzado',
      payload: game.id,
    );
    
    // También guardar en Firestore para historial
    await _saveNotificationHistory(game, 'game_started');
  }

  // Notificación para recordatorio de partido próximo
  static Future<void> notifyGameStartingSoon(MLBGame game, int minutesUntilStart) async {
    await _showLocalNotification(
      title: '⏰ Partido próximo',
      body: '${game.awayTeam.name} vs ${game.homeTeam.name} empieza en $minutesUntilStart minutos',
      payload: game.id,
    );
    
    await _saveNotificationHistory(game, 'game_reminder');
  }

  // Notificación para cambio de marcador
  static Future<void> notifyScoreUpdate(MLBGame game) async {
    if (game.score != null) {
      await _showLocalNotification(
        title: '📊 Actualización de marcador',
        body: '${game.awayTeam.abbreviation} ${game.score!.awayScore} - ${game.score!.homeScore} ${game.homeTeam.abbreviation}',
        payload: game.id,
      );
    }
  }

  // Guardar historial de notificaciones
  static Future<void> _saveNotificationHistory(MLBGame game, String type) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('notification_history').add({
          'userId': user.uid,
          'gameId': game.id,
          'type': type,
          'title': '${game.awayTeam.name} vs ${game.homeTeam.name}',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error guardando historial de notificación: $e');
    }
  }

  // Verificar si un juego debe enviar notificación
  static Future<bool> shouldNotifyForGame(String gameId) async {
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
      debugPrint('❌ Error verificando notificación para juego: $e');
      return false;
    }
  }

  // Chequear partidos que van a empezar (llamar periódicamente)
  static Future<void> checkUpcomingGames(List<MLBGame> games) async {
    final now = DateTime.now();
    
    for (final game in games) {
      if (await shouldNotifyForGame(game.id)) {
        final gameTime = game.scheduledTime;
        if (gameTime != null) {
          final minutesUntilStart = gameTime.difference(now).inMinutes;
          
          // Notificar 15 minutos antes
          if (minutesUntilStart <= 15 && minutesUntilStart > 10) {
            await notifyGameStartingSoon(game, minutesUntilStart);
          }
          
          // Notificar cuando empiece (con tolerancia de 5 minutos)
          if (minutesUntilStart <= 5 && minutesUntilStart >= -5 && game.isLive) {
            await notifyGameStarting(game);
          }
        }
      }
    }
  }

  // Obtener estado de permisos
  static Future<NotificationSettings> getPermissionStatus() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    final settings = await getPermissionStatus();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Método para testing - simular que empezó un partido
  static Future<void> simulateGameStart() async {
    // Crear un juego de prueba
    final testGame = MLBGame(
      id: 'test_game_${DateTime.now().millisecondsSinceEpoch}',
      status: 'inprogress',
      scheduled: DateTime.now().toIso8601String(),
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
      isLive: true,
    );

    await notifyGameStarting(testGame);
  }
}