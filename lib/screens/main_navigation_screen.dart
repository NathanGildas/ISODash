import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_transition_container.dart';
import '../widgets/fluid_nav_bar/fluid_nav_bar.dart';
import 'kpi_dashboard_screen.dart';
import 'kpi_evolution_screen.dart';
import 'export_screen.dart';
import '../widgets/data_diagnostic_widget.dart';
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
      const DataDiagnosticWidget(),
      // const DiagnosticScreen(key: ValueKey('diagnostic')),
      const SettingsScreen(key: ValueKey('settings')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedSwitcher(
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        duration: Duration(milliseconds: 500),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: FluidNavBar(onChange: _handleNavigationChange),
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
