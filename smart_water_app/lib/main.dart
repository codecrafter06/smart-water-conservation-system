import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/alerts/alerts_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const SmartWaterApp());
}

/// Main application widget.
class SmartWaterApp extends StatefulWidget {
  const SmartWaterApp({super.key});

  @override
  State<SmartWaterApp> createState() => _SmartWaterAppState();
}

class _SmartWaterAppState extends State<SmartWaterApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Water Conservation',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigation(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

/// Main navigation with bottom navigation bar.
class MainNavigation extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const MainNavigation({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardScreen(),
          const AnalyticsScreen(),
          const AlertsScreen(),
          SettingsScreen(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
