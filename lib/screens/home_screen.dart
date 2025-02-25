import 'package:flutter/material.dart';
import 'package:frontend/screens/logout_screen.dart';
import 'package:frontend/screens/patient_screen.dart';
import 'package:frontend/screens/pews_screen.dart';
import 'package:frontend/screens/monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PatientScreen(),
    const PewsScreen(),
    const MonitoringScreen(),
    const LogoutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services),
            label: 'PEWS',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitoramento',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
