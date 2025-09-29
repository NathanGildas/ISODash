import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kpi_provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export & Documentation'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExportSection(),
                  const SizedBox(height: 24),
                  _buildReportSection(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export des données',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exporter en PDF'),
              subtitle: const Text('Rapport complet des KPI ISO'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showExportDialog('PDF'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Exporter en Word'),
              subtitle: const Text('Document modifiable pour rapports'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showExportDialog('Word'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exporter en Excel'),
              subtitle: const Text('Données brutes pour analyse avancée'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showExportDialog('Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rapports automatiques',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<KPIProvider>(
              builder: (context, kpiProvider, child) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Rapport mensuel automatique'),
                      subtitle: const Text('Génération automatique chaque mois'),
                      trailing: Switch(
                        value: false, // TODO: Add to KPIProvider
                        onChanged: (value) {
                          // TODO: Implement automatic reports
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité en développement'),
                            ),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Envoi automatique par email'),
                      subtitle: const Text('Rapport envoyé aux responsables'),
                      trailing: Switch(
                        value: false, // TODO: Add to KPIProvider
                        onChanged: (value) {
                          // TODO: Implement email automation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité en développement'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export $format'),
        content: Text(
          'L\'export en format $format sera disponible dans une prochaine version.\n\n'
          'Cette fonctionnalité permettra d\'exporter :\n'
          '• Les indicateurs KPI complets\n'
          '• Les graphiques d\'évolution\n'
          '• Les analyses de conformité\n'
          '• Les plans d\'action',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}