// lib/widgets/game_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/simple_mlb_models.dart'; // ✅ IMPORT CORREGIDO

/// Widget para mostrar todos los partidos del día
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
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partidos del Día (${games.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...games.map((game) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GameCard(
            game: game,
            onTap: () => onGameTap(game),
            onNotificationToggle: () => onNotificationToggle(game),
            isNotificationActive: notificationGames.contains(game.id),
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_baseball, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No hay partidos programados',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar solo partidos en vivo
class LiveScoresWidget extends StatelessWidget {
  final List<MLBGame> liveGames;
  final Function(MLBGame) onGameTap;

  const LiveScoresWidget({
    super.key,
    required this.liveGames,
    required this.onGameTap,
  });

  @override
  Widget build(BuildContext context) {
    if (liveGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'En Vivo (${liveGames.length})',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...liveGames.map((game) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LiveGameCard(
            game: game,
            onTap: () => onGameTap(game),
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Widget para mostrar partidos terminados
class FinishedScoresWidget extends StatelessWidget {
  final List<MLBGame> finishedGames;
  final Function(MLBGame) onGameTap;

  const FinishedScoresWidget({
    super.key,
    required this.finishedGames,
    required this.onGameTap,
  });

  @override
  Widget build(BuildContext context) {
    if (finishedGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados Finales (${finishedGames.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...finishedGames.map((game) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FinishedGameCard(
            game: game,
            onTap: () => onGameTap(game),
          ),
        )),
      ],
    );
  }
}

/// Card base para cualquier partido - FIXED LAYOUT
class _GameCard extends StatelessWidget {
  final MLBGame game;
  final VoidCallback onTap;
  final VoidCallback onNotificationToggle;
  final bool isNotificationActive;

  const _GameCard({
    required this.game,
    required this.onTap,
    required this.onNotificationToggle,
    required this.isNotificationActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(),
                Text(
                  game.formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Teams and score - FIXED
            IntrinsicHeight(
              child: Row(
                children: [
                  // Away team
                  Expanded(
                    child: _buildTeam(game.awayTeam, game.score?.awayScore),
                  ),
                  
                  // VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  
                  // Home team
                  Expanded(
                    child: _buildTeam(game.homeTeam, game.score?.homeScore),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer - FIXED
            Row(
              children: [
                // Notification button
                GestureDetector(
                  onTap: onNotificationToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNotificationActive ? Colors.orange[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNotificationActive ? Colors.orange : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNotificationActive ? Icons.notifications_active : Icons.notifications_none,
                          size: 14,
                          color: isNotificationActive ? Colors.orange : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isNotificationActive ? 'ON' : 'OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isNotificationActive ? Colors.orange : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Location
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          game.venue.location,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    
    switch (game.status) {
      case 'inprogress':
        color = Colors.red;
        text = 'EN VIVO';
        break;
      case 'closed':
        color = Colors.grey;
        text = 'FINAL';
        break;
      default:
        color = Colors.blue;
        text = 'PROGRAMADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTeam(Team team, int? score) {
    final abbreviation = _getSafeAbbreviation(team);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Team logo - Simplificado sin TeamLogoService
        _buildSimpleTeamLogo(abbreviation),
        const SizedBox(height: 8),
        
        // Team name
        Text(
          team.name.isNotEmpty ? team.name : abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: score != null ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            score?.toString() ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: score != null ? Colors.blue[700] : Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  String _getSafeAbbreviation(Team team) {
    if (team.abbreviation.isNotEmpty) {
      return team.abbreviation;
    }
    if (team.name.isNotEmpty) {
      return team.name.substring(0, 3).toUpperCase();
    }
    return 'TBD';
  }

  Widget _buildSimpleTeamLogo(String abbreviation) {
    // Logo simplificado sin dependencias externas
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getTeamColor(abbreviation),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getTeamColor(String abbreviation) {
    // Colores básicos por equipo
    switch (abbreviation.toUpperCase()) {
      case 'NYY': return Colors.blue[900]!;
      case 'BOS': return Colors.red[700]!;
      case 'LAD': return Colors.blue[600]!;
      case 'SF': return Colors.orange[700]!;
      case 'CHC': return Colors.blue[600]!;
      case 'NYM': return Colors.blue[700]!;
      default: return Colors.blue[400]!;
    }
  }
}

/// Card especializada para partidos en vivo - FIXED
class _LiveGameCard extends StatelessWidget {
  final MLBGame game;
  final VoidCallback onTap;

  const _LiveGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[50]!, Colors.red[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live indicator
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EN VIVO',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                if (game.inning != null)
                  Text(
                    'Inning ${game.inning}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.red[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Score display with logos - FIXED
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildLiveTeam(game.awayTeam, game.score?.awayScore),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '-',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildLiveTeam(game.homeTeam, game.score?.homeScore),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTeam(Team team, int? score) {
    final abbreviation = _getSafeAbbreviation(team);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSimpleTeamLogo(abbreviation),
        const SizedBox(height: 8),
        Text(
          abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score?.toString() ?? '0',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red[800],
          ),
        ),
      ],
    );
  }

  String _getSafeAbbreviation(Team team) {
    if (team.abbreviation.isNotEmpty) {
      return team.abbreviation;
    }
    if (team.name.isNotEmpty) {
      return team.name.substring(0, 3).toUpperCase();
    }
    return 'TBD';
  }

  Widget _buildSimpleTeamLogo(String abbreviation) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red[400],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Card especializada para partidos terminados - FIXED
class _FinishedGameCard extends StatelessWidget {
  final MLBGame game;
  final VoidCallback onTap;

  const _FinishedGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final homeWon = game.score != null && 
                   game.score!.homeScore > game.score!.awayScore;
    final awayWon = game.score != null && 
                   game.score!.awayScore > game.score!.homeScore;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Away team
              Expanded(
                child: _buildFinishedTeam(
                  game.awayTeam, 
                  game.score?.awayScore, 
                  isWinner: awayWon,
                ),
              ),
              
              // Final indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FINAL',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              
              // Home team
              Expanded(
                child: _buildFinishedTeam(
                  game.homeTeam, 
                  game.score?.homeScore, 
                  isWinner: homeWon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedTeam(Team team, int? score, {bool isWinner = false}) {
    final abbreviation = _getSafeAbbreviation(team);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSimpleTeamLogo(abbreviation),
        const SizedBox(height: 6),
        Text(
          abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
            color: isWinner ? Colors.green[700] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            score?.toString() ?? '0',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWinner ? Colors.green[700] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _getSafeAbbreviation(Team team) {
    if (team.abbreviation.isNotEmpty) {
      return team.abbreviation;
    }
    if (team.name.isNotEmpty) {
      return team.name.substring(0, 3).toUpperCase();
    }
    return 'TBD';
  }

  Widget _buildSimpleTeamLogo(String abbreviation) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          abbreviation,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}