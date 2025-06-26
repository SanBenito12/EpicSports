// lib/services/team_logo_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TeamLogoService {
  // Mapeo de abreviaciones de equipos a IDs oficiales de MLB
  static const Map<String, String> _teamIds = {
    // Liga Americana Este
    'BAL': '110', // Baltimore Orioles
    'BOS': '111', // Boston Red Sox
    'NYY': '147', // New York Yankees
    'TB': '139',  // Tampa Bay Rays
    'TOR': '141', // Toronto Blue Jays
    
    // Liga Americana Central
    'CHW': '145', // Chicago White Sox
    'CLE': '114', // Cleveland Guardians
    'DET': '116', // Detroit Tigers
    'KC': '118',  // Kansas City Royals
    'MIN': '142', // Minnesota Twins
    
    // Liga Americana Oeste
    'HOU': '117', // Houston Astros
    'LAA': '108', // Los Angeles Angels
    'OAK': '133', // Oakland Athletics
    'SEA': '136', // Seattle Mariners
    'TEX': '140', // Texas Rangers
    
    // Liga Nacional Este
    'ATL': '144', // Atlanta Braves
    'MIA': '146', // Miami Marlins
    'NYM': '121', // New York Mets
    'PHI': '143', // Philadelphia Phillies
    'WSH': '120', // Washington Nationals
    
    // Liga Nacional Central
    'CHC': '112', // Chicago Cubs
    'CIN': '113', // Cincinnati Reds
    'MIL': '158', // Milwaukee Brewers
    'PIT': '134', // Pittsburgh Pirates
    'STL': '138', // St. Louis Cardinals
    
    // Liga Nacional Oeste
    'ARI': '109', // Arizona Diamondbacks
    'COL': '115', // Colorado Rockies
    'LAD': '119', // Los Angeles Dodgers
    'SD': '135',  // San Diego Padres
    'SF': '137',  // San Francisco Giants
  };

  // Colores principales por equipo (para fallback)
  static const Map<String, Color> _teamColors = {
    'BAL': Color(0xFFDF4601), // Orioles Orange
    'BOS': Color(0xFFBD3039), // Red Sox Red
    'NYY': Color(0xFF1F2A44), // Yankees Navy
    'TB': Color(0xFF092C5C),  // Rays Navy
    'TOR': Color(0xFF134A8E), // Blue Jays Blue
    
    'CHW': Color(0xFF27251F), // White Sox Black
    'CLE': Color(0xFFE31937), // Guardians Red
    'DET': Color(0xFF0C2340), // Tigers Navy
    'KC': Color(0xFF004687),  // Royals Blue
    'MIN': Color(0xFF002B5C), // Twins Navy
    
    'HOU': Color(0xFFEB6E1F), // Astros Orange
    'LAA': Color(0xFFBA0021), // Angels Red
    'OAK': Color(0xFF003831), // Athletics Green
    'SEA': Color(0xFF0C2C56), // Mariners Navy
    'TEX': Color(0xFFC0111F), // Rangers Red
    
    'ATL': Color(0xFFCE1141), // Braves Red
    'MIA': Color(0xFF00A3E0), // Marlins Blue
    'NYM': Color(0xFF002D72), // Mets Blue
    'PHI': Color(0xFFE81828), // Phillies Red
    'WSH': Color(0xFFAB0003), // Nationals Red
    
    'CHC': Color(0xFF0E3386), // Cubs Blue
    'CIN': Color(0xFFC6011F), // Reds Red
    'MIL': Color(0xFF0A2351), // Brewers Navy
    'PIT': Color(0xFFFDB827), // Pirates Gold
    'STL': Color(0xFFC41E3A), // Cardinals Red
    
    'ARI': Color(0xFFA71930), // Diamondbacks Red
    'COL': Color(0xFF33006F), // Rockies Purple
    'LAD': Color(0xFF005A9C), // Dodgers Blue
    'SD': Color(0xFF2F241D),  // Padres Brown
    'SF': Color(0xFFFF6600),  // Giants Orange
  };

  /// Obtener URL del logo SVG para un equipo
  static String? getTeamLogoUrl(String abbreviation) {
    final teamId = _teamIds[abbreviation.toUpperCase()];
    if (teamId != null) {
      return 'https://www.mlbstatic.com/team-logos/$teamId.svg';
    }
    return null;
  }

  /// Widget de logo de equipo con fallback
  static Widget buildTeamLogo({
    required String abbreviation,
    double size = 50,
    bool showFallback = true,
  }) {
    final logoUrl = getTeamLogoUrl(abbreviation);
    
    if (logoUrl != null) {
      return SizedBox(
        width: size,
        height: size,
        child: FutureBuilder(
          future: _loadSvgLogo(logoUrl, size),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildFallbackLogo(
                abbreviation, 
                size, 
                showPlaceholder: true,
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              debugPrint('❌ Error cargando logo para $abbreviation: ${snapshot.error}');
              return showFallback 
                  ? _buildFallbackLogo(abbreviation, size)
                  : const SizedBox.shrink();
            } else {
              return snapshot.data!;
            }
          },
        ),
      );
    }
    
    // Si no hay URL disponible, mostrar fallback
    return showFallback 
        ? _buildFallbackLogo(abbreviation, size)
        : const SizedBox.shrink();
  }

  /// Cargar logo SVG de forma asíncrona
  static Future<Widget> _loadSvgLogo(String url, double size) async {
    try {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Error loading SVG: $e');
    }
  }

  /// Logo de fallback con diseño circular y colores del equipo
  static Widget _buildFallbackLogo(
    String abbreviation, 
    double size, {
    bool showPlaceholder = false,
  }) {
    final color = _teamColors[abbreviation.toUpperCase()] ?? const Color(0xFF1976D2);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: size * 0.2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: showPlaceholder
            ? SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                abbreviation.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: size * 0.02,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  /// Obtener color principal del equipo
  static Color getTeamColor(String abbreviation) {
    return _teamColors[abbreviation.toUpperCase()] ?? const Color(0xFF1976D2);
  }

  /// Verificar si un equipo existe en nuestro mapeo
  static bool isValidTeam(String abbreviation) {
    return _teamIds.containsKey(abbreviation.toUpperCase());
  }

  /// Obtener lista de todos los equipos disponibles
  static List<String> getAllTeams() {
    return _teamIds.keys.toList()..sort();
  }

  /// Obtener nombre completo del equipo (opcional, para futuro uso)
  static String getTeamName(String abbreviation) {
    const teamNames = {
      'BAL': 'Baltimore Orioles',
      'BOS': 'Boston Red Sox',
      'NYY': 'New York Yankees',
      'TB': 'Tampa Bay Rays',
      'TOR': 'Toronto Blue Jays',
      
      'CHW': 'Chicago White Sox',
      'CLE': 'Cleveland Guardians',
      'DET': 'Detroit Tigers',
      'KC': 'Kansas City Royals',
      'MIN': 'Minnesota Twins',
      
      'HOU': 'Houston Astros',
      'LAA': 'Los Angeles Angels',
      'OAK': 'Oakland Athletics',
      'SEA': 'Seattle Mariners',
      'TEX': 'Texas Rangers',
      
      'ATL': 'Atlanta Braves',
      'MIA': 'Miami Marlins',
      'NYM': 'New York Mets',
      'PHI': 'Philadelphia Phillies',
      'WSH': 'Washington Nationals',
      
      'CHC': 'Chicago Cubs',
      'CIN': 'Cincinnati Reds',
      'MIL': 'Milwaukee Brewers',
      'PIT': 'Pittsburgh Pirates',
      'STL': 'St. Louis Cardinals',
      
      'ARI': 'Arizona Diamondbacks',
      'COL': 'Colorado Rockies',
      'LAD': 'Los Angeles Dodgers',
      'SD': 'San Diego Padres',
      'SF': 'San Francisco Giants',
    };
    
    return teamNames[abbreviation.toUpperCase()] ?? abbreviation;
  }

  /// Cache para logos cargados (opcional, para optimización)
  static final Map<String, Widget> _logoCache = {};
  
  /// Versión con cache para mejor rendimiento
  static Widget buildCachedTeamLogo({
    required String abbreviation,
    double size = 50,
    bool showFallback = true,
  }) {
    final cacheKey = '${abbreviation}_$size';
    
    if (_logoCache.containsKey(cacheKey)) {
      return _logoCache[cacheKey]!;
    }
    
    final logo = buildTeamLogo(
      abbreviation: abbreviation,
      size: size,
      showFallback: showFallback,
    );
    
    _logoCache[cacheKey] = logo;
    return logo;
  }

  /// Limpiar cache de logos
  static void clearCache() {
    _logoCache.clear();
  }

  /// Información de debug del servicio
  static Map<String, dynamic> getServiceInfo() {
    return {
      'total_teams': _teamIds.length,
      'base_url': 'https://www.mlbstatic.com/team-logos/',
      'cache_size': _logoCache.length,
      'teams_available': _teamIds.keys.toList()..sort(),
    };
  }
}