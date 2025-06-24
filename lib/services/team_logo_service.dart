// lib/services/team_logo_service.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamLogoService {
  // Mapeo básico de abreviaciones a colores principales
  static const Map<String, Color> _teamColors = {
    // Liga Americana - Este
    'BAL': Color(0xFFDF4601), // Baltimore Orioles - Naranja
    'BOS': Color(0xFFBD3039), // Boston Red Sox - Rojo
    'NYY': Color(0xFF132448), // New York Yankees - Azul marino
    'TB': Color(0xFF092C5C),  // Tampa Bay Rays - Azul
    'TOR': Color(0xFF134A8E), // Toronto Blue Jays - Azul

    // Liga Americana - Central
    'CWS': Color(0xFF27251F), // Chicago White Sox - Negro
    'CLE': Color(0xFFE31937), // Cleveland Guardians - Rojo
    'DET': Color(0xFF0C2340), // Detroit Tigers - Azul marino
    'KC': Color(0xFF004687),  // Kansas City Royals - Azul real
    'MIN': Color(0xFF002B5C), // Minnesota Twins - Azul marino

    // Liga Americana - Oeste
    'HOU': Color(0xFFEB6E1F), // Houston Astros - Naranja
    'LAA': Color(0xFFBA0021), // Los Angeles Angels - Rojo
    'OAK': Color(0xFF003831), // Oakland Athletics - Verde
    'SEA': Color(0xFF0C2C56), // Seattle Mariners - Azul marino
    'TEX': Color(0xFF003278), // Texas Rangers - Azul

    // Liga Nacional - Este
    'ATL': Color(0xFFCE1141), // Atlanta Braves - Rojo
    'MIA': Color(0xFF00A3E0), // Miami Marlins - Azul
    'NYM': Color(0xFF002D72), // New York Mets - Azul
    'PHI': Color(0xFFE81828), // Philadelphia Phillies - Rojo
    'WSH': Color(0xFFAB0003), // Washington Nationals - Rojo

    // Liga Nacional - Central
    'CHC': Color(0xFF0E3386), // Chicago Cubs - Azul
    'CIN': Color(0xFFC6011F), // Cincinnati Reds - Rojo
    'MIL': Color(0xFF12284B), // Milwaukee Brewers - Azul marino
    'PIT': Color(0xFFFDB827), // Pittsburgh Pirates - Amarillo
    'STL': Color(0xFFC41E3A), // St. Louis Cardinals - Rojo

    // Liga Nacional - Oeste
    'ARI': Color(0xFFA71930), // Arizona Diamondbacks - Rojo granate
    'COL': Color(0xFF33006F), // Colorado Rockies - Púrpura
    'LAD': Color(0xFF005A9C), // Los Angeles Dodgers - Azul
    'SD': Color(0xFF2F241D),  // San Diego Padres - Marrón
    'SF': Color(0xFFDF4601),  // San Francisco Giants - Naranja
  };

  /// Obtener color del equipo
  static Color getTeamColor(String teamAbbreviation) {
    return _teamColors[teamAbbreviation.toUpperCase()] ?? Colors.blue;
  }

  /// Widget simple para el logo del equipo (solo abreviación con colores)
  static Widget buildTeamLogo({
    required String teamAbbreviation,
    double size = 50,
    double fontSize = 12,
  }) {
    // Validación y limpieza de la abreviación
    final cleanAbbr = teamAbbreviation.trim().toUpperCase();
    if (cleanAbbr.isEmpty) {
      return _buildFallbackLogo(size, fontSize, 'TBD');
    }
    
    final color = getTeamColor(cleanAbbr);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          cleanAbbr.length > 3 ? cleanAbbr.substring(0, 3) : cleanAbbr,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget de fallback para casos de error
  static Widget _buildFallbackLogo(double size, double fontSize, String text) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Widget para el logo pequeño (para listas)
  static Widget buildSmallTeamLogo(String teamAbbreviation) {
    return buildTeamLogo(
      teamAbbreviation: teamAbbreviation,
      size: 40,
      fontSize: 10,
    );
  }

  /// Widget para el logo mediano (para cards)
  static Widget buildMediumTeamLogo(String teamAbbreviation) {
    return buildTeamLogo(
      teamAbbreviation: teamAbbreviation,
      size: 50,
      fontSize: 12,
    );
  }

  /// Widget para el logo grande (para detalles)
  static Widget buildLargeTeamLogo(String teamAbbreviation) {
    return buildTeamLogo(
      teamAbbreviation: teamAbbreviation,
      size: 70,
      fontSize: 16,
    );
  }
}