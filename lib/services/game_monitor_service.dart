// lib/services/game_monitor_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/simple_mlb_models.dart'; // ✅ IMPORT CORREGIDO
import 'simple_mlb_service.dart'; // ✅ USAR SERVICIO SIMPLIFICADO
import 'push_notification_service.dart';
import 'game_notification_service.dart';

class GameMonitorService {
  static GameMonitorService? _instance;
  static GameMonitorService get instance => _instance ??= GameMonitorService._();
  GameMonitorService._();

  // Services
  final GameNotificationService _notificationService = GameNotificationService();

  // State
  Timer? _monitorTimer;
  List<MLBGame> _lastKnownGames = [];
  final Set<String> _gamesAlreadyNotified = <String>{};
  final Set<String> _remindersSent = <String>{};

  bool _isMonitoring = false;

  /// Iniciar el monitoreo automático
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('⚠️ Monitor ya está ejecutándose');
      return;
    }

    _isMonitoring = true;
    debugPrint('🔍 Iniciando monitor de partidos');

    // Verificar cada 1 minuto
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkGamesStatus();
    });

    // Primera verificación inmediata
    await _checkGamesStatus();
  }

  /// Detener el monitoreo
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    debugPrint('🛑 Monitor de partidos detenido');
  }

  /// Verificar estado de todos los partidos
  Future<void> _checkGamesStatus() async {
    try {
      debugPrint('🔍 Verificando estado de partidos...');
      
      // Obtener partidos actuales usando el servicio simplificado
      final currentGames = await SimpleMLBService.getTodaysGames();
      
      // Comparar con partidos anteriores
      await _detectGameChanges(currentGames);
      
      // Actualizar lista conocida
      _lastKnownGames = currentGames;
      
      debugPrint('✅ Verificación completada: ${currentGames.length} partidos');
    } catch (e) {
      debugPrint('❌ Error en verificación de partidos: $e');
    }
  }

  /// Detectar cambios en los partidos
  Future<void> _detectGameChanges(List<MLBGame> currentGames) async {
    final now = DateTime.now();
    
    for (final game in currentGames) {
      // Verificar si el usuario quiere notificaciones para este juego
      final shouldNotify = await _notificationService.isGameNotificationActive(game.id);
      if (!shouldNotify) continue;

      // Verificar diferentes tipos de eventos
      await _checkGameReminder(game, now);
      await _checkGameStart(game);
      await _checkScoreUpdate(game);
    }
  }

  /// Verificar recordatorio de juego (15 minutos antes)
  Future<void> _checkGameReminder(MLBGame game, DateTime now) async {
    // Evitar enviar el mismo recordatorio múltiples veces
    if (_remindersSent.contains(game.id)) return;

    final gameTime = game.scheduledTime;
    if (gameTime == null) return;

    final minutesUntilStart = gameTime.difference(now).inMinutes;
    
    // Enviar recordatorio entre 15 y 10 minutos antes
    if (minutesUntilStart <= 15 && minutesUntilStart >= 10) {
      await PushNotificationService.notifyGameStartingSoon(game, minutesUntilStart);
      _remindersSent.add(game.id);
      
      debugPrint('⏰ Recordatorio enviado: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation} en $minutesUntilStart min');
    }
  }

  /// Verificar inicio de juego
  Future<void> _checkGameStart(MLBGame game) async {
    // Evitar notificar el mismo juego múltiples veces
    if (_gamesAlreadyNotified.contains(game.id)) return;

    // Buscar el juego anterior para comparar estados
    final previousGame = _lastKnownGames.where((g) => g.id == game.id).firstOrNull;
    
    // Caso 1: El juego cambió de 'scheduled' a 'inprogress'
    final wasScheduled = previousGame?.status == 'scheduled';
    final isNowLive = game.status == 'inprogress' || game.isLive;
    
    if (wasScheduled && isNowLive) {
      await PushNotificationService.notifyGameStarting(game);
      _gamesAlreadyNotified.add(game.id);
      
      debugPrint('🔴 ¡PARTIDO INICIADO! ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
      return;
    }
    
    // Caso 2: Juego que aparece ya en vivo (primera detección)
    if (previousGame == null && isNowLive) {
      final gameTime = game.scheduledTime;
      if (gameTime != null) {
        final minutesSinceStart = DateTime.now().difference(gameTime).inMinutes;
        
        // Solo notificar si empezó hace menos de 10 minutos
        if (minutesSinceStart <= 10 && minutesSinceStart >= -5) {
          await PushNotificationService.notifyGameStarting(game);
          _gamesAlreadyNotified.add(game.id);
          
          debugPrint('🔴 ¡PARTIDO EN VIVO DETECTADO! ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
        }
      }
    }
  }

  /// Verificar cambios en el marcador
  Future<void> _checkScoreUpdate(MLBGame game) async {
    // Solo verificar si el juego está en vivo
    if (!game.isLive || game.score == null) return;

    final previousGame = _lastKnownGames.where((g) => g.id == game.id).firstOrNull;
    if (previousGame?.score == null) return;

    // Verificar si cambió el marcador
    final previousScore = previousGame!.score!;
    final currentScore = game.score!;
    
    final scoreChanged = previousScore.homeScore != currentScore.homeScore || 
                        previousScore.awayScore != currentScore.awayScore;
    
    if (scoreChanged) {
      await PushNotificationService.notifyScoreUpdate(game);
      
      debugPrint('📊 CAMBIO DE MARCADOR: ${game.awayTeam.abbreviation} ${currentScore.awayScore} - ${currentScore.homeScore} ${game.homeTeam.abbreviation}');
    }
  }

  /// Simular que un partido está empezando (para testing)
  Future<void> simulateGameStarting() async {
    if (_lastKnownGames.isEmpty) {
      debugPrint('⚠️ No hay partidos para simular');
      return;
    }

    final gameToSimulate = _lastKnownGames.first;
    
    // Crear una versión "en vivo" del juego
    final liveGame = MLBGame(
      id: gameToSimulate.id,
      status: 'inprogress',
      scheduled: gameToSimulate.scheduled,
      homeTeam: gameToSimulate.homeTeam,
      awayTeam: gameToSimulate.awayTeam,
      score: GameScore(homeScore: 0, awayScore: 0),
      venue: gameToSimulate.venue,
      isLive: true,
      inning: '1',
      inningHalf: 'top',
    );

    // Simular que tenemos notificación activa para este juego
    await _notificationService.addGameNotification(liveGame);
    
    // Forzar detección de cambio
    await _checkGameStart(liveGame);
    
    debugPrint('🎮 Simulación de inicio de partido ejecutada');
  }

  /// Forzar verificación inmediata
  Future<void> forceCheck() async {
    debugPrint('🔄 Forzando verificación inmediata...');
    await _checkGamesStatus();
  }

  /// Obtener estadísticas del monitor
  Map<String, dynamic> getMonitorStats() {
    return {
      'is_monitoring': _isMonitoring,
      'games_being_monitored': _lastKnownGames.length,
      'games_already_notified': _gamesAlreadyNotified.length,
      'reminders_sent': _remindersSent.length,
      'live_games_count': _lastKnownGames.where((g) => g.isLive).length,
      'scheduled_games_count': _lastKnownGames.where((g) => g.status == 'scheduled').length,
    };
  }

  /// Limpiar notificaciones del día anterior
  void resetDailyNotifications() {
    _gamesAlreadyNotified.clear();
    _remindersSent.clear();
    debugPrint('🧹 Cache de notificaciones limpiado');
  }

  /// Verificar si un juego específico ya fue notificado
  bool wasGameNotified(String gameId) {
    return _gamesAlreadyNotified.contains(gameId);
  }

  /// Estado actual del monitor
  bool get isMonitoring => _isMonitoring;
  int get monitoredGamesCount => _lastKnownGames.length;
  int get liveGamesCount => _lastKnownGames.where((g) => g.isLive).length;
}

// Extension para ayudar con null safety
extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}