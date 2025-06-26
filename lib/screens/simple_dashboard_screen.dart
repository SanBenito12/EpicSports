// lib/screens/simple_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/simple_mlb_models.dart';
import '../services/simple_mlb_service.dart';
import '../services/auth_service.dart';
import '../services/game_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/game_monitor_service.dart';
import 'login_screen.dart';

class SimpleDashboardScreen extends StatefulWidget {
  const SimpleDashboardScreen({super.key});

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Inicialización completa de la app
  Future<void> _initializeApp() async {
    try {
      // 1. Mostrar notificación de bienvenida automática
      await _showWelcomeNotification();
      // 2. Inicializar monitor de juegos
      await _initializeGameMonitor();
      // 3. Cargar datos
      await _loadGames();
      // 4. Configurar subscripción a notificaciones
      _setupNotificationSubscription();
      // 5. Configurar auto-refresh
      _setupAutoRefresh();
    } catch (e) {
      debugPrint('❌ Error inicializando app: $e');
    }
  }

  /// Mostrar notificación de bienvenida automática
  Future<void> _showWelcomeNotification() async {
    try {
      await PushNotificationService.showTestNotification();
      debugPrint('✅ Notificación de bienvenida enviada');
    } catch (e) {
      debugPrint('❌ Error enviando notificación de bienvenida: $e');
    }
  }

  /// Inicializar monitor de juegos
  Future<void> _initializeGameMonitor() async {
    try {
      await GameMonitorService.instance.startMonitoring();
    } catch (e) {
      debugPrint('❌ Error inicializando monitor de juegos: $e');
    }
  }

  /// Configurar subscripción a notificaciones
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

  /// Cargar juegos de MLB
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

