import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/constants.dart';

/// Settings screen - Threshold controls and theme toggle.
class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _overflowThreshold = WaterLevelConstants.overflowThreshold;
  double _lowWaterThreshold = WaterLevelConstants.warningLow;
  double _highFlowThreshold = FlowRateConstants.highUsage;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _overflowThreshold = prefs.getDouble('overflow_threshold') ?? 95;
      _lowWaterThreshold = prefs.getDouble('low_water_threshold') ?? 20;
      _highFlowThreshold = prefs.getDouble('high_flow_threshold') ?? 20;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overflow_threshold', _overflowThreshold);
    await prefs.setDouble('low_water_threshold', _lowWaterThreshold);
    await prefs.setDouble('high_flow_threshold', _highFlowThreshold);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Settings'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.waterBlue],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Appearance Section
              _buildSectionHeader('Appearance')
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 300)),
              _buildThemeCard(),

              const SizedBox(height: Dimensions.paddingLG),

              // Thresholds Section
              _buildSectionHeader('Alert Thresholds')
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200)),
              _buildThresholdCard(
                'Overflow Alert',
                'Water level above this triggers overflow alert',
                Icons.water_damage,
                _overflowThreshold,
                50,
                100,
                '%',
                (v) => setState(() => _overflowThreshold = v),
              ),
              _buildThresholdCard(
                'Low Water Alert',
                'Water level below this triggers low water alert',
                Icons.water_drop_outlined,
                _lowWaterThreshold,
                5,
                50,
                '%',
                (v) => setState(() => _lowWaterThreshold = v),
              ),
              _buildThresholdCard(
                'High Flow Alert',
                'Flow rate above this triggers high flow alert',
                Icons.speed,
                _highFlowThreshold,
                5,
                50,
                'L/min',
                (v) => setState(() => _highFlowThreshold = v),
              ),

              const SizedBox(height: Dimensions.paddingLG),

              // Notifications Section
              _buildSectionHeader('Notifications')
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 400)),
              _buildNotificationCard(),

              const SizedBox(height: Dimensions.paddingLG),

              // About Section
              _buildSectionHeader('About')
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 500)),
              _buildAboutCard(),

              const SizedBox(height: Dimensions.paddingLG),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

              const SizedBox(height: Dimensions.paddingXL),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSM),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildThemeCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: AppColors.primaryBlue,
        ),
        title: const Text('Dark Mode'),
        subtitle: Text(widget.isDarkMode ? 'On' : 'Off'),
        trailing: Switch(
          value: widget.isDarkMode,
          onChanged: (_) => widget.onThemeToggle(),
        ),
      ),
    );
  }

  Widget _buildThresholdCard(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSM),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  '${value.round()} $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppColors.primaryBlue),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts on your device'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.water, color: AppColors.waterBlue),
            title: Text('Smart Water Conservation System'),
            subtitle: Text('Version 1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Final Semester Project'),
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Water Conservation',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Smart Water Team',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A smart IoT-based water conservation system with '
          'real-time monitoring, anomaly detection, and analytics.',
        ),
      ],
    );
  }
}
