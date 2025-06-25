// lib/services/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/simple_mlb_models.dart'; 
import 'package:flutter/foundation.dart';
import 'dart:async'; // ✅ Agregar import para Timer

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
      // Expandir para mostrar más texto
      styleInformation: BigTextStyleInformation(''),
      // Vibración personalizada
      enableVibration: true,
      playSound: true,
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

  // 🏟️ NOTIFICACIÓN DE BIENVENIDA AUTOMÁTICA
  static Future<void> showTestNotification() async {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    
    await _showLocalNotification(
      title: '⚾ ¡Bienvenido a EpicSports, $userName!',
      body: '🔔 Las notificaciones están activas. Selecciona los partidos que quieres seguir y recibe alertas cuando empiecen.',
      payload: 'welcome_notification',
    );
    debugPrint('🎉 Notificación de bienvenida enviada a $userName');
  }

  // 🔴 Notificación cuando empieza un partido
  static Future<void> notifyGameStarting(MLBGame game) async {
    await _showLocalNotification(
      title: '🔴 ¡Partido EN VIVO!',
      body: '${game.awayTeam.name} vs ${game.homeTeam.name} acaba de comenzar en ${game.venue.name}',
      payload: game.id,
    );
    
    // También guardar en Firestore para historial
    await _saveNotificationHistory(game, 'game_started');
    debugPrint('🔴 Notificación de inicio enviada: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
  }

  // ⏰ Notificación para recordatorio de partido próximo
  static Future<void> notifyGameStartingSoon(MLBGame game, int minutesUntilStart) async {
    await _showLocalNotification(
      title: '⏰ Partido próximo - ${minutesUntilStart} minutos',
      body: '${game.awayTeam.name} vs ${game.homeTeam.name} empezará pronto en ${game.venue.name}',
      payload: game.id,
    );
    
    await _saveNotificationHistory(game, 'game_reminder');
    debugPrint('⏰ Recordatorio enviado: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation} en $minutesUntilStart min');
  }

  // 📊 Notificación para cambio de marcador
  static Future<void> notifyScoreUpdate(MLBGame game) async {
    if (game.score != null) {
      String title = '📊 Actualización de marcador';
      String body = '${game.awayTeam.name} ${game.score!.awayScore} - ${game.score!.homeScore} ${game.homeTeam.name}';
      
      // Agregar contexto si hay ganador
      if (game.score!.awayWins) {
        body += ' - ${game.awayTeam.name} va ganando';
      } else if (game.score!.homeWins) {
        body += ' - ${game.homeTeam.name} va ganando';
      } else if (game.score!.isTied) {
        body += ' - Empate';
      }
      
      await _showLocalNotification(
        title: title,
        body: body,
        payload: game.id,
      );
      
      await _saveNotificationHistory(game, 'score_update');
      debugPrint('📊 Marcador actualizado: ${game.awayTeam.abbreviation} ${game.score!.awayScore} - ${game.score!.homeScore} ${game.homeTeam.abbreviation}');
    }
  }

  // 🎉 Notificación cuando termina un partido
  static Future<void> notifyGameFinished(MLBGame game) async {
    if (game.score != null) {
      String winner = '';
      if (game.score!.awayWins) {
        winner = '🏆 ${game.awayTeam.name} ganó';
      } else if (game.score!.homeWins) {
        winner = '🏆 ${game.homeTeam.name} ganó';
      } else {
        winner = '🤝 Empate';
      }
      
      await _showLocalNotification(
        title: '🏁 Partido terminado',
        body: '$winner - ${game.awayTeam.name} ${game.score!.awayScore} - ${game.score!.homeScore} ${game.homeTeam.name}',
        payload: game.id,
      );
      
      await _saveNotificationHistory(game, 'game_finished');
      debugPrint('🏁 Partido terminado: $winner');
    }
  }

  // 🧪 SIMULACIÓN DE INICIO DE JUEGO (para debug)
  static Future<void> simulateGameStart() async {
    // Crear un juego de prueba realista
    final testGame = MLBGame(
      id: 'simulation_${DateTime.now().millisecondsSinceEpoch}',
      status: 'inprogress',
      scheduled: DateTime.now().toIso8601String(),
      homeTeam: Team(
        id: 'simulation_home',
        name: 'New York Yankees',
        market: 'New York',
        abbreviation: 'NYY',
      ),
      awayTeam: Team(
        id: 'simulation_away', 
        name: 'Boston Red Sox',
        market: 'Boston',
        abbreviation: 'BOS',
      ),
      venue: Venue(
        id: 'yankee_stadium',
        name: 'Yankee Stadium',
        city: 'New York',
        state: 'NY',
      ),
      isLive: true,
      score: GameScore(homeScore: 0, awayScore: 0),
    );

    await notifyGameStarting(testGame);
    debugPrint('🎮 Simulación de inicio de juego ejecutada');
  }

  // 🧪 SIMULACIÓN DE CAMBIO DE MARCADOR (para debug)
  static Future<void> simulateScoreUpdate() async {
    final testGame = MLBGame(
      id: 'score_simulation_${DateTime.now().millisecondsSinceEpoch}',
      status: 'inprogress',
      scheduled: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      homeTeam: Team(
        id: 'simulation_home',
        name: 'Los Angeles Dodgers',
        market: 'Los Angeles',
        abbreviation: 'LAD',
      ),
      awayTeam: Team(
        id: 'simulation_away', 
        name: 'San Francisco Giants',
        market: 'San Francisco',
        abbreviation: 'SF',
      ),
      venue: Venue(
        id: 'dodger_stadium',
        name: 'Dodger Stadium',
        city: 'Los Angeles',
        state: 'CA',
      ),
      isLive: true,
      score: GameScore(homeScore: 3, awayScore: 2),
    );

    await notifyScoreUpdate(testGame);
    debugPrint('🎮 Simulación de cambio de marcador ejecutada');
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
          'awayTeam': game.awayTeam.name,
          'homeTeam': game.homeTeam.name,
          'venue': game.venue.name,
          'status': game.status,
          'score': game.score != null ? '${game.score!.awayScore}-${game.score!.homeScore}' : null,
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Historial de notificación guardado: $type');
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

  // 🧪 SUITE COMPLETA DE TESTING
  static Future<void> runNotificationTests() async {
    debugPrint('🧪 Iniciando suite de tests de notificaciones...');
    
    // Test 1: Notificación básica
    await Future.delayed(const Duration(seconds: 1));
    await showTestNotification();
    
    // Test 2: Simulación de inicio de juego
    await Future.delayed(const Duration(seconds: 3));
    await simulateGameStart();
    
    // Test 3: Simulación de cambio de marcador
    await Future.delayed(const Duration(seconds: 5));
    await simulateScoreUpdate();
    
    debugPrint('✅ Suite de tests completada');
  }

  // Obtener historial de notificaciones del usuario
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown',
          'title': data['title'] ?? 'Sin título',
          'awayTeam': data['awayTeam'] ?? '',
          'homeTeam': data['homeTeam'] ?? '',
          'venue': data['venue'] ?? '',
          'score': data['score'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo historial: $e');
      return [];
    }
  }

  // Limpiar historial de notificaciones antiguas
  static Future<void> cleanOldNotificationHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final querySnapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isLessThan: Timestamp.fromDate(oneWeekAgo))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ ${querySnapshot.docs.length} notificaciones antiguas eliminadas');
    } catch (e) {
      debugPrint('❌ Error limpiando historial: $e');
    }
  }

  // Configurar notificaciones programadas (para recordatorios)
  static Future<void> scheduleGameReminder(MLBGame game, int minutesBefore) async {
    try {
      final gameTime = game.scheduledTime;
      if (gameTime == null) return;

      final reminderTime = gameTime.subtract(Duration(minutes: minutesBefore));
      final now = DateTime.now();

      if (reminderTime.isAfter(now)) {
        // Calcular delay hasta el recordatorio
        final delay = reminderTime.difference(now);
        
        debugPrint('📅 Recordatorio programado para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation} en ${delay.inMinutes} minutos');
        
        // ✅ Usar Timer.periodic o simplemente Timer
        Timer(delay, () async {
          await notifyGameStartingSoon(game, minutesBefore);
        });
      }
    } catch (e) {
      debugPrint('❌ Error programando recordatorio: $e');
    }
  }

  // Cancelar todas las notificaciones pendientes
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ Todas las notificaciones canceladas');
    } catch (e) {
      debugPrint('❌ Error cancelando notificaciones: $e');
    }
  }

  // Estadísticas de notificaciones
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'total_sent': 0,
          'game_started': 0,
          'reminders': 0,
          'score_updates': 0,
          'game_finished': 0,
        };
      }

      final querySnapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      int total = querySnapshot.docs.length;
      int gameStarted = 0;
      int reminders = 0;
      int scoreUpdates = 0;
      int gameFinished = 0;

      for (var doc in querySnapshot.docs) {
        final type = doc.data()['type'] as String? ?? '';
        switch (type) {
          case 'game_started':
            gameStarted++;
            break;
          case 'game_reminder':
            reminders++;
            break;
          case 'score_update':
            scoreUpdates++;
            break;
          case 'game_finished':
            gameFinished++;
            break;
        }
      }

      return {
        'total_sent': total,
        'game_started': gameStarted,
        'reminders': reminders,
        'score_updates': scoreUpdates,
        'game_finished': gameFinished,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {
        'total_sent': 0,
        'game_started': 0,
        'reminders': 0,
        'score_updates': 0,
        'game_finished': 0,
      };
    }
  }

  // Información del servicio de notificaciones
  static Future<Map<String, dynamic>> getServiceInfo() async {
    final settings = await getPermissionStatus();
    final isEnabled = await areNotificationsEnabled();
    
    return {
      'permissions_granted': isEnabled,
      'authorization_status': settings.authorizationStatus.toString(),
      'alert_enabled': settings.alert == AppleNotificationSetting.enabled,
      'badge_enabled': settings.badge == AppleNotificationSetting.enabled,
      'sound_enabled': settings.sound == AppleNotificationSetting.enabled,
      'channels_created': true, // Android channels
      'firebase_initialized': true,
    };
  }
}