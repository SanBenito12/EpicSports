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
    GameScore? gameScore;
    
    // Buscar marcadores de diferentes formas
    if (json['home'] != null && json['away'] != null) {
      final home = json['home'] as Map<String, dynamic>;
      final away = json['away'] as Map<String, dynamic>;
      
      // Intentar obtener runs directamente
      final homeRuns = home['runs'] as int?;
      final awayRuns = away['runs'] as int?;
      
      if (homeRuns != null && awayRuns != null) {
        gameScore = GameScore(homeScore: homeRuns, awayScore: awayRuns);
      }
    }

    // Determinar estado del juego
    final status = json['status'] ?? '';
    final isLive = status == 'inprogress';

    return MLBGame(
      id: json['id'] ?? '',
      status: status,
      scheduled: json['scheduled'] ?? '',
      homeTeam: Team.fromJson(json['home'] ?? {}),
      awayTeam: Team.fromJson(json['away'] ?? {}),
      score: gameScore,
      inning: json['inning']?.toString(),
      inningHalf: json['inning_half'],
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
      return "MLB";
    }
  }

  bool get isScheduled {
    return status == 'scheduled';
  }

  bool get isCompleted {
    return status == 'closed';
  }

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
    return months[month];
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': id,
      'homeTeam': homeTeam.name,
      'awayTeam': awayTeam.name,
      'scheduled': scheduled,
      'status': status,
      'score': score != null ? {
        'homeScore': score!.homeScore,
        'awayScore': score!.awayScore,
      } : null,
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
      abbreviation: json['abbr'] ?? json['abbreviation'] ?? json['alias'] ?? '',
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
      return "Estadio";
    }
  }
}