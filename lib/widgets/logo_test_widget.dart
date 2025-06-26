// lib/widgets/logo_test_widget.dart - Widget de prueba para verificar logos
import 'package:flutter/material.dart';
import '../services/team_logo_service.dart';

class LogoTestWidget extends StatelessWidget {
  const LogoTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Equipos que tienes en assets (basado en los archivos que veo)
    final availableTeams = ['KC', 'PIT', 'SD'];
    
    // Equipos adicionales para probar fallback
    final allTestTeams = ['KC', 'PIT', 'SD', 'NYY', 'LAD', 'BOS', 'HOU'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Logos SVG'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección 1: Logos disponibles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Logos Disponibles (SVG)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: availableTeams.map((team) => _buildTeamLogo(team, true)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Sección 2: Todos los logos (con fallback)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎨 Todos los Logos (SVG + Fallback)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: allTestTeams.map((team) => _buildTeamLogo(team, false)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Sección 3: Widget VS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚔️ Widget VS',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TeamLogoService.versusWidget(
                        'KC',
                        'PIT',
                        logoSize: 50,
                        showTeamNames: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Información de debug
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐛 Información de Debug',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('📁 Ruta de assets: assets/logos/teams/'),
                    Text('📋 Equipos disponibles: ${availableTeams.join(", ")}'),
                    Text('🎯 Formato esperado: [CÓDIGO].svg (ej: KC.svg)'),
                    const SizedBox(height: 12),
                    const Text(
                      '💡 Si ves círculos con códigos en lugar de logos, significa que el archivo SVG no se pudo cargar.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de prueba
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLogInfo(context);
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Ver Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String teamCode, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        children: [
          TeamLogoService.getTeamLogo(teamCode, size: 50),
          const SizedBox(height: 8),
          Text(
            teamCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            TeamLogoService.getTeamName(teamCode),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showLogInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Logs'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revisa la consola de debug para ver:'),
            SizedBox(height: 8),
            Text('🏈 Logs de búsqueda de logos'),
            Text('❌ Errores de archivos no encontrados'),
            Text('⚠️ Warnings de carga de SVG'),
            SizedBox(height: 12),
            Text(
              'Los logos deberían aparecer si los archivos SVG están en la ubicación correcta.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}