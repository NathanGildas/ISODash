import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/guided_auth_screen.dart';
// import 'screens/dashboard_screen.dart'; // Commenté temporairement
import 'widgets/data_diagnostic_widget.dart';
import 'screens/kpi_dashboard_screen.dart';
import 'screens/api_explorer_screen.dart';
import 'providers/project_provider.dart';
import 'providers/kpi_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => KPIProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ISODash - Monitoring ISO',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: GuidedAuthScreen(),
            routes: {
              // '/dashboard': (context) => DashboardScreen(), // Commenté temporairement
              '/kpi': (context) => KPIDashboardScreen(),
              '/explorer': (context) => APIExplorerScreen(),
              '/diagnostic': (context) => DataDiagnosticWidget(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}