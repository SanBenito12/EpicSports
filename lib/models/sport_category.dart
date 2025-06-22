import 'package:flutter/material.dart';

class SportCategory {
  final String name;
  final String iconPath;
  final Color color;

  SportCategory({
    required this.name,
    required this.iconPath,
    required this.color,
  });
}

// Lista de categorías predefinidas
final List<SportCategory> sportCategories = [
  SportCategory(
    name: 'Basquetbol',
    iconPath: 'assets/images/sports/basketball.png',
    color: const Color(0xFFFF6B35),
  ),
  SportCategory(
    name: 'Futbol',
    iconPath: 'assets/images/sports/soccer.jpg',
    color: const Color(0xFF4CAF50),
  ),
  SportCategory(
    name: 'Beisbol',
    iconPath: 'assets/images/sports/baseball.png',
    color: const Color(0xFF2196F3),
  ),
  SportCategory(
    name: 'Tenis',
    iconPath: 'assets/images/sports/tennis.png',
    color: const Color(0xFF8BC34A),
  ),
];
