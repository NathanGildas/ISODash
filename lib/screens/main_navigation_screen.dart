import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_transition_container.dart';
import 'kpi_dashboard_screen.dart';
import 'kpi_evolution_screen.dart';
import 'export_screen.dart';
import 'api_explorer_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Liste statique des écrans pour éviter la recréation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const KPIDashboardScreen(key: ValueKey('dashboard')),
      const KPIEvolutionScreen(key: ValueKey('evolution')),
      const ExportScreen(key: ValueKey('export')),
      const APIExplorerScreen(key: ValueKey('apis')),
      const SettingsScreen(key: ValueKey('settings')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _handleNavigationChange,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.file_download),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.api),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '',
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleNavigationChange(int index) {
    if (index != _selectedIndex && index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}
