import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sport_category.dart';
import '../models/sport_event.dart';
// Imports para autenticación
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart'; // Asegúrate de importar tu LoginScreen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<SportCategory> _categories = sportCategories;
  final List<SportEvent> _events = upcomingEvents;

  // Variables para autenticación
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
            displayName:
                userData['displayName'] ?? user.displayName ?? 'Usuario',
            photoURL: userData['photoURL'] ?? '',
            favoriteTeams: List<String>.from(userData['favoriteTeams'] ?? []),
            favoriteSports: List<String>.from(userData['favoriteSports'] ?? []),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categorías
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

                    // Próximos Eventos
                    Text(
                      'Próximos Eventos',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de eventos usando el modelo
                    ..._events.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildEventCard(event),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Imágenes destacadas
                    Row(
                      children: [
                        Expanded(
                          child: _buildHighlightImage(
                            'assets/images/basketball1.jpg',
                            Icons.sports_basketball,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHighlightImage(
                            'assets/images/basketball2.jpg',
                            Icons.sports_basketball,
                          ),
                        ),
                      ],
                    ),
                  ],
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
          // Avatar del usuario
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image:
                  (_currentUser != null && _currentUser!.photoURL.isNotEmpty)
                      ? DecorationImage(
                        image: NetworkImage(_currentUser!.photoURL),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                (_currentUser == null || _currentUser!.photoURL.isEmpty)
                    ? Center(
                      child: Text(
                        (_currentUser != null &&
                                _currentUser!.displayName.isNotEmpty)
                            ? _currentUser!.displayName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // Nombre y ubicación
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
                    Text(
                      'Mexico, Puebla',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          // Íconos de acción
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Mi Perfil'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Configuración'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Cerrar Sesión'),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  // Función para cerrar sesión
  void _handleLogout() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
      children:
          _categories.map((category) {
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
            child: Image.asset(
              category.iconPath,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                // Si no encuentra la imagen, muestra un ícono
                return Icon(
                  _getCategoryIcon(category.name),
                  size: 32,
                  color: category.color,
                );
              },
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

  Widget _buildEventCard(SportEvent event) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: event.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: event.gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Contenido de la tarjeta
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha y hora
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.date,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Equipos
                Row(
                  children: [
                    // Equipo 1
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamLogo(event.team1Logo),
                          const SizedBox(height: 8),
                          Text(
                            event.team1Name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // VS
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'VS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Equipo 2
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamLogo(event.team2Logo),
                          const SizedBox(height: 8),
                          Text(
                            event.team2Name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notificación y título
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Notifícame',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.gameTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Ubicación y asistentes
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Avatares de asistentes
                    ...event.attendees.asMap().entries.map((entry) {
                      return Transform.translate(
                        offset: Offset(-8.0 * entry.key, 0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    }),

                    Text(
                      event.additionalAttendees,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hashtag
          Positioned(
            right: 20,
            top: 20,
            child: Text(
              event.hashtag,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Botón Ver Todos
          Positioned(
            right: 20,
            bottom: 20,
            child: Row(
              children: [
                Text(
                  'Ver Todos',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String logoPath) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          logoPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Si no encuentra la imagen, muestra un ícono
            return const Icon(Icons.sports, color: Colors.white, size: 30);
          },
        ),
      ),
    );
  }

  Widget _buildHighlightImage(String imagePath, IconData icon) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          onError: (error, stackTrace) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 40)),
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
