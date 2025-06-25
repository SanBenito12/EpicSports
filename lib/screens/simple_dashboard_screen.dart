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
      debugPrint('✅ Monitor de juegos iniciado');
    } catch (e) {
      debugPrint('❌ Error iniciando monitor: $e');
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
      debugPrint('🔄 Cargando juegos...');
      
      final games = await SimpleMLBService.getTodaysGames();
      
      if (mounted) {
        setState(() {
          _allGames = games;
          _liveGames = SimpleMLBService.getLiveGames(games);
          _finishedGames = SimpleMLBService.getFinishedGames(games);
          _isLoading = false;
        });

        // DEBUG: Imprimir información de los juegos
        debugPrint('✅ Juegos cargados: ${games.length} total, ${_liveGames.length} en vivo');
        debugPrint('📊 Primeros 3 juegos:');
        for (int i = 0; i < games.take(3).length; i++) {
          final game = games[i];
          debugPrint('  Juego ${i + 1}: ${game.awayTeam.name} vs ${game.homeTeam.name} - Estado: ${game.status}');
          if (game.score != null) {
            debugPrint('    Marcador: ${game.score!.awayScore} - ${game.score!.homeScore}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error cargando juegos: $e');
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔕 Notificaciones desactivadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Activar notificación
        final success = await _notificationService.addGameNotification(game);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔔 Notificaciones activadas para ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar notificación: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      appBar: AppBar(
        title: Text(
          'MLB Hoy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          // Indicador de notificaciones activas
          if (_notificationGames.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${_notificationGames.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
          
          // Menú
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text('Test Notificación'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate_game_start',
                child: Row(
                  children: [
                    Icon(Icons.play_circle),
                    SizedBox(width: 8),
                    Text('Simular Inicio de Juego'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'get_yesterday',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Juegos de Ayer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'debug_api',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Debug API Response'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'notification_stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Stats Notificaciones'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'service_info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Info Servicio'),
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
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de estado del servicio
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado del Servicio',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${_allGames.length} juegos | En vivo: ${_liveGames.length} | Terminados: ${_finishedGames.length}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          // Mostrar información de notificaciones
          if (_notificationGames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.notifications_active, size: 14, color: Colors.orange[600]),
                const SizedBox(width: 4),
                Text(
                  'Notificaciones activas: ${_notificationGames.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          // Mostrar información de marcadores
          if (_allGames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Con marcadores: ${_allGames.where((g) => g.score != null).length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[600],
              ),
            ),
          ],
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
        // Juegos en vivo
        if (_liveGames.isNotEmpty) ...[
          _buildSectionTitle('🔴 En Vivo (${_liveGames.length})'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _liveGames.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGameCard(_liveGames[index], isLive: true),
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        // Todos los juegos
        _buildSectionTitle('📅 Partidos de Hoy (${_allGames.length})'),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allGames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGameCard(_allGames[index]),
            );
          },
        ),

        const SizedBox(height: 20),

        // Juegos terminados
        if (_finishedGames.isNotEmpty) ...[
          _buildSectionTitle('✅ Terminados (${_finishedGames.length})'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _finishedGames.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGameCard(_finishedGames[index], isFinished: true),
              );
            },
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Card de juego individual - CON BOTÓN DE NOTIFICACIÓN
  Widget _buildGameCard(MLBGame game, {bool isLive = false, bool isFinished = false}) {
    Color? cardColor;
    if (isLive) cardColor = Colors.red[50];
    if (isFinished) cardColor = Colors.grey[50];

    // Verificar si tiene notificación activa
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
        // Empate o juego en vivo
        awayScoreColor = isLive ? Colors.red[700] : Colors.blue[700];
        homeScoreColor = isLive ? Colors.red[700] : Colors.blue[700];
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasNotification 
              ? Colors.orange[300]!
              : isLive 
                  ? Colors.red[200]! 
                  : isFinished 
                      ? Colors.grey[300]! 
                      : Colors.blue[200]!,
          width: hasNotification ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y botón de notificación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(game.status),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        game.formattedTime,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (game.inning != null && game.isLive)
                        Text(
                          'Inning ${game.inning}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // 🔔 BOTÓN DE NOTIFICACIÓN
                  GestureDetector(
                    onTap: () => _toggleGameNotification(game),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasNotification ? Colors.orange[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasNotification ? Colors.orange : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        hasNotification ? Icons.notifications_active : Icons.notifications_none,
                        size: 20,
                        color: hasNotification ? Colors.orange[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Equipos y marcador
          Row(
            children: [
              // Equipo visitante
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTeamColor(game.awayTeam.abbreviation),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          game.awayTeam.abbreviation.isNotEmpty 
                              ? game.awayTeam.abbreviation 
                              : 'A',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.awayTeam.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Marcador visitante
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: game.score != null ? Colors.white : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: awayScoreColor ?? Colors.grey[300]!,
                          width: game.score?.awayWins == true ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        game.score?.awayScore.toString() ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: awayScoreColor ?? Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // VS y marcador central
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.red[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VS',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLive ? Colors.red[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (game.score != null) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${game.score!.awayScore} - ${game.score!.homeScore}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.red[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Equipo local
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTeamColor(game.homeTeam.abbreviation),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          game.homeTeam.abbreviation.isNotEmpty 
                              ? game.homeTeam.abbreviation 
                              : 'H',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.homeTeam.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Marcador local
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: game.score != null ? Colors.white : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: homeScoreColor ?? Colors.grey[300]!,
                          width: game.score?.homeWins == true ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        game.score?.homeScore.toString() ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: homeScoreColor ?? Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Footer con venue y estado de notificación
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  game.venue.location,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Indicador de notificación
              if (hasNotification)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Notificaciones ON',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Indicador de marcador
              if (game.score != null && !hasNotification)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Con marcador ✅',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String abbreviation) {
    // Colores básicos por equipo
    switch (abbreviation.toUpperCase()) {
      case 'NYY': return Colors.blue[900]!;
      case 'BOS': return Colors.red[700]!;
      case 'LAD': return Colors.blue[600]!;
      case 'SF': return Colors.orange[700]!;
      case 'CHC': return Colors.blue[600]!;
      case 'NYM': return Colors.blue[700]!;
      case 'HOU': return Colors.orange[800]!;
      case 'ATL': return Colors.red[600]!;
      case 'TEX': return Colors.red[800]!;
      case 'OAK': return Colors.green[700]!;
      case 'SEA': return Colors.teal[700]!;
      default: return Colors.blue[400]!;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'inprogress':
        color = Colors.red;
        text = 'EN VIVO';
        break;
      case 'closed':
        color = Colors.grey;
        text = 'FINAL';
        break;
      default:
        color = Colors.blue;
        text = 'PROGRAMADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
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
            _errorMessage ?? 'Error desconocido',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGames,
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

  Widget _buildEmptyWidget() {
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

  /// Manejo de acciones del menú
  void _handleMenuAction(String action) {
    switch (action) {
      case 'test_connection':
        _testConnection();
        break;
      case 'test_notification':
        _testNotification();
        break;
      case 'simulate_game_start':
        _simulateGameStart();
        break;
      case 'get_yesterday':
        _getYesterdayGames();
        break;
      case 'debug_api':
        _debugApiResponse();
        break;
      case 'notification_stats':
        _showNotificationStats();
        break;
      case 'service_info':
        _showServiceInfo();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Notificación de prueba enviada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error enviando notificación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Simular inicio de juego
  Future<void> _simulateGameStart() async {
    try {
      await PushNotificationService.simulateGameStart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎮 Simulación de inicio de juego enviada'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error en simulación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Obtener partidos de ayer para testing
  Future<void> _getYesterdayGames() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Obteniendo juegos de ayer...'),
          ],
        ),
      ),
    );

    final yesterdayGames = await SimpleMLBService.getYesterdayGames();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      // Actualizar estado con juegos de ayer para testing
      setState(() {
        _allGames = yesterdayGames;
        _liveGames = SimpleMLBService.getLiveGames(yesterdayGames);
        _finishedGames = SimpleMLBService.getFinishedGames(yesterdayGames);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${yesterdayGames.length} juegos de ayer cargados'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Debug: Mostrar respuesta RAW de la API
  Future<void> _debugApiResponse() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Obteniendo respuesta RAW...'),
          ],
        ),
      ),
    );

    final rawResponse = await SimpleMLBService.getDebugApiResponse();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Debug API Response', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                rawResponse,
                style: GoogleFonts.sourceCodePro(fontSize: 10),
              ),
            ),
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
  }

  /// Mostrar estadísticas de notificaciones
  Future<void> _showNotificationStats() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Obteniendo estadísticas...'),
          ],
        ),
      ),
    );

    final stats = await _notificationService.getNotificationStats();
    final monitorStats = GameMonitorService.instance.getMonitorStats();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Estadísticas de Notificaciones', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Notificaciones del Usuario:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text('• Total activas: ${stats['total']}'),
              Text('• Programadas: ${stats['scheduled']}'),
              Text('• En vivo: ${stats['live']}'),
              Text('• Terminadas: ${stats['finished']}'),
              const SizedBox(height: 16),
              Text('🔍 Monitor de Juegos:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text('• Estado: ${monitorStats['is_monitoring'] ? 'Activo' : 'Inactivo'}'),
              Text('• Juegos monitoreados: ${monitorStats['games_being_monitored']}'),
              Text('• En vivo: ${monitorStats['live_games_count']}'),
              Text('• Notificaciones enviadas: ${monitorStats['games_already_notified']}'),
              Text('• Recordatorios enviados: ${monitorStats['reminders_sent']}'),
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
  }

  Future<void> _testConnection() async {
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

    final isConnected = await SimpleMLBService.testConnection();
    
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

  void _showServiceInfo() {
    final info = SimpleMLBService.getServiceInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Información del Servicio', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicio: ${info['service']}'),
            Text('API configurada: ${info['api_configured']}'),
            Text('Preview API Key: ${info['api_key_preview']}'),
            Text('URL base: ${info['base_url']}'),
            Text('Última llamada: ${info['last_call'] ?? 'Nunca'}'),
            Text('Intervalo mínimo: ${info['min_interval_seconds']}s'),
            const SizedBox(height: 16),
            Text(
              'Estadísticas de Juegos:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text('• Total cargados: ${_allGames.length}'),
            Text('• En vivo: ${_liveGames.length}'),
            Text('• Terminados: ${_finishedGames.length}'),
            Text('• Con marcadores: ${_allGames.where((g) => g.score != null).length}'),
            Text('• Con notificaciones: ${_notificationGames.length}'),
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
      // Limpiar notificaciones y parar monitor
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