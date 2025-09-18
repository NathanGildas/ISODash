import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/guided_auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/project_provider.dart';
import 'providers/kpi_provider.dart';
import 'services/api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Create a single ApiService instance to share between providers
    final apiService = ApiService();
    
    return MultiProvider(
      providers: [
        // Project Provider - manages project data and authentication
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        
        // KPI Provider - manages ISO objectives calculations
        ChangeNotifierProvider(create: (_) => KPIProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'ISODash',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          // Responsive text scaling
          textTheme: const TextTheme().apply(
            fontSizeFactor: 1.0,
          ),
          // Ensure proper touch targets on mobile
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
        home: const GuidedAuthScreen(),
        //Routes pour la navigation (si besoin)
        routes: {'/dashboard': (context) => const DashboardScreen()},
      ),
    );
  }
}