  /// Toggle notificación para un juego específico
  Future<void> _toggleGameNotification(MLBGame game) async {
    try {
      final isActive = _notificationGames.contains(game.id);
      if (isActive) {
        // Desactivar notificación
        final success = await _notificationService.removeGameNotification(game.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔕 Notificaciones desactivadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // Activar notificación
        final success = await _notificationService.addGameNotification(game);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔔 Notificaciones activadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar notificación'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Auto-refresh cada 5 minutos
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
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadGames,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// App Bar mejorada con diseño moderno
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'MLB Hoy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(200, 220, 255, 1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isLoading) ...[
                    const SizedBox(height: 8),
                    _buildQuickStats(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Indicador de notificaciones activas
        if (_notificationGames.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active),
                  onPressed: _showNotificationStats,
                  color: Colors.orange[700],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_notificationGames.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Botón refresh
        IconButton(
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadGames,
          tooltip: 'Actualizar',
        ),
        // Menú simplificado para app final
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications),
                  SizedBox(width: 8),
                  Text('Mis Notificaciones'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test_notification',
              child: Row(
                children: [
                  Icon(Icons.notification_add),
                  SizedBox(width: 8),
                  Text('Probar Notificación'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('Acerca de'),
                ],
              ),
            ),
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
    );
  }

  /// Estadísticas rápidas en el header
  Widget _buildQuickStats() {
    return Row(
      children: [
        if (_liveGames.isNotEmpty) ...[
          _buildStatChip(
            icon: Icons.circle,
            label: '${_liveGames.length} en vivo',
            color: Colors.red,
          ),
          const SizedBox(width: 8),
        ],
        _buildStatChip(
          icon: Icons.sports_baseball,
          label: '${_allGames.length} partidos',
          color: Colors.blue,
        ),
        if (_notificationGames.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.notifications_active,
            label: '${_notificationGames.length} siguiendo',
            color: Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido principal
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
          _buildLiveGamesSection(),
          const SizedBox(height: 24),
        ],
        // Todos los juegos
        _buildAllGamesSection(),
        // Juegos terminados
        if (_finishedGames.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFinishedGamesSection(),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  /// Sección de juegos en vivo con diseño destacado
  Widget _buildLiveGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'EN VIVO',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_liveGames.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _liveGames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGameCard(_liveGames[index], isLive: true),
            );
          },
        ),
      ],
    );
  }

  /// Sección de todos los juegos
  Widget _buildAllGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partidos de Hoy',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allGames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGameCard(_allGames[index]),
            );
          },
        ),
      ],
    );
  }

  /// Sección de juegos terminados
  Widget _buildFinishedGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Resultados Finales',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _finishedGames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGameCard(_finishedGames[index], isFinished: true),
            );
          },
        ),
      ],
    );
  }

  /// Card de juego mejorada con diseño premium
  Widget _buildGameCard(MLBGame game, {bool isLive = false, bool isFinished = false}) {
    final hasNotification = _notificationGames.contains(game.id);

    // Determinar colores del marcador
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                ? Color.fromRGBO(255, 0, 0, 0.1)
                : Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: isLive ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (game.inning != null && game.isLive)
                      Text(
                        'Inning ${game.inning}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Equipos y marcador - Layout mejorado
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
                // Separador central
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red[50] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.red[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (game.score != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${game.score!.awayScore} - ${game.score!.homeScore}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.red[700] : Colors.blue[700],
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
            const SizedBox(height: 20),
            // Footer con venue y controles
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    game.venue.location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildNotificationButton(game, hasNotification),
              ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasNotification ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNotification ? Colors.orange[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNotification ? Icons.notifications_active : Icons.notifications_none,
              size: 18,
              color: hasNotification ? Colors.orange[700] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              hasNotification ? 'ON' : 'OFF',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasNotification ? Colors.orange[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de equipo mejorada
  Widget _buildTeamSection(Team team, int? score, Color? scoreColor, {bool isWinner = false}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getTeamColor(team.abbreviation),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getTeamColor(team.abbreviation).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              team.abbreviation.isNotEmpty ? team.abbreviation : 'TBD',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          team.name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isWinner ? Colors.green[700] : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: score != null ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scoreColor ?? Colors.grey[300]!,
              width: isWinner ? 2 : 1,
            ),
          ),
          child: Text(
            score?.toString() ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scoreColor ?? Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTeamColor(String abbreviation) {
    switch (abbreviation.toUpperCase()) {
      case 'NYY': return Colors.blue[900]!;
      case 'BOS': return Colors.red[700]!;
      case 'LAD': return Colors.blue[600]!;
      case 'SF': return Colors.orange[700]!;
      case 'CHC': return Colors.blue[600]!;
      case 'NYM': return Colors.blue[700]!;
      case 'HOU': return Colors.orange[800]!;
      case 'ATL': return Colors.red[600]!;
      default: return Colors.blue[400]!;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    switch (status) {
      case 'inprogress':
        color = Colors.red;
        text = 'EN VIVO';
        icon = Icons.circle;
        break;
      case 'closed':
        color = Colors.green;
        text = 'FINAL';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.blue;
        text = 'PROGRAMADO';
        icon = Icons.schedule;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
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

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 56),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los partidos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica tu conexión a internet e intenta nuevamente',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            label: Text('Reintentar', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando partidos...',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Obteniendo los últimos datos de MLB',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_baseball,
            color: Colors.grey[400],
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'No hay partidos hoy',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron partidos programados para hoy',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            label: Text('Actualizar', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
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

  /// Test de notificación manual
  Future<void> _testNotification() async {
    try {
      await PushNotificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notificación de prueba enviada'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      debugPrint('🧪 Notificación de prueba enviada');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al enviar notificación'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      debugPrint('❌ Error enviando notificación: $e');
    }
  }

  /// Mostrar estadísticas de notificaciones
  Future<void> _showNotificationStats() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Text(
              'Mis Notificaciones',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_notificationGames.isEmpty) ...[
              const Icon(Icons.notifications_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No tienes notificaciones activas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el botón de notificación en cualquier partido para recibir alertas.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          '${_notificationGames.length} partidos siguiendo',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recibirás notificaciones cuando estos partidos empiecen y cuando cambien los marcadores.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          if (_notificationGames.isNotEmpty)
            FilledButton(
              onPressed: _testNotification,
              child: Text(
                'Probar Notificación',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
    debugPrint('📊 Estadísticas de notificaciones mostradas');
  }

  /// Mostrar información de la app
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.sports_baseball, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              'EpicSports MLB',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu app definitiva para seguir los partidos de MLB en tiempo real.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Características:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Marcadores en tiempo real\n• Notificaciones personalizables\n• Información completa de partidos\n• Interfaz moderna y fácil de usar',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Limpiar notificaciones y parar monitor
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