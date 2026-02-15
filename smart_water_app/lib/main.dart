import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/alerts/alerts_screen.dart';
import 'features/settings/settings_screen.dart';
import 'core/constants/constants.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final isMedium = constraints.maxWidth > 600 && constraints.maxWidth <= 900;

        return Scaffold(
          body: Row(
            children: [
              if (isWide || isMedium)
                _buildSidebar(isWide),
              Expanded(
                child: IndexedStack(
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
              ),
            ],
          ),
          bottomNavigationBar: (!isWide && !isMedium)
              ? NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  destinations: _buildDestinations(),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSidebar(bool extended) {
    final isDark = widget.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        extended: extended,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        labelType: extended ? null : NavigationRailLabelType.all,
        leading: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(extended),
            const SizedBox(height: 30),
          ],
        ),
        trailing: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: widget.onThemeToggle,
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle Theme',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        destinations: _buildRailDestinations(),
      ),
    );
  }

  Widget _buildLogo(bool extended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.water_drop, color: AppColors.primaryBlue),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            const Text(
              'SmartWater',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<NavigationDestination> _buildDestinations() {
    return const [
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
    ];
  }

  List<NavigationRailDestination> _buildRailDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Analytics'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: Text('Alerts'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
  }
}
