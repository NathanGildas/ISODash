import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/guided_auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/project_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ProjectProvider())],
      child: MaterialApp(
        title: 'Project Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true, //Dessin moderne
        ),
        home: GuidedAuthScreen(),
        //Routes pour la navigation (si besoin)
        routes: {'/dashboard': (context) => DashboardScreen()},
      ),
    );
  }
}
