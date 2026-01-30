import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/constants.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/enhanced_widgets.dart';

/// Enhanced Alerts screen with advanced UI and detailed view.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  List<Alert>? _alerts;
  bool _isLoading = true;
  String? _error;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _apiService.getAlerts(activeOnly: _showActiveOnly);
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFff9966),
                    Color(0xFFff5e62),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.notifications_active, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAlerts,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _buildFilterBar()
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ),
        _isLoading
            ? _buildLoadingContent()
            : _error != null
                ? _buildErrorContent()
                : _buildAlertsContent(),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildFilterChip('All Alerts', !_showActiveOnly, () {
            setState(() => _showActiveOnly = false);
            _loadAlerts();
          }),
          const SizedBox(width: 12),
          _buildFilterChip('Active Only', _showActiveOnly, () {
            setState(() => _showActiveOnly = true);
            _loadAlerts();
          }),
          const Spacer(),
          if (_alerts != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_alerts!.length} alerts',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20),
          ),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400)
                .animate()
                .fadeIn()
                .scale(),
            const SizedBox(height: 16),
            Text(_error ?? 'Connection error', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAlerts, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsContent() {
    if (_alerts == null || _alerts!.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline, size: 80, color: AppColors.success)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms, delay: 1000.ms),
              ),
              const SizedBox(height: 24),
              Text('All Systems Normal', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'No alerts detected at this time',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<Alert>.from(_alerts!)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final alert = sorted[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EnhancedAlertCard(alert: alert)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 * index))
                  .slideX(begin: 0.1, end: 0),
            );
          },
          childCount: sorted.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
