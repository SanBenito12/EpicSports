// lib/models/simple_mlb_models.dart
import 'package:flutter/foundation.dart';

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

  factory MLBGame.fromJson(Map<String, dynamic> json) {
    try {
      // Información básica
      final gameId = json['id']?.toString() ?? '';
      final status = json['status']?.toString() ?? 'scheduled';
      final scheduled = json['scheduled']?.toString() ?? DateTime.now().toIso8601String();
      
      // Equipos
      final homeTeam = Team.fromJson(json['home'] ?? {});
      final awayTeam = Team.fromJson(json['away'] ?? {});
      
      // Venue
      final venue = Venue.fromJson(json['venue'] ?? {});
      
      // Marcadores
      GameScore? gameScore;
      if (json['home'] != null && json['away'] != null) {
        final home = json['home'] as Map<String, dynamic>;
        final away = json['away'] as Map<String, dynamic>;
        
        // Buscar runs en diferentes ubicaciones posibles
        final homeRuns = home['runs'] ?? home['score']?['runs'];
        final awayRuns = away['runs'] ?? away['score']?['runs'];
        
        if (homeRuns != null && awayRuns != null) {
          try {
            final homeScore = homeRuns is int ? homeRuns : int.parse(homeRuns.toString());
            final awayScore = awayRuns is int ? awayRuns : int.parse(awayRuns.toString());
            gameScore = GameScore(homeScore: homeScore, awayScore: awayScore);
            
            debugPrint('✅ Marcador parseado: $awayScore - $homeScore');
          } catch (e) {
            debugPrint('⚠️ Error parseando marcador: $e');
          }
        }
      }

      // Estado del juego
      final isLive = status == 'inprogress';
      final inning = json['inning']?.toString();
      final inningHalf = json['inning_half']?.toString();

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
        statusDetail: json['status_detail']?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error creando MLBGame desde JSON: $e');
      rethrow;
    }
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(scheduled);
      return "${date.day} ${_getMonthName(date.month)}";
    } catch (e) {
      return "TBD";
    }
  }

  String get formattedTime {
    try {
      final date = DateTime.parse(scheduled).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      final result = "$hour:$minute $period";
      debugPrint('⏰ Formatted time: $scheduled -> $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error formatting time: $scheduled -> $e');
      return "TBD";
    }
  }

  String get gameTitle {
    if (isLive) {
      return "MLB - EN VIVO";
    } else if (isCompleted) {
      return "MLB - FINAL";
    } else {
      return "MLB";
    }
  }

  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'closed';

  DateTime? get scheduledTime {
    try {
      return DateTime.parse(scheduled);
    } catch (e) {
      return null;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return month < months.length ? months[month] : 'UNK';
  }

  @override
  String toString() {
    return 'MLBGame(${awayTeam.abbreviation} @ ${homeTeam.abbreviation}, score: ${score?.toString() ?? 'N/A'}, status: $status)';
  }
}

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

  factory Team.fromJson(Map<String, dynamic> json) {
    // DEBUG: Imprimir datos recibidos
    debugPrint('👥 Team JSON keys: ${json.keys.toList()}');
    if (json.isNotEmpty) {
      debugPrint('👥 Team data sample: ${json.toString().substring(0, json.toString().length > 200 ? 200 : json.toString().length)}');
    }
    
    // Extraer información del equipo de diferentes estructuras posibles
    final id = json['id']?.toString() ?? '';
    
    // Buscar nombre en diferentes ubicaciones
    final name = json['name']?.toString() ?? 
                 json['full_name']?.toString() ?? 
                 json['team_name']?.toString() ?? 
                 'Unknown Team';
                 
    // Buscar market/ciudad en diferentes ubicaciones  
    final market = json['market']?.toString() ?? 
                   json['city']?.toString() ?? 
                   json['location']?.toString() ?? 
                   '';
                   
    // Buscar abreviación en diferentes ubicaciones
    final abbreviation = json['abbr']?.toString() ?? 
                        json['abbreviation']?.toString() ?? 
                        json['alias']?.toString() ??
                        json['short_name']?.toString() ??
                        '';
    
    debugPrint('👥 Team parsed: $name ($abbreviation) from $market');
    
    return Team(
      id: id,
      name: name,
      market: market,
      abbreviation: abbreviation,
    );
  }

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

  factory Venue.fromJson(Map<String, dynamic> json) {
    // DEBUG: Imprimir datos del venue
    debugPrint('🏟️ Venue JSON keys: ${json.keys.toList()}');
    if (json.isNotEmpty) {
      debugPrint('🏟️ Venue data: ${json.toString()}');
    }
    
    // Extraer información del venue
    final id = json['id']?.toString() ?? '';
    
    final name = json['name']?.toString() ?? 
                 json['venue_name']?.toString() ?? 
                 json['stadium']?.toString() ?? 
                 'Unknown Venue';
                 
    final city = json['city']?.toString() ?? 
                 json['location']?.toString() ?? 
                 '';
                 
    final state = json['state']?.toString() ?? 
                  json['province']?.toString() ?? 
                  '';
    
    debugPrint('🏟️ Venue parsed: $name in $city, $state');
    
    return Venue(
      id: id,
      name: name,
      city: city,
      state: state,
    );
  }

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