// lib/models/mlb_game.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Debug: Imprimir la estructura del JSON para entender mejor los datos
    print('🔍 Estructura del juego JSON: ${json.keys.toList()}');
    
    GameScore? gameScore;
    
    // Intentar obtener el marcador de diferentes posibles estructuras
    if (json['home'] != null && json['away'] != null) {
      final home = json['home'] as Map<String, dynamic>;
      final away = json['away'] as Map<String, dynamic>;
      
      // Buscar marcadores en diferentes campos posibles
      int? homeScore = home['runs'] ?? home['points'] ?? home['score'];
      int? awayScore = away['runs'] ?? away['points'] ?? away['score'];
      
      if (homeScore != null && awayScore != null) {
        gameScore = GameScore(homeScore: homeScore, awayScore: awayScore);
      }
    }
    
    // Si no encontramos marcadores en home/away, buscar en summary o game
    if (gameScore == null && json['summary'] != null) {
      final summary = json['summary'] as Map<String, dynamic>;
      if (summary['home'] != null && summary['away'] != null) {
        final homeRuns = summary['home']['runs'];
        final awayRuns = summary['away']['runs'];
        if (homeRuns != null && awayRuns != null) {
          gameScore = GameScore(homeScore: homeRuns, awayScore: awayRuns);
        }
      }
    }

    // Determinar si el juego está en vivo
    final status = json['status'] ?? '';
    final isLive = status == 'inprogress' || status == 'live';

    // Obtener información del inning
    String? currentInning;
    String? inningHalf;
    
    if (json['inning'] != null) {
      currentInning = json['inning'].toString();
    } else if (json['game_inning'] != null) {
      currentInning = json['game_inning'].toString();
    }
    
    if (json['inning_half'] != null) {
      inningHalf = json['inning_half'];
    } else if (json['top_inning'] != null) {
      inningHalf = json['top_inning'] == true ? 'top' : 'bottom';
    }

    return MLBGame(
      id: json['id'] ?? '',
      status: status,
      scheduled: json['scheduled'] ?? '',
      homeTeam: Team.fromJson(json['home'] ?? {}),
      awayTeam: Team.fromJson(json['away'] ?? {}),
      score: gameScore,
      inning: currentInning,
      inningHalf: inningHalf,
      venue: Venue.fromJson(json['venue'] ?? {}),
      isLive: isLive,
      statusDetail: json['status_detail'],
    );
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
      return "$hour:$minute $period";
    } catch (e) {
      return "TBD";
    }
  }

  String get gameTitle {
    if (isLive) {
      return "MLB - EN VIVO";
    } else if (isCompleted) {
      return "MLB - FINAL";
    } else {
      return "MLB - PROGRAMADO";
    }
  }

  String get gameStatusText {
    return _getStatusText();
  }

  bool get isScheduled {
    return status == 'scheduled';
  }

  bool get isCompleted {
    return status == 'closed' || status == 'complete';
  }

  DateTime? get scheduledTime {
    try {
      return DateTime.parse(scheduled);
    } catch (e) {
      return null;
    }
  }

  String get displayScore {
    if (score != null) {
      return "${score!.awayScore} - ${score!.homeScore}";
    } else if (isCompleted) {
      return "Final";
    } else if (isLive) {
      return "En Vivo";
    } else {
      return formattedTime;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'scheduled':
        return 'Programado';
      case 'inprogress':
      case 'live':
        return 'En Vivo';
      case 'closed':
      case 'complete':
        return 'Final';
      case 'postponed':
        return 'Pospuesto';
      case 'cancelled':
        return 'Cancelado';
      case 'delayed':
        return 'Retrasado';
      case 'suspended':
        return 'Suspendido';
      default:
        return statusDetail ?? 'Programado';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return months[month];
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': id,
      'homeTeam': homeTeam.name,
      'awayTeam': awayTeam.name,
      'scheduled': scheduled,
      'status': status,
      'isNotified': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
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
    return Team(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      market: json['market'] ?? '',
      abbreviation: json['abbr'] ?? json['abbreviation'] ?? '',
    );
  }

  String get fullName => market.isNotEmpty && name.isNotEmpty 
    ? "$market $name" 
    : name.isNotEmpty 
      ? name 
      : abbreviation;
}

class GameScore {
  final int homeScore;
  final int awayScore;

  GameScore({required this.homeScore, required this.awayScore});
  
  @override
  String toString() => "$awayScore - $homeScore";
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
    return Venue(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
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
      return "Ubicación TBD";
    }
  }
}