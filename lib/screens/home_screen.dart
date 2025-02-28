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
    LogoutScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 1) {
        MonitoringScreen.refreshInstance(context);
      }
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      MonitoringScreen.refreshInstance(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
