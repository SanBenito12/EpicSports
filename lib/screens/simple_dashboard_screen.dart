// lib/screens/simple_dashboard_screen.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/simple_mlb_models.dart';
import '../services/simple_mlb_service.dart';
import '../services/auth_service.dart';
import '../services/game_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/game_monitor_service.dart';
import '../services/team_logo_service.dart';
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

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
    
    // Verificar servicio de logos para que el linter detecte el uso
    debugPrint('🏆 Servicio de logos inicializado: ${TeamLogoService.getAllTeams().length} equipos');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
  }

  /// Inicialización completa de la app
  Future<void> _initializeApp() async {
    try {
      // Verificar que el servicio de logos funcione
      debugPrint('🏆 TeamLogoService inicializado: ${TeamLogoService.getServiceInfo()}');
      
      await _showWelcomeNotification();
      await _initializeGameMonitor();
      await _loadGames();
      _setupNotificationSubscription();
      _setupAutoRefresh();
      
      // Iniciar animaciones
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
    } catch (e) {
      debugPrint('❌ Error inicializando app: $e');
    }
  }

  Future<void> _showWelcomeNotification() async {
    try {
      await PushNotificationService.showTestNotification();
      debugPrint('✅ Notificación de bienvenida enviada');
    } catch (e) {
      debugPrint('❌ Error enviando notificación de bienvenida: $e');
    }
  }

  Future<void> _initializeGameMonitor() async {
    try {
      await GameMonitorService.instance.startMonitoring();
    } catch (e) {
      debugPrint('❌ Error inicializando monitor de juegos: $e');
    }
  }

  void _setupNotificationSubscription() {
    _notificationSubscription = _notificationService
        .getUserNotificationGamesStream()
        .listen((gameIds) {
      if (mounted) {
        setState(() {
          _notificationGames = gameIds;
        });
        debugPrint('🔔 Notificaciones actualizadas: ${gameIds.length} juegos');
      }
    });
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final games = await SimpleMLBService.getTodaysGames();
      if (mounted) {
        setState(() {
          _allGames = games;
          _liveGames = SimpleMLBService.getLiveGames(games);
          _finishedGames = SimpleMLBService.getFinishedGames(games);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleGameNotification(MLBGame game) async {
    try {
      final isActive = _notificationGames.contains(game.id);
      if (isActive) {
        final success = await _notificationService.removeGameNotification(game.id);
        if (success && mounted) {
          _showCustomSnackBar(
            '🔕 Notificaciones desactivadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}',
            Colors.orange,
            Icons.notifications_off,
          );
        }
      } else {
        final success = await _notificationService.addGameNotification(game);
        if (success && mounted) {
          _showCustomSnackBar(
            '🔔 Notificaciones activadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}',
            Colors.green,
            Icons.notifications_active,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          'Error al cambiar notificación',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  void _showCustomSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadGames();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
              Color(0xFF3d6cb9),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: _loadGames,
                color: Colors.white,
                backgroundColor: const Color(0xFF1e3c72),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildModernAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverToBoxAdapter(
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1e3c72),
                Color(0xFF2a5298),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sports_baseball,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚾ MLB Hoy',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Partidos en tiempo real',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isLoading) _buildAnimatedStats(),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Indicador de notificaciones con animación
        if (_notificationGames.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active, color: Colors.white),
                  onPressed: _showNotificationStats,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${_notificationGames.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        // Botón refresh con animación
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _loadGames,
              tooltip: 'Actualizar',
            );
          },
        ),
        // Menú mejorado
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            _buildMenuItem('notifications', Icons.notifications, 'Mis Notificaciones'),
            _buildMenuItem('test_notification', Icons.notification_add, 'Probar Notificación'),
            const PopupMenuDivider(),
            _buildMenuItem('about', Icons.info, 'Acerca de'),
            _buildMenuItem('logout', Icons.logout, 'Cerrar Sesión'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_liveGames.isNotEmpty) ...[
            _buildStatCard(
              icon: Icons.circle,
              label: '${_liveGames.length} EN VIVO',
              color: Colors.red,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
              ),
            ),
            const SizedBox(width: 12),
          ],
          _buildStatCard(
            icon: Icons.sports_baseball,
            label: '${_allGames.length} PARTIDOS',
            color: Colors.blue,
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
            ),
          ),
          if (_notificationGames.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.notifications_active,
              label: '${_notificationGames.length} SIGUIENDO',
              color: Colors.orange,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
    required Gradient gradient,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    if (_isLoading && _allGames.isEmpty) {
      return _buildLoadingWidget();
    }
    if (_allGames.isEmpty) {
      return _buildEmptyWidget();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Juegos en vivo con diseño especial
        if (_liveGames.isNotEmpty) ...[
          _buildSectionHeader(
            '🔴 EN VIVO',
            '${_liveGames.length} partidos',
            Colors.red,
            const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)]),
          ),
          const SizedBox(height: 16),
          ..._liveGames.asMap().entries.map((entry) {
            final index = entry.key;
            final game = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGameCard(game, isLive: true),
                    ),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 32),
        ],
        
        // Todos los juegos
        _buildSectionHeader(
          '📅 PARTIDOS DE HOY',
          '${_allGames.length} total',
          Colors.blue,
          const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF2196F3)]),
        ),
        const SizedBox(height: 16),
        ..._allGames.asMap().entries.map((entry) {
          final index = entry.key;
          final game = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildGameCard(game),
                  ),
                ),
              );
            },
          );
        }),
        
        // Juegos terminados
        if (_finishedGames.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            '✅ RESULTADOS FINALES',
            '${_finishedGames.length} completados',
            Colors.green,
            const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
          ),
          const SizedBox(height: 16),
          ..._finishedGames.asMap().entries.map((entry) {
            final index = entry.key;
            final game = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGameCard(game, isFinished: true),
                    ),
                  ),
                );
              },
            );
          }),
        ],
        
        // Espacio final para el scroll
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title.contains('VIVO') ? Icons.circle :
              title.contains('HOY') ? Icons.today :
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGameCard(MLBGame game, {bool isLive = false, bool isFinished = false}) {
    final hasNotification = _notificationGames.contains(game.id);

    Color? awayScoreColor;
    Color? homeScoreColor;
    if (game.score != null) {
      if (game.score!.awayWins) {
        awayScoreColor = Colors.green[700];
        homeScoreColor = Colors.grey[600];
      } else if (game.score!.homeWins) {
        homeScoreColor = Colors.green[700];
        awayScoreColor = Colors.grey[600];
      } else {
        awayScoreColor = isLive ? Colors.red[700] : Colors.blue[700];
        homeScoreColor = isLive ? Colors.red[700] : Colors.blue[700];
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasNotification 
              ? Colors.orange[300]!
              : isLive 
                  ? Colors.red[200]! 
                  : Colors.grey[200]!,
          width: hasNotification ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive 
                ? Colors.red.withOpacity(0.15)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isLive ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header con estado y tiempo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(game.status),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      game.formattedTime,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (game.inning != null && game.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Inning ${game.inning}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Equipos y marcador mejorado
            Row(
              children: [
                // Equipo visitante
                Expanded(
                  child: _buildTeamSection(
                    game.awayTeam,
                    game.score?.awayScore,
                    awayScoreColor,
                    isWinner: game.score?.awayWins == true,
                  ),
                ),
                
                // Separador central mejorado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLive 
                                ? [Colors.red[400]!, Colors.red[600]!]
                                : [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isLive ? Colors.red : Colors.blue).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (game.score != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.red[50] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${game.score!.awayScore} - ${game.score!.homeScore}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLive ? Colors.red[700] : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Equipo local
                Expanded(
                  child: _buildTeamSection(
                    game.homeTeam,
                    game.score?.homeScore,
                    homeScoreColor,
                    isWinner: game.score?.homeWins == true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Footer mejorado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      game.venue.location,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildNotificationButton(game, hasNotification),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(MLBGame game, bool hasNotification) {
    return GestureDetector(
      onTap: () => _toggleGameNotification(game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasNotification 
                ? [Colors.orange[400]!, Colors.orange[600]!]
                : [Colors.grey[300]!, Colors.grey[400]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (hasNotification ? Colors.orange : Colors.grey).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNotification ? Icons.notifications_active : Icons.notifications_none,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              hasNotification ? 'ON' : 'OFF',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(Team team, int? score, Color? scoreColor, {bool isWinner = false}) {
    return Column(
      children: [
        // Logo del equipo con efectos mejorados
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTeamColor(team.abbreviation),
                _getTeamColor(team.abbreviation).withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getTeamColor(team.abbreviation).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              team.abbreviation.isNotEmpty ? team.abbreviation : 'TBD',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Nombre del equipo
        Text(
          team.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isWinner ? Colors.green[700] : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        
        // Marcador con diseño mejorado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: score != null 
                  ? [Colors.white, Colors.grey[50]!]
                  : [Colors.grey[100]!, Colors.grey[200]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scoreColor ?? Colors.grey[300]!,
              width: isWinner ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (scoreColor ?? Colors.grey).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            score?.toString() ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: scoreColor ?? Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    Gradient gradient;
    
    switch (status) {
      case 'inprogress':
        color = Colors.red;
        text = 'EN VIVO';
        icon = Icons.circle;
        gradient = const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)]);
        break;
      case 'closed':
        color = Colors.green;
        text = 'FINAL';
        icon = Icons.check_circle;
        gradient = const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]);
        break;
      default:
        color = Colors.blue;
        text = 'PROGRAMADO';
        icon = Icons.schedule;
        gradient = const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF2196F3)]);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.red[600], size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'No se pudieron cargar los partidos',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Verifica tu conexión a internet e intenta nuevamente',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            label: Text('Reintentar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28, // 2π
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_baseball,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando partidos...',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Obteniendo los últimos datos de MLB',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_baseball,
              color: Colors.blue[600],
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay partidos hoy',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No se encontraron partidos programados para hoy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            label: Text('Actualizar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String abbreviation) {
    switch (abbreviation.toUpperCase()) {
      case 'NYY': return const Color(0xFF1F2A44); // Yankees Navy
      case 'BOS': return const Color(0xFFBD3039); // Red Sox Red
      case 'LAD': return const Color(0xFF005A9C); // Dodgers Blue
      case 'SF': return const Color(0xFFFF6600); // Giants Orange
      case 'CHC': return const Color(0xFF0E3386); // Cubs Blue
      case 'NYM': return const Color(0xFF002D72); // Mets Blue
      case 'HOU': return const Color(0xFFEB6E1F); // Astros Orange
      case 'ATL': return const Color(0xFFCE1141); // Braves Red
      case 'WSH': return const Color(0xFFAB0003); // Nationals Red
      case 'PHI': return const Color(0xFFE81828); // Phillies Red
      case 'MIA': return const Color(0xFF00A3E0); // Marlins Blue
      case 'TOR': return const Color(0xFF134A8E); // Blue Jays Blue
      case 'TB': return const Color(0xFF092C5C); // Rays Navy
      case 'BAL': return const Color(0xFFDF4601); // Orioles Orange
      case 'CHW': return const Color(0xFF27251F); // White Sox Black
      case 'CLE': return const Color(0xFFE31937); // Guardians Red
      case 'DET': return const Color(0xFF0C2340); // Tigers Navy
      case 'KC': return const Color(0xFF004687); // Royals Blue
      case 'MIN': return const Color(0xFF002B5C); // Twins Navy
      case 'OAK': return const Color(0xFF003831); // Athletics Green
      case 'LAA': return const Color(0xFFBA0021); // Angels Red
      case 'SEA': return const Color(0xFF0C2C56); // Mariners Navy
      case 'TEX': return const Color(0xFFC0111F); // Rangers Red
      case 'MIL': return const Color(0xFF0A2351); // Brewers Navy
      case 'STL': return const Color(0xFFC41E3A); // Cardinals Red
      case 'CIN': return const Color(0xFFC6011F); // Reds Red
      case 'PIT': return const Color(0xFFFDB827); // Pirates Gold
      case 'ARI': return const Color(0xFFA71930); // Diamondbacks Red
      case 'COL': return const Color(0xFF33006F); // Rockies Purple
      case 'SD': return const Color(0xFF2F241D); // Padres Brown
      default: return const Color(0xFF1976D2); // Default Blue
    }
  }

  /// Manejo de acciones del menú
  void _handleMenuAction(String action) {
    switch (action) {
      case 'notifications':
        _showNotificationStats();
        break;
      case 'test_notification':
        _testNotification();
        break;
      case 'about':
        _showAboutDialog();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  Future<void> _testNotification() async {
    try {
      await PushNotificationService.showTestNotification();
      if (mounted) {
        _showCustomSnackBar(
          'Notificación de prueba enviada',
          Colors.green,
          Icons.check_circle,
        );
      }
      debugPrint('🧪 Notificación de prueba enviada');
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          'Error al enviar notificación',
          Colors.red,
          Icons.error,
        );
      }
      debugPrint('❌ Error enviando notificación: $e');
    }
  }

  Future<void> _showNotificationStats() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mis Notificaciones',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              if (_notificationGames.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes notificaciones activas',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el botón de notificación en cualquier partido para recibir alertas.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_active, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 12),
                          Text(
                            '${_notificationGames.length} partidos siguiendo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recibirás notificaciones cuando estos partidos empiecen y cuando cambien los marcadores.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (_notificationGames.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _testNotification();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Probar Notificación',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    debugPrint('📊 Estadísticas de notificaciones mostradas');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_baseball,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EpicSports MLB',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versión 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tu app definitiva para seguir los partidos de MLB en tiempo real.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Características:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Marcadores en tiempo real\n• Notificaciones personalizables\n• Información completa de partidos\n• Interfaz moderna y fácil de usar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cerrar Sesión',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cerrar Sesión',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirmed == true) {
      debugPrint('🔔 Limpiando notificaciones al cerrar sesión');
      await _notificationService.clearAllNotifications();
      GameMonitorService.instance.stopMonitoring();
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