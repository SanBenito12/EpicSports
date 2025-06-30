// lib/services/team_logo_service.dart - VERSIÓN CORREGIDA PARA CARGAR LOGOS SVG
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TeamLogoService {
  // Mapeo directo usando los códigos de equipo como nombres de archivo
  static final Map<String, Map<String, String>> _teamData = {
    // American League East
    'BAL': {'name': 'Baltimore Orioles', 'logo': 'assets/logos/teams/BAL.svg'},
    'BOS': {'name': 'Boston Red Sox', 'logo': 'assets/logos/teams/BOS.svg'},
    'NYY': {'name': 'New York Yankees', 'logo': 'assets/logos/teams/NYY.svg'},
    'TB': {'name': 'Tampa Bay Rays', 'logo': 'assets/logos/teams/TB.svg'},
    'TOR': {'name': 'Toronto Blue Jays', 'logo': 'assets/logos/teams/TOR.svg'},
    
    // American League Central
    'CWS': {'name': 'Chicago White Sox', 'logo': 'assets/logos/teams/CWS.svg'},
    'CLE': {'name': 'Cleveland Guardians', 'logo': 'assets/logos/teams/CLE.svg'},
    'DET': {'name': 'Detroit Tigers', 'logo': 'assets/logos/teams/DET.svg'},
    'KC': {'name': 'Kansas City Royals', 'logo': 'assets/logos/teams/KC.svg'},
    'MIN': {'name': 'Minnesota Twins', 'logo': 'assets/logos/teams/MIN.svg'},
    
    // American League West
    'HOU': {'name': 'Houston Astros', 'logo': 'assets/logos/teams/HOU.svg'},
    'LAA': {'name': 'Los Angeles Angels', 'logo': 'assets/logos/teams/LAA.svg'},
    'ATH': {'name': 'Oakland Athletics', 'logo': 'assets/logos/teams/ATH.svg'},
    'SEA': {'name': 'Seattle Mariners', 'logo': 'assets/logos/teams/SEA.svg'},
    'TEX': {'name': 'Texas Rangers', 'logo': 'assets/logos/teams/TEX.svg'},
    
    // National League East
    'ATL': {'name': 'Atlanta Braves', 'logo': 'assets/logos/teams/ATL.svg'},
    'MIA': {'name': 'Miami Marlins', 'logo': 'assets/logos/teams/MIA.svg'},
    'NYM': {'name': 'New York Mets', 'logo': 'assets/logos/teams/NYM.svg'},
    'PHI': {'name': 'Philadelphia Phillies', 'logo': 'assets/logos/teams/PHI.svg'},
    'WSH': {'name': 'Washington Nationals', 'logo': 'assets/logos/teams/WSH.svg'},
    
    // National League Central
    'CHC': {'name': 'Chicago Cubs', 'logo': 'assets/logos/teams/CHC.svg'},
    'CIN': {'name': 'Cincinnati Reds', 'logo': 'assets/logos/teams/CIN.svg'},
    'MIL': {'name': 'Milwaukee Brewers', 'logo': 'assets/logos/teams/MIL.svg'},
    'PIT': {'name': 'Pittsburgh Pirates', 'logo': 'assets/logos/teams/PIT.svg'},
    'STL': {'name': 'St. Louis Cardinals', 'logo': 'assets/logos/teams/STL.svg'},
    
    // National League West
    'ARI': {'name': 'Arizona Diamondbacks', 'logo': 'assets/logos/teams/ARI.svg'},
    'COL': {'name': 'Colorado Rockies', 'logo': 'assets/logos/teams/COL.svg'},
    'LAD': {'name': 'Los Angeles Dodgers', 'logo': 'assets/logos/teams/LAD.svg'},
    'SD': {'name': 'San Diego Padres', 'logo': 'assets/logos/teams/SD.svg'},
    'SF': {'name': 'San Francisco Giants', 'logo': 'assets/logos/teams/SF.svg'},
  };

  /// Obtiene el logo SVG de un equipo por su código
  static Widget getTeamLogo(String teamCode, {double size = 40.0}) {
    final normalizedCode = teamCode.toUpperCase().trim();
    final logoPath = _teamData[normalizedCode]?['logo'];
    
    debugPrint('🏈 Buscando logo para: $normalizedCode -> $logoPath');
    
    if (logoPath == null) {
      debugPrint('❌ No se encontró logo para: $normalizedCode');
      return _defaultLogo(normalizedCode, size);
    }

    return SvgPicture.asset(
      logoPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Manejar errores de carga
      placeholderBuilder: (context) {
        debugPrint('⚠️ Error cargando SVG: $logoPath');
        return _defaultLogo(normalizedCode, size);
      },
    );
  }

  /// Obtiene el nombre completo del equipo por su código
  static String getTeamName(String teamCode) {
    return _teamData[teamCode.toUpperCase()]?['name'] ?? teamCode;
  }

  /// Verifica si existe un logo para el equipo
  static bool hasLogo(String teamCode) {
    return _teamData.containsKey(teamCode.toUpperCase());
  }

  /// Logo por defecto cuando no se encuentra el SVG
  static Widget _defaultLogo(String teamCode, double size) {
    // Usar colores específicos por equipo para el fallback
    final teamColors = _getTeamColors(teamCode);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teamColors['primary']!, teamColors['secondary']!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          teamCode.length > 3 ? teamCode.substring(0, 3) : teamCode,
          style: TextStyle(
            fontSize: size * 0.22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Colores por equipo para los logos por defecto
  static Map<String, Color> _getTeamColors(String teamCode) {
    final colors = {
      // American League East
      'BAL': {'primary': const Color(0xFFDF4601), 'secondary': const Color(0xFF000000)},
      'BOS': {'primary': const Color(0xFFBD3039), 'secondary': const Color(0xFF0C2340)},
      'NYY': {'primary': const Color(0xFF132448), 'secondary': const Color(0xFFC4CED4)},
      'TB': {'primary': const Color(0xFF092C5C), 'secondary': const Color(0xFF8FBCE6)},
      'TOR': {'primary': const Color(0xFF134A8E), 'secondary': const Color(0xFFE8291C)},
      
      // American League Central
      'CWS': {'primary': const Color(0xFF27251F), 'secondary': const Color(0xFFC4CED4)},
      'CLE': {'primary': const Color(0xFFE31937), 'secondary': const Color(0xFF0C2340)},
      'DET': {'primary': const Color(0xFF0C2340), 'secondary': const Color(0xFFFA4616)},
      'KC': {'primary': const Color(0xFF004687), 'secondary': const Color(0xFFBD9B60)},
      'MIN': {'primary': const Color(0xFF002B5C), 'secondary': const Color(0xFFD31145)},
      
      // American League West
      'HOU': {'primary': const Color(0xFFEB6E1F), 'secondary': const Color(0xFF002D62)},
      'LAA': {'primary': const Color(0xFFBA0021), 'secondary': const Color(0xFF003263)},
      'OAK': {'primary': const Color(0xFF003831), 'secondary': const Color(0xFFEFB21E)},
      'SEA': {'primary': const Color(0xFF0C2C56), 'secondary': const Color(0xFF005C5C)},
      'TEX': {'primary': const Color(0xFF003278), 'secondary': const Color(0xFFC0111F)},
      
      // National League East
      'ATL': {'primary': const Color(0xFFCE1141), 'secondary': const Color(0xFF13274F)},
      'MIA': {'primary': const Color(0xFF00A3E0), 'secondary': const Color(0xFF000000)},
      'NYM': {'primary': const Color(0xFF002D72), 'secondary': const Color(0xFFFF5910)},
      'PHI': {'primary': const Color(0xFFE81828), 'secondary': const Color(0xFF002D72)},
      'WSH': {'primary': const Color(0xFFAB0003), 'secondary': const Color(0xFF14225A)},
      
      // National League Central
      'CHC': {'primary': const Color(0xFF0E3386), 'secondary': const Color(0xFFCC3433)},
      'CIN': {'primary': const Color(0xFFC6011F), 'secondary': const Color(0xFF000000)},
      'MIL': {'primary': const Color(0xFF0A2351), 'secondary': const Color(0xFFB5985A)},
      'PIT': {'primary': const Color(0xFF27251F), 'secondary': const Color(0xFFFDB827)},
      'STL': {'primary': const Color(0xFFC41E3A), 'secondary': const Color(0xFF0C2340)},
      
      // National League West
      'ARI': {'primary': const Color(0xFFA71930), 'secondary': const Color(0xFFE3D4A7)},
      'COL': {'primary': const Color(0xFF33006F), 'secondary': const Color(0xFFBAA5B4)},
      'LAD': {'primary': const Color(0xFF005A9C), 'secondary': const Color(0xFFFFFFFF)},
      'SD': {'primary': const Color(0xFF2F241C), 'secondary': const Color(0xFFFFC425)},
      'SF': {'primary': const Color(0xFFFF5000), 'secondary': const Color(0xFF000000)},
    };
    
    return colors[teamCode.toUpperCase()] ?? {
      'primary': const Color(0xFF666666), 
      'secondary': const Color(0xFF999999)
    };
  }

  /// Widget personalizado para mostrar logos con información adicional
  static Widget teamLogoWithName(
    String teamCode, {
    double logoSize = 40.0,
    bool showName = true,
    TextStyle? nameStyle,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return Column(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        getTeamLogo(teamCode, size: logoSize),
        if (showName) ...[
          const SizedBox(height: 4),
          Text(
            teamCode.toUpperCase(),
            style: nameStyle ?? const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Widget para mostrar vs entre dos equipos
  static Widget versusWidget(
    String homeTeam,
    String awayTeam, {
    double logoSize = 35.0,
    bool showTeamNames = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: teamLogoWithName(
            awayTeam,
            logoSize: logoSize,
            showName: showTeamNames,
            alignment: MainAxisAlignment.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'vs',
            style: TextStyle(
              fontSize: logoSize * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: teamLogoWithName(
            homeTeam,
            logoSize: logoSize,
            showName: showTeamNames,
            alignment: MainAxisAlignment.center,
          ),
        ),
      ],
    );
  }

  /// Widget de prueba para verificar que los logos cargan
  static Widget testLogosWidget() {
    final testTeams = ['KC', 'PIT', 'SD', 'NYY', 'LAD'];
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: testTeams.map((team) => Column(
        children: [
          getTeamLogo(team, size: 60),
          const SizedBox(height: 8),
          Text(
            team,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      )).toList(),
    );
  }
}