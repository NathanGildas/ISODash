import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kpi_provider.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_explorer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
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
                  _buildThemeSection(),
                  const SizedBox(height: 24),
                  _buildDataSection(),
                  const SizedBox(height: 24),
                  _buildAccountSection(),
                  const SizedBox(height: 24),
                  _buildAPISection(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Apparence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return RadioGroup<ThemeMode>(
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('Thème clair'),
                        subtitle: const Text('Interface claire'),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Thème sombre'),
                        subtitle: const Text('Interface sombre'),
                        value: ThemeMode.dark,
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Thème système'),
                        subtitle: const Text('Suit les paramètres du système'),
                        value: ThemeMode.system,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.data_usage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Données',
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
                    SwitchListTile(
                      title: const Text('Mode test'),
                      subtitle: const Text(
                        'Inclut les projets fermés pour les tests',
                      ),
                      value: kpiProvider.isTestMode,
                      onChanged: (bool value) {
                        if (value) {
                          kpiProvider.enableTestMode();
                        } else {
                          kpiProvider.disableTestMode();
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Actualiser les données'),
                      subtitle: const Text('Recharger tous les KPI'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => kpiProvider.refresh(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('Effacer le cache'),
                      subtitle: const Text(
                        'Supprimer toutes les données mises en cache',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showClearCacheDialog(),
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

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Compte & Authentification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Changer le token API'),
              subtitle: const Text('Modifier les identifiants d\'accès'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showChangeTokenDialog(),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade600),
              title: Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red.shade600),
              ),
              subtitle: const Text('Se déconnecter et revenir à l\'accueil'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLogoutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPISection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'APIs & Intégrations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Explorer les APIs OpenProject'),
              subtitle: const Text(
                'Tester la connectivité et analyser les endpoints',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToAPIExplorer(),
            ),
            ListTile(
              leading: const Icon(Icons.integration_instructions),
              title: const Text('Configuration des intégrations'),
              subtitle: const Text('Gérer les connexions externes et webhooks'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showIntegrationsDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'À propos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.apps),
              title: Text('ISODash'),
              subtitle: Text('Version 1.0.0 - Monitoring des indicateurs ISO'),
            ),
            const ListTile(
              leading: Icon(Icons.business),
              title: Text('Développé pour'),
              subtitle: Text('Suivi des performances ISO'),
            ),
            const ListTile(
              leading: Icon(Icons.update),
              title: Text('Dernière mise à jour'),
              subtitle: Text('Sprint 3 - Septembre 2024'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer le cache'),
        content: const Text(
          'Cette action supprimera toutes les données mises en cache. '
          'Les données seront rechargées depuis l\'API lors du prochain accès.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<KPIProvider>().clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache effacé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?\n\n'
          'Vous devrez entrer à nouveau votre token API pour vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showChangeTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le token API'),
        content: const Text(
          'Cette fonctionnalité permettra de modifier votre token API.\n\n'
          'Pour l\'instant, utilisez la déconnexion pour changer de compte.',
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

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAPIExplorer() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const APIExplorerScreen()));
  }

  void _showIntegrationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration des intégrations'),
        content: const Text(
          'Cette fonctionnalité permettra de configurer les intégrations avec des services externes.\n\n'
          'Fonctionnalités à venir :\n'
          '• Webhooks OpenProject\n'
          '• Export automatique vers Teams/Slack\n'
          '• Synchronisation calendrier\n'
          '• Notifications par email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
