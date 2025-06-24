// lib/services/dashboard_state_manager.dart
import 'package:flutter/foundation.dart';
import '../models/mlb_game.dart';
import 'sportradar_service.dart';
import 'game_notification_service.dart';
import 'dart:async';

/// Gestor centralizado del estado del dashboard
class DashboardStateManager extends ChangeNotifier {
  // Services
  final SportradarService _sportradarService = SportradarService();
  final GameNotificationService _notificationService = GameNotificationService();

  // State
  List<MLBGame> _allGames = [];
  List<MLBGame> _liveGames = [];
  List<MLBGame> _finishedGames = [];
  List<MLBGame> _scheduledGames = [];
  List<String> _userNotificationGames = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;

  // Timers
  Timer? _refreshTimer;
  StreamSubscription? _notificationSubscription;

  // Getters
  List<MLBGame> get allGames => List.unmodifiable(_allGames);
  List<MLBGame> get liveGames => List.unmodifiable(_liveGames);
  List<MLBGame> get finishedGames => List.unmodifiable(_finishedGames);
  List<MLBGame> get scheduledGames => List.unmodifiable(_scheduledGames);
  List<String> get userNotificationGames => List.unmodifiable(_userNotificationGames);
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  
  bool get hasLiveGames => _liveGames.isNotEmpty;
  int get totalGames => _allGames.length;

  /// Inicializar el gestor
  Future<void> initialize() async {
    await _loadNotifications();
    await loadGames();
    _setupAutoRefresh();
    _listenToNotificationChanges();
  }

  /// Cargar juegos del día
  Future<void> loadGames() async {
    try {
      _setLoading(true);
      _clearError();

      final games = await _sportradarService.getTodaysGames();
      _processGames(games);
      _lastUpdate = DateTime.now();

      debugPrint('📊 Estado actualizado: ${_allGames.length} total, ${_liveGames.length} en vivo');
    } catch (e) {
      _setError(e.toString());
      debugPrint('❌ Error en DashboardStateManager: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Procesar y clasificar juegos
  void _processGames(List<MLBGame> games) {
    _allGames = games;
    _liveGames = _sportradarService.getLiveGames(games);
    _finishedGames = _sportradarService.getFinishedGames(games);
    _scheduledGames = _sportradarService.getScheduledGames(games);
    notifyListeners();
  }

  /// Cargar notificaciones del usuario
  Future<void> _loadNotifications() async {
    try {
      _userNotificationGames = await _notificationService.getUserNotificationGames();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error cargando notificaciones: $e');
    }
  }

  /// Configurar auto-refresh
  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    
    // Intervalo dinámico basado en si hay juegos en vivo
    final interval = hasLiveGames 
        ? const Duration(minutes: 2)
        : const Duration(minutes: 10);

    _refreshTimer = Timer.periodic(interval, (timer) {
      loadGames();
    });
  }

  /// Escuchar cambios en notificaciones
  void _listenToNotificationChanges() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _notificationService
        .getUserNotificationGamesStream()
        .listen((notifications) {
      _userNotificationGames = notifications;
      notifyListeners();
    });
  }

  /// Toggle notificación para un juego
  Future<bool> toggleGameNotification(MLBGame game) async {
    try {
      final isActive = _userNotificationGames.contains(game.id);
      
      bool success;
      if (isActive) {
        success = await _notificationService.removeGameNotification(game.id);
      } else {
        success = await _notificationService.addGameNotification(game);
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error toggle notificación: $e');
      return false;
    }
  }

  /// Obtener juego específico por ID
  MLBGame? getGameById(String gameId) {
    try {
      return _allGames.firstWhere((game) => game.id == gameId);
    } catch (e) {
      return null;
    }
  }

  /// Verificar si un juego tiene notificación activa
  bool isGameNotificationActive(String gameId) {
    return _userNotificationGames.contains(gameId);
  }

  /// Obtener estadísticas del estado actual
  Map<String, dynamic> getStats() {
    return {
      'total_games': _allGames.length,
      'live_games': _liveGames.length,
      'finished_games': _finishedGames.length,
      'scheduled_games': _scheduledGames.length,
      'notifications_active': _userNotificationGames.length,
      'last_update': _lastUpdate?.toIso8601String(),
      'is_loading': _isLoading,
      'has_error': _errorMessage != null,
    };
  }

  /// Test de conexión
  Future<bool> testConnection() async {
    return await _sportradarService.testConnection();
  }

  /// Forzar actualización
  Future<void> forceRefresh() async {
    _refreshTimer?.cancel();
    await loadGames();
    _setupAutoRefresh();
  }

  // Helpers privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}