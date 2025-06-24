// lib/screens/optimized_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/sport_category.dart';
import '../models/mlb_game.dart';
import '../services/auth_service.dart';
import '../services/sportradar_service.dart';
import '../services/game_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/game_monitor_service.dart'; // 🔍 NUEVO
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../widgets/game_widgets.dart';
import 'login_screen.dart';

class OptimizedDashboardScreen extends StatefulWidget {
  const OptimizedDashboardScreen({super.key});

  @override
  State<OptimizedDashboardScreen> createState() => _OptimizedDashboardScreenState();
}

class _OptimizedDashboardScreenState extends State<OptimizedDashboardScreen> {
  // UI State
  int _selectedIndex = 0;
  final List<SportCategory> _categories = sportCategories;

  // Services
  final AuthService _authService = AuthService();
  final SportradarService _sportradarService = SportradarService();
  final GameNotificationService _notificationService = GameNotificationService();
  final GameMonitorService _gameMonitor = GameMonitorService.instance; // 🔍 NUEVO

  // Data State
  UserModel? _currentUser;
  List<MLBGame> _allGames = [];
  List<MLBGame> _liveGames = [];
  List<MLBGame> _finishedGames = [];
  List<MLBGame> _scheduledGames = [];
  List<String> _userNotificationGames = [];

  // Loading States
  bool _isLoadingGames = true;
  String? _errorMessage;

