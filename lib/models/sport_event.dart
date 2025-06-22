import 'package:flutter/material.dart';

class SportEvent {
  final String date;
  final String time;
  final String team1Name;
  final String team1Logo;
  final String team2Name;
  final String team2Logo;
  final String gameTitle;
  final String location;
  final List<String> attendees;
  final String additionalAttendees;
  final String hashtag;
  final List<Color> gradientColors;
  final bool isNotificationEnabled;

  SportEvent({
    required this.date,
    required this.time,
    required this.team1Name,
    required this.team1Logo,
    required this.team2Name,
    required this.team2Logo,
    required this.gameTitle,
    required this.location,
    required this.attendees,
    required this.additionalAttendees,
    required this.hashtag,
    required this.gradientColors,
    this.isNotificationEnabled = false,
  });
}

// Lista de eventos de ejemplo
final List<SportEvent> upcomingEvents = [
  SportEvent(
    date: '20 MAY',
    time: '7:30PM',
    team1Name: 'OKLAHOMA CITY THUNDER',
    team1Logo: 'assets/logos/teams/thunder.png',
    team2Name: 'MINNESOTA TIMBERWOLVES',
    team2Logo: 'assets/logos/teams/timberwolves.png',
    gameTitle: 'NBA PLAYOFFS',
    location: 'Oklahoma City',
    attendees: [
      'https://i.pravatar.cc/150?img=1',
      'https://i.pravatar.cc/150?img=2',
      'https://i.pravatar.cc/150?img=3',
    ],
    additionalAttendees: '+170 otros',
    hashtag: '#BACKTOBACK',
    gradientColors: [const Color(0xFF6B5B95), const Color(0xFF3D5A80)],
  ),
  SportEvent(
    date: '27 MAY',
    time: '6:05PM',
    team1Name: 'TORONTO BLUE JAYS',
    team1Logo: 'assets/logos/teams/blue_jays.png',
    team2Name: 'TEXAS RANGERS',
    team2Logo: 'assets/logos/teams/rangers.png',
    gameTitle: 'MLB',
    location: 'Oklahoma City',
    attendees: [
      'https://i.pravatar.cc/150?img=4',
      'https://i.pravatar.cc/150?img=5',
      'https://i.pravatar.cc/150?img=6',
    ],
    additionalAttendees: '+17 otros',
    hashtag: '#GAMEOFDAY',
    gradientColors: [const Color(0xFF134E8B), const Color(0xFFCE1141)],
  ),
];
