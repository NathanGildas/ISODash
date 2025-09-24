import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/guided_auth_screen.dart';
// import 'screens/dashboard_screen.dart'; // Commenté temporairement
import 'screens/kpi_dashboard_screen.dart';
import 'screens/api_explorer_screen.dart';
import 'providers/project_provider.dart';
import 'providers/kpi_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => KPIProvider()),
      ],
      child: MaterialApp(
        title: 'ISODash - Monitoring ISO',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 2,
            centerTitle: true,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 3,
            margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: GuidedAuthScreen(),
        routes: {
          // '/dashboard': (context) => DashboardScreen(), // Commenté temporairement
          '/kpi': (context) => KPIDashboardScreen(),
          '/explorer': (context) => APIExplorerScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}