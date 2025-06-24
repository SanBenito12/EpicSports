// lib/screens/optimized_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/sport_category.dart';
import '../models/mlb_game.dart';
import '../services/auth_service.dart';
import '../services/final_mlb_api_service.dart';
import '../services/game_notification_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'login_screen.dart';

class OptimizedDashboardScreen extends StatefulWidget {
  const OptimizedDashboardScreen({super.key});

  @override
  State<OptimizedDashboardScreen> createState() => _OptimizedDashboardScreenState();
}

class _OptimizedDashboardScreenState extends State<OptimizedDashboardScreen> {
  int _selectedIndex = 0;
  final List<SportCategory> _categories = sportCategories;

  // Variables para autenticación
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  // Variables para MLB API
  final FinalMLBApiService _mlbApiService = FinalMLBApiService();
  final GameNotificationService _notificationService = GameNotificationService();

  List<MLBGame> _todaysGames = [];
  List<String> _userNotificationGames = [];
  bool _isLoadingGames = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  StreamSubscription<List<String>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeData();
    _setupRefresh();
    _listenToNotificationChanges();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

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

  Future<void> _initializeData() async {
    if (!_mlbApiService.isApiKeyConfigured()) {
      setState(() {
        _errorMessage = ApiConfig.apiKeyNotConfiguredMessage;
        _isLoadingGames = false;
      });
      return;
    }

    await _loadTodaysGames();
    await _loadUserNotifications();
  }

  Future<void> _loadTodaysGames() async {
    try {
      setState(() {
        _isLoadingGames = true;
        _errorMessage = null;
      });

      final games = await _mlbApiService.getTodaysGames();

      if (mounted) {
        setState(() {
          _todaysGames = games;
          _isLoadingGames = false;
        });
        
        print('✅ ${games.length} juegos cargados en UI');
        for (var game in games) {
          print('🎮 ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation} - Score: ${game.score?.toString() ?? 'Sin marcador'}');
        }
      }
    } catch (e) {
      print('❌ Error cargando juegos: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingGames = false;
        });
      }
    }
  }

  Future<void> _loadUserNotifications() async {
    try {
      final notifications = await _notificationService.getUserNotificationGames();
      if (mounted) {
        setState(() {
          _userNotificationGames = notifications;
        });
      }
    } catch (e) {
      print('Error cargando notificaciones: $e');
    }
  }

  void _setupRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadTodaysGames();
      }
    });
  }

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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                      Text(
                        'Categorías',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategories(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Partidos MLB de Hoy',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_isLoadingGames)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[400],
            ),
            child: Center(
              child: Text(
                (_currentUser != null && _currentUser!.displayName.isNotEmpty)
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
                Text(
                  'Mexico, Puebla',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadTodaysGames,
            tooltip: 'Recargar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'clear_cache') {
                _clearCache();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Limpiar Cache'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
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

  void _clearCache() {
    _mlbApiService.clearCache();
    _loadTodaysGames();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache limpiado y datos recargados'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildGamesContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_isLoadingGames && _todaysGames.isEmpty) {
      return _buildLoadingWidget();
    }

    if (_todaysGames.isEmpty) {
      return _buildNoGamesWidget();
    }

    return Column(
      children: _todaysGames
          .map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMLBGameCard(game),
            ),
          )
          .toList(),
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
            'Error al cargar los partidos',
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando partidos...',
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
        borderRadius: BorderRadius.circular(20),
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
            'No se encontraron partidos de MLB para el día de hoy.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMLBGameCard(MLBGame game) {
    final isNotificationActive = _userNotificationGames.contains(game.id);
    final gradientColors = _getGameGradientColors(game);

    print('🔍 Construyendo card para: ${game.awayTeam.abbreviation} vs ${game.homeTeam.abbreviation}');
    print('📊 Score en card: ${game.score?.toString() ?? 'null'}');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    game.formattedDate,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!game.isLive && !game.isCompleted)
                  Text(
                    game.formattedTime,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                const Spacer(),
                _buildGameStatusBadge(game),
              ],
            ),
            const SizedBox(height: 20),

            // Equipos y marcador
            Row(
              children: [
                // Equipo visitante
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(game.awayTeam.abbreviation),
                      const SizedBox(height: 8),
                      Text(
                        game.awayTeam.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildScoreWidget(
                        score: game.score?.awayScore,
                        isWinner: game.score != null && 
                                 game.isCompleted && 
                                 game.score!.awayScore > game.score!.homeScore,
                      ),
                    ],
                  ),
                ),

                // Centro
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sports_baseball,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.isLive ? 'VIVO' : game.isCompleted ? 'FINAL' : 'VS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Equipo local
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(game.homeTeam.abbreviation),
                      const SizedBox(height: 8),
                      Text(
                        game.homeTeam.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildScoreWidget(
                        score: game.score?.homeScore,
                        isWinner: game.score != null && 
                                 game.isCompleted && 
                                 game.score!.homeScore > game.score!.awayScore,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Footer con notificación
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleGameNotification(game),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isNotificationActive
                          ? Colors.orange.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNotificationActive
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isNotificationActive ? 'Activada' : 'Notifícame',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      game.venue.location,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreWidget({int? score, bool isWinner = false}) {
    if (score == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '-',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner 
          ? Colors.green.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: isWinner 
          ? Border.all(color: Colors.white, width: 2)
          : null,
      ),
      child: Text(
        '$score',
        style: GoogleFonts.poppins(
          color: isWinner ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildGameStatusBadge(MLBGame game) {
    String text;
    Color color;
    
    if (game.isLive) {
      text = 'EN VIVO';
      color = Colors.red;
    } else if (game.isCompleted) {
      text = 'FINAL';
      color = Colors.grey[700]!;
    } else {
      text = 'PROGRAMADO';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (game.isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGameGradientColors(MLBGame game) {
    if (game.isLive) {
      return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    } else if (game.status == 'closed') {
      return [const Color(0xFF757575), const Color(0xFF424242)];
    } else {
      return [const Color(0xFF2196F3), const Color(0xFF1565C0)];
    }
  }

  void _handleLogout() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cerrar Sesión', style: GoogleFonts.poppins()),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _categories.map((category) {
        return _buildCategoryItem(category);
      }).toList(),
    );
  }

  Widget _buildCategoryItem(SportCategory category) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              _getCategoryIcon(category.name),
              size: 32,
              color: category.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.name,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
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

  Widget _buildTeamLogo(String teamAbbr) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          teamAbbr,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
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
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}