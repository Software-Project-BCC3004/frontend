import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pews_screen.dart';
import 'screens/professional_screen.dart';
import 'screens/monitoring_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Médico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF64B5F6),
          tertiary: const Color(0xFF4CAF50),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/pews': (context) => const PewsScreen(),
        '/professional': (context) => const ProfessionalScreen(),
        '/monitoring': (context) => const MonitoringScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Página não encontrada')),
            body: const Center(
              child: Text('A página solicitada não existe.'),
            ),
          ),
        );
      },
    );
  }
}
