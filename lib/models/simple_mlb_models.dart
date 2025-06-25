// lib/models/simple_mlb_models.dart - VERSIÓN CORREGIDA
import 'package:flutter/foundation.dart';

/// 🎮 MODELO PRINCIPAL DEL JUEGO MLB
class MLBGame {
  final String id;
  final String status;
  final String scheduled;
  final Team homeTeam;
  final Team awayTeam;
  final GameScore? score;
  final String? inning;
  final String? inningHalf;
  final Venue venue;
  final bool isLive;
  final String? statusDetail;

  MLBGame({
    required this.id,
    required this.status,
    required this.scheduled,
    required this.homeTeam,
    required this.awayTeam,
    this.score,
    this.inning,
    this.inningHalf,
    required this.venue,
    required this.isLive,
    this.statusDetail,
  });

  /// 🏗️ FACTORY CONSTRUCTOR CON PARSING ROBUSTO
  factory MLBGame.fromJson(Map<String, dynamic> json) {
    try {
      // 📋 INFORMACIÓN BÁSICA CON VALORES SEGUROS
      final gameId = _getSafeStringNonNull(json, ['id', 'game_id'], 'game_${DateTime.now().millisecondsSinceEpoch}');
      final status = _getSafeStringNonNull(json, ['status', 'game_status'], 'scheduled').toLowerCase();
      final scheduled = _getSafeStringNonNull(json, ['scheduled', 'start_time', 'game_time'], DateTime.now().toIso8601String());
      
      debugPrint('🎮 Parseando juego: $gameId, estado: $status');
      
      // 👥 EQUIPOS CON PARSING DEFENSIVO
      final homeTeam = _parseTeamSafely(json, 'home', 'Home Team', 'HOM');
      final awayTeam = _parseTeamSafely(json, 'away', 'Away Team', 'AWY');
      
      // 🏟️ VENUE CON PARSING DEFENSIVO
      final venue = _parseVenueSafely(json);
      
      // 📊 MARCADORES (OPCIONAL)
      final gameScore = _parseScoreSafely(json, homeTeam, awayTeam);
      
      // 🔴 ESTADO DEL JUEGO
      final isLive = _isGameLive(status);
      final inning = _getSafeString(json, ['inning', 'current_inning'], null);
      final inningHalf = _getSafeString(json, ['inning_half', 'inning_period'], null);

      return MLBGame(
        id: gameId,
        status: status,
        scheduled: scheduled,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        score: gameScore,
        inning: inning,
        inningHalf: inningHalf,
        venue: venue,
        isLive: isLive,
        statusDetail: _getSafeString(json, ['status_detail', 'game_status_detail'], null),
      );
    } catch (e) {
      debugPrint('❌ Error creando MLBGame desde JSON: $e');
      debugPrint('📊 JSON problemático: ${json.toString()}');
      rethrow;
    }
  }

  /// 📅 FECHA FORMATEADA
  String get formattedDate {
    try {
      final date = DateTime.parse(scheduled);
      return "${date.day} ${_getMonthName(date.month)}";
    } catch (e) {
      return "TBD";
    }
  }

  /// ⏰ HORA FORMATEADA
  String get formattedTime {
    try {
      final date = DateTime.parse(scheduled).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return "$hour:$minute $period";
    } catch (e) {
      debugPrint('❌ Error formatting time: $scheduled -> $e');
      return "TBD";
    }
  }

  /// 🏆 TÍTULO DEL JUEGO
  String get gameTitle {
    if (isLive) {
      return "MLB - EN VIVO";
    } else if (isCompleted) {
      return "MLB - FINAL";
    } else {
      return "MLB";
    }
  }

  /// 📊 PROPIEDADES DE ESTADO
  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'closed' || status == 'complete';

  DateTime? get scheduledTime {
    try {
      return DateTime.parse(scheduled);
    } catch (e) {
      return null;
    }
  }

  /// 🗓️ NOMBRES DE MESES
  String _getMonthName(int month) {
    const months = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return month < months.length ? months[month] : 'UNK';
  }

  @override
  String toString() {
    return 'MLBGame(${awayTeam.abbreviation} @ ${homeTeam.abbreviation}, score: ${score?.toString() ?? 'N/A'}, status: $status)';
  }

  // 🛠️ MÉTODOS HELPER ESTÁTICOS

