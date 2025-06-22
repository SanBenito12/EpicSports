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
  });

  factory MLBGame.fromJson(Map<String, dynamic> json) {
    return MLBGame(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      scheduled: json['scheduled'] ?? '',
      homeTeam: Team.fromJson(json['home'] ?? {}),
      awayTeam: Team.fromJson(json['away'] ?? {}),
      score:
          json['home_points'] != null && json['away_points'] != null
              ? GameScore(
                homeScore: json['home_points'],
                awayScore: json['away_points'],
              )
              : null,
      inning: json['inning']?.toString(),
      inningHalf: json['inning_half'],
      venue: Venue.fromJson(json['venue'] ?? {}),
      isLive: json['status'] == 'inprogress',
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
      final date = DateTime.parse(scheduled);
      final hour =
          date.hour > 12
              ? date.hour - 12
              : date.hour == 0
              ? 12
              : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return "$hour:$minute $period";
    } catch (e) {
      return "TBD";
    }
  }

  String get gameTitle {
    return "MLB ${_getStatusText()}";
  }

  String get gameStatusText {
    return _getStatusText();
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

  String _getStatusText() {
    switch (status) {
      case 'scheduled':
        return 'Programado';
      case 'inprogress':
        return 'En Vivo';
      case 'closed':
        return 'Finalizado';
      case 'postponed':
        return 'Pospuesto';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Programado';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
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
      abbreviation: json['abbr'] ?? '',
    );
  }

  String get fullName => "$market $name";
}

class GameScore {
  final int homeScore;
  final int awayScore;

  GameScore({required this.homeScore, required this.awayScore});
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

  String get location => "$city, $state";
}
