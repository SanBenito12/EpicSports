// lib/widgets/game_widgets.dart - CORREGIDO para usar el modelo MLBGame correcto
import 'package:flutter/material.dart';
import '../models/simple_mlb_models.dart';
import '../services/team_logo_service.dart';

/// Widget principal para lista de partidos
class TodayMatchesWidget extends StatelessWidget {
  final List<MLBGame> games;
  final Function(MLBGame) onGameTap;
  final Function(MLBGame) onNotificationToggle;
  final List<String> notificationGames;

  const TodayMatchesWidget({
    super.key,
    required this.games,
    required this.onGameTap,
    required this.onNotificationToggle,
    required this.notificationGames,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No hay juegos programados para hoy',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final isNotificationEnabled = notificationGames.contains(game.id);
        
        return GameCard(
          game: game,
          isNotificationEnabled: isNotificationEnabled,
          onTap: () => onGameTap(game),
          onNotificationToggle: () => onNotificationToggle(game),
        );
      },
    );
  }
}

/// Widget para partidos en vivo
class LiveScoresWidget extends StatelessWidget {
  final List<MLBGame> liveGames;

  const LiveScoresWidget({
    super.key,
    required this.liveGames,
  });

  @override
  Widget build(BuildContext context) {
    if (liveGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '🔴 EN VIVO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: liveGames.length,
          itemBuilder: (context, index) {
            final game = liveGames[index];
            return GameCard(
              game: game,
              isLive: true,
              onTap: () {}, // Acción para juegos en vivo
              onNotificationToggle: () {},
            );
          },
        ),
      ],
    );
  }
}

/// Widget para partidos terminados
class FinishedScoresWidget extends StatelessWidget {
  final List<MLBGame> finishedGames;

  const FinishedScoresWidget({
    super.key,
    required this.finishedGames,
  });

  @override
  Widget build(BuildContext context) {
    if (finishedGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '✅ FINALIZADOS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: finishedGames.length,
          itemBuilder: (context, index) {
            final game = finishedGames[index];
            return GameCard(
              game: game,
              isFinished: true,
              onTap: () {}, // Acción para juegos terminados
              onNotificationToggle: () {},
            );
          },
        ),
      ],
    );
  }
}

/// Tarjeta individual de juego con logos SVG
class GameCard extends StatelessWidget {
  final MLBGame game;
  final bool isNotificationEnabled;
  final bool isLive;
  final bool isFinished;
  final VoidCallback onTap;
  final VoidCallback onNotificationToggle;

  const GameCard({
    super.key,
    required this.game,
    this.isNotificationEnabled = false,
    this.isLive = false,
    this.isFinished = false,
    required this.onTap,
    required this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getCardGradient(),
          ),
          child: Column(
            children: [
              // Estado del juego
              _buildGameStatus(),
              const SizedBox(height: 12),
              
              // Equipos con logos SVG
              _buildTeamsSection(),
              const SizedBox(height: 12),
              
              // Información adicional
              _buildGameInfo(),
              
              // Botón de notificación (solo para juegos programados)
              if (!isLive && !isFinished) _buildNotificationButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradiente según el estado del juego
  LinearGradient? _getCardGradient() {
    if (isLive) {
      return const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isFinished) {
      return const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF6FDDDD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null; // Sin gradiente para juegos programados
  }

  /// Estado del juego
  Widget _buildGameStatus() {
    String status;
    Color statusColor;
    
    if (isLive || game.isLive) {
      status = 'EN VIVO';
      statusColor = Colors.red;
    } else if (isFinished || game.isCompleted) {
      status = 'FINAL';
      statusColor = Colors.green;
    } else {
      status = 'PROGRAMADO';
      statusColor = Colors.blue;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          game.venue.name,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Sección de equipos con logos SVG
  Widget _buildTeamsSection() {
    return Row(
      children: [
        // Equipo visitante
        Expanded(
          child: _buildTeam(
            teamCode: game.awayTeam.abbreviation,
            teamName: game.awayTeam.name,
            score: game.score?.awayScore ?? 0,
            isAway: true,
          ),
        ),
        
        // VS o marcador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (isLive || isFinished || game.score != null)
                Text(
                  '${game.score?.awayScore ?? 0} - ${game.score?.homeScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              if (isLive && game.inning?.isNotEmpty == true)
                Text(
                  game.inning!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        
        // Equipo local
        Expanded(
          child: _buildTeam(
            teamCode: game.homeTeam.abbreviation,
            teamName: game.homeTeam.name,
            score: game.score?.homeScore ?? 0,
            isAway: false,
          ),
        ),
      ],
    );
  }

  /// Widget individual de equipo con logo SVG
  Widget _buildTeam({
    required String teamCode,
    required String teamName,
    required int score,
    required bool isAway,
  }) {
    return Column(
      children: [
        // Logo SVG del equipo
        TeamLogoService.getTeamLogo(teamCode, size: 50),
        const SizedBox(height: 8),
        
        // Código del equipo
        Text(
          teamCode,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Nombre del equipo (abreviado)
        Text(
          teamName.length > 12 ? '${teamName.substring(0, 12)}...' : teamName,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Información adicional del juego
  Widget _buildGameInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              game.formattedTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        if (game.venue.name.length > 20)
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${game.venue.name.substring(0, 20)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
      ],
    );
  }

  /// Botón de notificación
  Widget _buildNotificationButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: onNotificationToggle,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNotificationEnabled ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isNotificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                    size: 16,
                    color: isNotificationEnabled ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isNotificationEnabled ? 'Notificar' : 'Silenciar',
                    style: TextStyle(
                      fontSize: 12,
                      color: isNotificationEnabled ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}