  /// 📝 OBTENER STRING SEGURO DE MÚLTIPLES UBICACIONES
  static String? _getSafeString(Map<String, dynamic> json, List<String> keys, String? defaultValue) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return defaultValue;
  }

  /// 📝 OBTENER STRING NO NULO DE MÚLTIPLES UBICACIONES
  static String _getSafeStringNonNull(Map<String, dynamic> json, List<String> keys, String defaultValue) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return defaultValue;
  }

  /// 👥 PARSEAR EQUIPO DE MANERA SEGURA
  static Team _parseTeamSafely(Map<String, dynamic> json, String teamKey, String defaultName, String defaultAbbr) {
    try {
      final teamData = json[teamKey] as Map<String, dynamic>? ?? {};
      
      final id = _getSafeStringNonNull(teamData, ['id', 'team_id'], '${teamKey}_team');
      final name = _getSafeStringNonNull(teamData, ['name', 'full_name', 'team_name'], defaultName);
      final market = _getSafeStringNonNull(teamData, ['market', 'city', 'location'], '');
      final abbreviation = _getSafeStringNonNull(teamData, ['abbr', 'abbreviation', 'alias', 'short_name'], defaultAbbr);
      
      debugPrint('👥 $teamKey team: $name ($abbreviation) from $market');
      
      return Team(
        id: id,
        name: name,
        market: market,
        abbreviation: abbreviation,
      );
    } catch (e) {
      debugPrint('❌ Error parseando equipo $teamKey: $e');
      return Team(
        id: '${teamKey}_team',
        name: defaultName,
        market: '',
        abbreviation: defaultAbbr,
      );
    }
  }

  /// 🏟️ PARSEAR VENUE DE MANERA SEGURA
  static Venue _parseVenueSafely(Map<String, dynamic> json) {
    try {
      final venueData = json['venue'] as Map<String, dynamic>? ?? {};
      
      final id = _getSafeStringNonNull(venueData, ['id', 'venue_id'], 'venue_unknown');
      final name = _getSafeStringNonNull(venueData, ['name', 'venue_name', 'stadium'], 'Stadium');
      final city = _getSafeStringNonNull(venueData, ['city', 'location'], 'City');
      final state = _getSafeStringNonNull(venueData, ['state', 'province'], '');
      
      debugPrint('🏟️ Venue: $name in $city, $state');
      
      return Venue(
        id: id,
        name: name,
        city: city,
        state: state,
      );
    } catch (e) {
      debugPrint('❌ Error parseando venue: $e');
      return Venue(
        id: 'venue_unknown',
        name: 'Stadium',
        city: 'City',
        state: '',
      );
    }
  }

  /// 📊 PARSEAR MARCADOR DE MANERA SEGURA
  static GameScore? _parseScoreSafely(Map<String, dynamic> json, Team homeTeam, Team awayTeam) {
    try {
      // 🔍 BUSCAR MARCADORES EN MÚLTIPLES UBICACIONES
      final homeData = json['home'] as Map<String, dynamic>? ?? {};
      final awayData = json['away'] as Map<String, dynamic>? ?? {};
      
      // Intentar diferentes ubicaciones para los runs
      final homeRuns = homeData['runs'] ??
                      homeData['score']?['runs'] ??
                      homeData['scoring']?['runs'] ??
                      json['scoring']?['home']?['runs'] ??
                      json['score']?['home'];
                      
      final awayRuns = awayData['runs'] ??
                      awayData['score']?['runs'] ??
                      awayData['scoring']?['runs'] ??
                      json['scoring']?['away']?['runs'] ??
                      json['score']?['away'];
      
      debugPrint('🎯 Buscando marcadores: home=$homeRuns, away=$awayRuns');
      
      if (homeRuns != null && awayRuns != null) {
        final homeScore = homeRuns is int ? homeRuns : int.tryParse(homeRuns.toString()) ?? 0;
        final awayScore = awayRuns is int ? awayRuns : int.tryParse(awayRuns.toString()) ?? 0;
        
        final score = GameScore(homeScore: homeScore, awayScore: awayScore);
        debugPrint('📊 Marcador parseado: ${awayTeam.abbreviation} $awayScore - $homeScore ${homeTeam.abbreviation}');
        return score;
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando marcador (puede ser normal en juegos programados): $e');
    }
    
    return null;
  }

  /// 🔴 VERIFICAR SI EL JUEGO ESTÁ EN VIVO
  static bool _isGameLive(String status) {
    final liveStatuses = ['inprogress', 'in_progress', 'live', 'playing'];
    return liveStatuses.contains(status.toLowerCase());
  }
}

/// 👥 MODELO DEL EQUIPO
class Team {
  final String id;
  final String name;
  final String market;
  final String abbreviation;

  Team({
    required this.id,
    required this.name,
    required this.market,
    required this.abbreviation,
  });

  /// 📝 NOMBRE COMPLETO
  String get fullName {
    if (market.isNotEmpty && name.isNotEmpty) {
      return "$market $name";
    } else if (name.isNotEmpty) {
      return name;
    } else if (abbreviation.isNotEmpty) {
      return abbreviation;
    } else {
      return "Equipo";
    }
  }

  @override
  String toString() => fullName;
}

/// 📊 MODELO DEL MARCADOR
class GameScore {
  final int homeScore;
  final int awayScore;

  GameScore({required this.homeScore, required this.awayScore});
  
  @override
  String toString() => "$awayScore - $homeScore";

  bool get isTied => homeScore == awayScore;
  bool get homeWins => homeScore > awayScore;
  bool get awayWins => awayScore > homeScore;
}

/// 🏟️ MODELO DEL VENUE
class Venue {
  final String id;
  final String name;
  final String city;
  final String state;

  Venue({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
  });

  /// 📍 UBICACIÓN FORMATEADA
  String get location {
    if (city.isNotEmpty && state.isNotEmpty) {
      return "$city, $state";
    } else if (city.isNotEmpty) {
      return city;
    } else if (name.isNotEmpty) {
      return name;
    } else {
      return "Estadio";
    }
  }

  @override
  String toString() => location;
}