  // Controllers
  Timer? _refreshTimer;
  Timer? _notificationTimer; // 🔔 NUEVO
  StreamSubscription<List<String>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    _notificationSubscription?.cancel();
    _gameMonitor.stopMonitoring(); // 🔍 NUEVO
    super.dispose();
  }

  /// Inicialización principal
  Future<void> _initializeApp() async {
    await _loadUserData();
    await _checkApiConfiguration();
    await _initializeNotifications();
    await _startGameMonitoring(); // 🔍 NUEVO
    await _loadInitialData();
    _setupAutoRefresh();
    _setupNotificationChecks();
    _listenToNotificationChanges();
    _showWelcomeNotification();
  }

  /// 🔍 INICIALIZAR MONITOR DE PARTIDOS
  Future<void> _startGameMonitoring() async {
    try {
      await _gameMonitor.startMonitoring();
      debugPrint('✅ Monitor de partidos iniciado');
    } catch (e) {
      debugPrint('❌ Error iniciando monitor de partidos: $e');
    }
  }

  /// 🔔 INICIALIZAR NOTIFICACIONES
  Future<void> _initializeNotifications() async {
    try {
      await PushNotificationService.initialize();
      debugPrint('✅ Notificaciones inicializadas en dashboard');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones en dashboard: $e');
    }
  }

  /// 🔔 CONFIGURAR VERIFICACIONES PERIÓDICAS DE NOTIFICACIONES
  void _setupNotificationChecks() {
    // Verificar cada 2 minutos si hay partidos que van a empezar
    _notificationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_allGames.isNotEmpty) {
        PushNotificationService.checkUpcomingGames(_allGames);
      }
    });
  }

  /// 🔔 MOSTRAR NOTIFICACIÓN DE BIENVENIDA (PRUEBA)
  Future<void> _showWelcomeNotification() async {
    // Esperar un poco para que la UI se cargue
    await Future.delayed(const Duration(seconds: 2));
    await PushNotificationService.showTestNotification();
  }

  /// Cargar datos del usuario
  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null && mounted) {
        setState(() {
          _currentUser = UserModel(
            uid: user.uid,
            email: userData['email'] ?? user.email ?? '',
            displayName: userData['displayName'] ?? user.displayName ?? 'Usuario',
            photoURL: userData['photoURL'] ?? '',
            favoriteTeams: List<String>.from(userData['favoriteTeams'] ?? []),
            favoriteSports: List<String>.from(userData['favoriteSports'] ?? []),
          );
        });
      }
    }
  }

  /// Verificar configuración de API
  Future<void> _checkApiConfiguration() async {
    if (!ApiConfig.isConfigured) {
      setState(() {
        _errorMessage = ApiConfig.apiKeyNotConfiguredMessage;
        _isLoadingGames = false;
      });
    }
  }

  /// Cargar datos iniciales
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTodaysGames(),
      _loadUserNotifications(),
    ]);
  }

  /// Cargar juegos del día (método principal optimizado)
  Future<void> _loadTodaysGames() async {
    if (!ApiConfig.isConfigured) return;

    try {
      setState(() {
        _isLoadingGames = true;
        _errorMessage = null;
      });

      final games = await _sportradarService.getTodaysGames();

      if (mounted) {
        _processGames(games);
        setState(() {
          _isLoadingGames = false;
        });

        debugPrint('✅ Dashboard: ${games.length} juegos procesados');
      }
    } catch (e) {
      debugPrint('❌ Error cargando juegos: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingGames = false;
        });
      }
    }
  }

  /// Procesar y clasificar juegos por estado
  void _processGames(List<MLBGame> games) {
    _allGames = games;
    _liveGames = _sportradarService.getLiveGames(games);
    _finishedGames = _sportradarService.getFinishedGames(games);
    _scheduledGames = _sportradarService.getScheduledGames(games);

    debugPrint('🎮 Clasificación: ${_liveGames.length} en vivo, ${_finishedGames.length} terminados, ${_scheduledGames.length} programados');
  }

  /// Cargar notificaciones del usuario
  Future<void> _loadUserNotifications() async {
    try {
      final notifications = await _notificationService.getUserNotificationGames();
      if (mounted) {
        setState(() {
          _userNotificationGames = notifications;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando notificaciones: $e');
    }
  }

  /// Configurar auto-refresh inteligente
  void _setupAutoRefresh() {
    final interval = _liveGames.isNotEmpty 
        ? const Duration(minutes: 2)
        : const Duration(minutes: 10);

    _refreshTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        _loadTodaysGames();
      }
    });
  }

  /// Escuchar cambios en notificaciones
  void _listenToNotificationChanges() {
    _notificationSubscription = _notificationService
        .getUserNotificationGamesStream()
        .listen((notifications) {
      if (mounted) {
        setState(() {
          _userNotificationGames = notifications;
        });
      }
    });
  }

  /// Toggle notificación de juego
  Future<void> _toggleGameNotification(MLBGame game) async {
    final isActive = _userNotificationGames.contains(game.id);

    bool success;
    if (isActive) {
      success = await _notificationService.removeGameNotification(game.id);
    } else {
      success = await _notificationService.addGameNotification(game);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Notificación desactivada' : 'Notificación activada',
          ),
          backgroundColor: isActive ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Manejo de tap en juego
  void _handleGameTap(MLBGame game) {
    debugPrint('🎯 Tap en juego: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${game.awayTeam.name} vs ${game.homeTeam.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTodaysGames,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategories(),
                      const SizedBox(height: 24),
                      _buildGamesContent(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header optimizado
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[400],
            ),
            child: Center(
              child: Text(
                (_currentUser?.displayName.isNotEmpty ?? false)
                    ? _currentUser!.displayName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.displayName ?? 'Usuario',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'México, Puebla',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status indicators
          if (_liveGames.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_liveGames.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),

          // Refresh button
          IconButton(
            icon: _isLoadingGames 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoadingGames ? null : _loadTodaysGames,
            tooltip: 'Actualizar',
          ),

          // Menu with notifications options 🔔
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('🧪 Prueba Notificación'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate_game',
                child: Row(
                  children: [
                    Icon(Icons.sports_baseball, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('🎮 Simular Partido'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'force_check',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.green),
                    SizedBox(width: 8),
                    Text('🔍 Verificar Ahora'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'monitor_stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('📊 Stats Monitor'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'test_connection',
                child: Row(
                  children: [
                    Icon(Icons.wifi),
                    SizedBox(width: 8),
                    Text('Test Conexión'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Categorías (simplificadas)
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deportes',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _categories.take(4).map((category) {
            return _buildCategoryItem(category);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(SportCategory category) {
    final isSelected = category.name == 'Beisbol'; // MLB selected by default
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected 
                ? category.color.withValues(alpha: 0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? category.color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              _getCategoryIcon(category.name),
              size: 28,
              color: isSelected ? category.color : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          category.name,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isSelected ? category.color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'basquetbol':
        return Icons.sports_basketball;
      case 'futbol':
        return Icons.sports_soccer;
      case 'beisbol':
        return Icons.sports_baseball;
      case 'tenis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  /// Contenido principal de juegos
  Widget _buildGamesContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_isLoadingGames && _allGames.isEmpty) {
      return _buildLoadingWidget();
    }

    if (_allGames.isEmpty) {
      return _buildNoGamesWidget();
    }

    return Column(
      children: [
        // Juegos en vivo (prioridad)
        if (_liveGames.isNotEmpty) ...[
          LiveScoresWidget(
            liveGames: _liveGames,
            onGameTap: _handleGameTap,
          ),
          const SizedBox(height: 20),
        ],

        // Todos los juegos del día
        TodayMatchesWidget(
          games: _allGames,
          onGameTap: _handleGameTap,
          onNotificationToggle: _toggleGameNotification,
          notificationGames: _userNotificationGames,
        ),

        const SizedBox(height: 20),

        // Juegos terminados
        if (_finishedGames.isNotEmpty) ...[
          FinishedScoresWidget(
            finishedGames: _finishedGames,
            onGameTap: _handleGameTap,
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'Error al cargar partidos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTodaysGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Reintentar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando partidos MLB...',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGamesWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_baseball, color: Colors.blue[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'No hay partidos programados',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron partidos de MLB para hoy.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _userNotificationGames.isNotEmpty,
              label: Text('${_userNotificationGames.length}'),
              child: Icon(_selectedIndex == 1 ? Icons.notifications : Icons.notifications_outlined),
            ),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _liveGames.isNotEmpty,
              label: Text('${_liveGames.length}'),
              child: Icon(_selectedIndex == 2 ? Icons.live_tv : Icons.live_tv_outlined),
            ),
            label: 'En Vivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Manejo de acciones del menú 🔔 ACTUALIZADO
  void _handleMenuAction(String action) {
    switch (action) {
      case 'test_notification':
        _showTestNotification();
        break;
      case 'simulate_game':
        _simulateGameStart();
        break;
      case 'force_check':
        _forceMonitorCheck(); // 🔍 NUEVO
        break;
      case 'monitor_stats':
        _showMonitorStats(); // 🔍 NUEVO
        break;
      case 'test_connection':
        _testApiConnection();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  /// 🔔 MOSTRAR NOTIFICACIÓN DE PRUEBA
  Future<void> _showTestNotification() async {
    await PushNotificationService.showTestNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Notificación de prueba enviada'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔔 SIMULAR INICIO DE PARTIDO
  Future<void> _simulateGameStart() async {
    await _gameMonitor.simulateGameStarting(); // 🔍 ACTUALIZADO
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎮 Simulación de inicio de partido enviada'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔍 FORZAR VERIFICACIÓN DEL MONITOR
  Future<void> _forceMonitorCheck() async {
    await _gameMonitor.forceCheck();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Verificación forzada ejecutada'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔍 MOSTRAR ESTADÍSTICAS DEL MONITOR
  void _showMonitorStats() {
    final stats = _gameMonitor.getMonitorStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Estadísticas del Monitor', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Monitor activo: ${stats['is_monitoring'] ? 'SÍ' : 'NO'}'),
            Text('🎮 Partidos monitoreados: ${stats['games_being_monitored']}'),
            Text('🔴 Partidos en vivo: ${stats['live_games_count']}'),
            Text('📅 Partidos programados: ${stats['scheduled_games_count']}'),
            Text('🔔 Notificaciones enviadas: ${stats['games_already_notified']}'),
            Text('⏰ Recordatorios enviados: ${stats['reminders_sent']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Test de conexión API
  Future<void> _testApiConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Probando conexión...'),
          ],
        ),
      ),
    );

    final isConnected = await _sportradarService.testConnection();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected ? 'Conexión exitosa ✅' : 'Error de conexión ❌',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// Cerrar sesión
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión', style: GoogleFonts.poppins()),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
}