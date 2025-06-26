// lib/screens/simple_dashboard_screen.dart - DASHBOARD COMPLETO CON LOGOS SVG
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/simple_mlb_models.dart';
import '../services/simple_mlb_service.dart';
import '../services/auth_service.dart';
import '../services/game_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/game_monitor_service.dart'; // ✅ YA NO ES UNUSED
import '../services/team_logo_service.dart';
import '../widgets/logo_test_widget.dart';
import 'login_screen.dart';

class SimpleDashboardScreen extends StatefulWidget {
  const SimpleDashboardScreen({super.key});

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen>
    with TickerProviderStateMixin {
  // Services
  final AuthService _authService = AuthService();
  final GameNotificationService _notificationService = GameNotificationService();
  
  // ✅ NUEVA INTEGRACIÓN: GameMonitorService
  late final GameMonitorService _gameMonitorService;
  
  // Data
  List<MLBGame> _allGames = [];
  List<MLBGame> _liveGames = [];
  List<MLBGame> _finishedGames = [];

  // Notification state
  List<String> _notificationGames = [];
  StreamSubscription<List<String>>? _notificationSubscription;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  Timer? _liveRefreshTimer;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ NUEVO: Estado del monitor
  bool _isMonitorActive = false;
  Map<String, dynamic> _monitorStats = {};

  @override
  void initState() {
    super.initState();
    
    // ✅ INICIALIZAR GameMonitorService
    _gameMonitorService = GameMonitorService.instance;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeDashboard();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _liveRefreshTimer?.cancel();
    _notificationSubscription?.cancel();
    _animationController.dispose();
    
    // ✅ DETENER MONITOR AL SALIR
    _gameMonitorService.stopMonitoring();
    
    super.dispose();
  }

  // ✅ NUEVA FUNCIÓN: Inicialización completa del dashboard
  Future<void> _initializeDashboard() async {
    await _loadGames();
    _setupAutoRefresh();
    _setupNotificationStream();
    
    // ✅ INICIAR MONITOR DE JUEGOS
    await _startGameMonitoring();
    
    _animationController.forward();
  }

  // ✅ NUEVA FUNCIÓN: Iniciar monitoreo automático
  Future<void> _startGameMonitoring() async {
    try {
      await _gameMonitorService.startMonitoring();
      setState(() {
        _isMonitorActive = _gameMonitorService.isMonitoring;
        _monitorStats = _gameMonitorService.getMonitorStats();
      });
      
      debugPrint('🔍 GameMonitorService iniciado exitosamente');
      
      // Actualizar estadísticas del monitor cada minuto
      Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _monitorStats = _gameMonitorService.getMonitorStats();
          });
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error al iniciar GameMonitorService: $e');
    }
  }

  Future<void> _loadGames() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final games = await SimpleMLBService.getTodaysGames();
      
      if (!mounted) return;
      
      setState(() {
        _allGames = games;
        _liveGames = SimpleMLBService.getLiveGames(games);
        _finishedGames = SimpleMLBService.getFinishedGames(games);
        _isLoading = false;
        
        // ✅ ACTUALIZAR ESTADÍSTICAS DEL MONITOR
        _monitorStats = _gameMonitorService.getMonitorStats();
      });

      debugPrint('📊 Juegos cargados: ${games.length} total, ${_liveGames.length} en vivo');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error al cargar los juegos: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error al cargar juegos: $e');
    }
  }

  void _setupAutoRefresh() {
    // Refresh general cada 5 minutos
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadGames();
      }
    });

    // Refresh rápido para juegos en vivo cada 30 segundos
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _liveGames.isNotEmpty) {
        _loadGames();
      }
    });
  }

  void _setupNotificationStream() {
    _notificationSubscription = _notificationService
        .getUserNotificationGamesStream()
        .listen((games) {
      if (mounted) {
        setState(() {
          _notificationGames = games;
        });
      }
    });
  }

  Future<void> _toggleGameNotification(MLBGame game) async {
    try {
      final isActive = _notificationGames.contains(game.id);
      
      if (isActive) {
        final success = await _notificationService.removeGameNotification(game.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificaciones desactivadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final success = await _notificationService.addGameNotification(game);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificaciones activadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar notificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NUEVA FUNCIÓN: Forzar verificación del monitor
  Future<void> _forceMonitorCheck() async {
    try {
      await _gameMonitorService.forceCheck();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verificación de monitor forzada'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en verificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    // ✅ DETENER MONITOR ANTES DE LOGOUT
    _gameMonitorService.stopMonitoring();
    
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildStatusCard(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildGamesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo y título (expandible)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_baseball, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EpicSports MLB',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Partidos de hoy',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Acciones del header (tamaño fijo)
              _buildHeaderActions(),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ✅ NUEVO WIDGET: Indicador del estado del monitor
  Widget _buildMonitorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isMonitorActive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isMonitorActive ? Icons.radio_button_checked : Icons.radio_button_off,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isMonitorActive ? 'Monitor ON' : 'Monitor OFF',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO WIDGET: Estadísticas del monitor
  Widget _buildMonitorStats() {
    if (!_isMonitorActive || _monitorStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Monitoreando', '${_monitorStats['games_being_monitored'] ?? 0}'),
          _buildStatItem('En Vivo', '${_monitorStats['live_games_count'] ?? 0}'),
          _buildStatItem('Notificados', '${_monitorStats['games_already_notified'] ?? 0}'),
          _buildStatItem('Recordatorios', '${_monitorStats['reminders_sent'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de notificaciones compacto
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _showNotificationStats,
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 20),
                if (_notificationGames.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_notificationGames.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Botón de info compacto
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _showAboutDialog,
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
        ),
        // Menú desplegable compacto
        PopupMenuButton<String>(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'simulate',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 18),
                  SizedBox(width: 8),
                  Text('Simular Notificación'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Cerrar Sesión'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadGames();
                break;
              case 'simulate':
                PushNotificationService.simulateGameStart();
                break;
              case 'logout':
                _logout();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              'Total Juegos',
              '${_allGames.length}',
              Icons.sports_baseball,
              const Color(0xFF6366F1),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatusItem(
              'En Vivo',
              '${_liveGames.length}',
              Icons.play_circle_filled,
              const Color(0xFFEF4444),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatusItem(
              'Terminados',
              '${_finishedGames.length}',
              Icons.check_circle,
              const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando partidos...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGames,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    if (_allGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_baseball, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay partidos programados para hoy',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Juegos en vivo
        if (_liveGames.isNotEmpty) ...[
          _buildSectionHeader('🔴 Partidos en Vivo', _liveGames.length),
          ..._liveGames.map((game) => _buildGameCard(game, isLive: true)),
          const SizedBox(height: 20),
        ],

        // Todos los juegos del día
        _buildSectionHeader('📅 Todos los Partidos', _allGames.length),
        ..._allGames.map((game) => _buildGameCard(game)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(MLBGame game, {bool isLive = false}) {
    final isCompleted = game.isCompleted;
    final hasScore = game.score != null;
    final hasNotification = _notificationGames.contains(game.id);
    
    // Determinar ganador si el juego terminó
    bool homeWins = false;
    bool awayWins = false;
    if (isCompleted && hasScore) {
      homeWins = game.score!.homeScore > game.score!.awayScore;
      awayWins = game.score!.awayScore > game.score!.homeScore;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLive 
            ? Border.all(color: Colors.red, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isLive 
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con estado y notificación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(game, isLive, isCompleted),
                _buildNotificationButton(game, hasNotification),
              ],
            ),
            const SizedBox(height: 16),
            
            // Equipos y marcador
            Row(
              children: [
                // Equipo visitante
                Expanded(
                  child: _buildTeamInfo(game.awayTeam, 
                      hasScore ? '${game.score!.awayScore}' : '', 
                      null, 
                      isWinner: awayWins),
                ),
                
                // VS o marcador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (hasScore) ...[
                        // Marcador
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${game.score!.awayScore}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: awayWins ? Colors.green[700] : Colors.grey[800],
                              ),
                            ),
                            Text(
                              ' - ',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              '${game.score!.homeScore}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: homeWins ? Colors.green[700] : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        // Inning info para juegos en vivo
                        if (isLive && game.inning != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${game.inningHalf?.toUpperCase()} ${game.inning}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ] else ...[
                        // VS
                        Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Equipo local
                Expanded(
                  child: _buildTeamInfo(game.homeTeam, 
                      hasScore ? '${game.score!.homeScore}' : '', 
                      null, 
                      isWinner: homeWins),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hora y estadio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              game.formattedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (game.venue != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  game.venue.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(Team team, String? score, Color? scoreColor, {bool isWinner = false}) {
    return Column(
      children: [
        // Logo SVG del equipo
        TeamLogoService.getTeamLogo(team.abbreviation, size: 60),
        const SizedBox(height: 12),
        
        // Código del equipo
        Text(
          team.abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.green[700] : Colors.grey[800],
          ),
        ),
        
        // Nombre del equipo
        Text(
          team.name.length > 15 ? '${team.name.substring(0, 15)}...' : team.name,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(MLBGame game, bool isLive, bool isFinished) {
    String status;
    Color color;
    
    if (isLive || game.isLive) {
      status = 'EN VIVO';
      color = Colors.red;
    } else if (isFinished || game.isCompleted) {
      status = 'FINAL';
      color = Colors.green;
    } else {
      status = 'PROGRAMADO';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(MLBGame game, bool hasNotification) {
    return GestureDetector(
      onTap: () => _toggleGameNotification(game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasNotification 
                ? [Colors.orange[400]!, Colors.orange[600]!]
                : [Colors.grey[300]!, Colors.grey[400]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (hasNotification ? Colors.orange : Colors.grey).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNotification ? Icons.notifications_active : Icons.notifications_off,
              size: 16,
              color: hasNotification ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              hasNotification ? 'ON' : 'OFF',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasNotification ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Notificaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Juegos con alertas: ${_notificationGames.length}'),
            Text('Total de juegos: ${_allGames.length}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                PushNotificationService.simulateGameStart();
              },
              child: const Text('Probar Notificación'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_baseball, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('EpicSports MLB'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu app definitiva para seguir los partidos de MLB en tiempo real.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('Versión: 1.0.0', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            Text('Desarrollado con Flutter', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}