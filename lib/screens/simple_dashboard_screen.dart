// lib/screens/simple_dashboard_screen.dart - DASHBOARD COMPLETO CON LOGOS SVG
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
  Timer? _autoRefreshTimer;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadGames();
    _setupAutoRefresh();
    _setupNotificationStream();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _notificationSubscription?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
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

  Future<void> _loadGames() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _refreshController.forward();

      final games = await SimpleMLBService.getTodaysGames();
      
      if (!mounted) return;

      setState(() {
        _allGames = games;
        _liveGames = SimpleMLBService.getLiveGames(games);
        _finishedGames = SimpleMLBService.getFinishedGames(games);
        _isLoading = false;
      });

      _refreshController.reverse();
      
      debugPrint('✅ Dashboard cargado: ${_allGames.length} juegos total');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error cargando juegos: $e';
        _isLoading = false;
      });
      
      _refreshController.reverse();
      debugPrint('❌ Error en dashboard: $e');
    }
  }

  Future<void> _toggleGameNotification(MLBGame game) async {
    try {
      final hasNotification = _notificationGames.contains(game.id);
      
      if (hasNotification) {
        await _notificationService.removeGameNotification(game.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación desactivada para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _notificationService.addGameNotification(game);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación activada para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cerrando sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_baseball, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MLB Today',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_allGames.length} juegos',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AnimatedBuilder(
          animation: _refreshController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshController.value * 2 * 3.14159,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isLoading ? null : _loadGames,
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'test_logos':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogoTestWidget()),
                );
                break;
              case 'notifications':
                _showNotificationStats();
                break;
              case 'test':
                PushNotificationService.simulateGameStart();
                break;
              case 'about':
                _showAboutDialog();
                break;
              case 'logout':
                _signOut();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'test_logos',
              child: Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 8),
                  Text('Probar Logos'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications),
                  SizedBox(width: 8),
                  Text('Notificaciones'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Test Notificación'),
                ],
              ),
            ),
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

  Widget _buildBody() {
    if (_isLoading && _allGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando juegos MLB...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error cargando datos',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadGames,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGames,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas generales
            _buildStatsCard(),
            const SizedBox(height: 20),

            // Juegos en vivo
            if (_liveGames.isNotEmpty) ...[
              _buildSectionHeader(
                '🔴 EN VIVO',
                '${_liveGames.length} partido${_liveGames.length != 1 ? 's' : ''} en progreso',
                Colors.red,
                const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]),
              ),
              const SizedBox(height: 16),
              ..._liveGames.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGameCard(game, isLive: true),
              )),
              const SizedBox(height: 20),
            ],

            // Todos los juegos de hoy
            _buildSectionHeader(
              '📅 JUEGOS DE HOY',
              '${_allGames.length} partido${_allGames.length != 1 ? 's' : ''} programado${_allGames.length != 1 ? 's' : ''}',
              Colors.blue,
              const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
            ),
            const SizedBox(height: 16),

            if (_allGames.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.sports_baseball, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay juegos programados para hoy',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._allGames.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGameCard(game),
              )),

            // Juegos finalizados
            if (_finishedGames.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(
                '✅ FINALIZADOS',
                '${_finishedGames.length} partido${_finishedGames.length != 1 ? 's' : ''} terminado${_finishedGames.length != 1 ? 's' : ''}',
                Colors.green,
                const LinearGradient(colors: [Color(0xFF56AB2F), Color(0xFFA8E6CF)]),
              ),
              const SizedBox(height: 16),
              ..._finishedGames.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGameCard(game, isFinished: true),
              )),
            ],

            const SizedBox(height: 100), // Espacio para el FAB
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '${_allGames.length}', Colors.blue, Icons.sports_baseball),
          _buildStatItem('En Vivo', '${_liveGames.length}', Colors.red, Icons.circle),
          _buildStatItem('Finalizados', '${_finishedGames.length}', Colors.green, Icons.check_circle),
          _buildStatItem('Alertas', '${_notificationGames.length}', Colors.orange, Icons.notifications),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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
              title.contains('HOY') ? Icons.today : Icons.check_circle,
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getCardGradient(isLive, isFinished),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(game, isLive, isFinished),
                  Text(
                    game.formattedTime,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Equipos con logos SVG
              Row(
                children: [
                  // Equipo visitante
                  Expanded(
                    child: _buildTeamSection(
                      game.awayTeam,
                      game.score?.awayScore,
                      game.score?.awayWins == true ? Colors.green[700] : Colors.grey[600],
                      isWinner: game.score?.awayWins == true,
                    ),
                  ),
                  
                  // Marcador o VS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        if (game.score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isLive ? Colors.red[50] : isFinished ? Colors.green[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${game.score!.awayScore} - ${game.score!.homeScore}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isLive ? Colors.red[700] : isFinished ? Colors.green[700] : Colors.blue[700],
                              ),
                            ),
                          )
                        else
                          Text(
                            'VS',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                        if (isLive && game.inning != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              game.inning!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Equipo local
                  Expanded(
                    child: _buildTeamSection(
                      game.homeTeam,
                      game.score?.homeScore,
                      game.score?.homeWins == true ? Colors.green[700] : Colors.grey[600],
                      isWinner: game.score?.homeWins == true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Footer con venue y notificación
              Container(
                padding: const EdgeInsets.all(12),
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
                    if (!isFinished) _buildNotificationButton(game, hasNotification),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection(Team team, int? score, Color? scoreColor, {bool isWinner = false}) {
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasNotification ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient? _getCardGradient(bool isLive, bool isFinished) {
    if (isLive) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.red[50]!, Colors.red[100]!],
      );
    } else if (isFinished) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.green[50]!, Colors.green[100]!],
      );
    }
    return null;
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de prueba de logos (temporal)
        FloatingActionButton.small(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogoTestWidget()),
            );
          },
          backgroundColor: Colors.orange,
          heroTag: "test_logos",
          child: const Icon(Icons.image, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        // Botón principal de refresh
        FloatingActionButton(
          onPressed: _loadGames,
          backgroundColor: const Color(0xFF1e3c72),
          heroTag: "refresh",
          child: _isLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
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