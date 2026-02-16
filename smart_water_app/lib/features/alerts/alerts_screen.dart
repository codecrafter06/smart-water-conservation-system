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

  Alert? _selectedAlert;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return Scaffold(
          body: _isLoading
              ? _buildLoadingSkeleton(isWide)
              : _error != null
                  ? _buildErrorContent()
                  : isWide 
                      ? _buildWideLayout() 
                      : _buildMobileLayout(),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Alerts List
              Expanded(
                flex: 4,
                child: _buildAlertsListContainer(),
              ),
              const VerticalDivider(width: 1),
              // Right Column: Detail View
              Expanded(
                flex: 6,
                child: _selectedAlert != null
                    ? _buildDetailView(_selectedAlert!)
                    : _buildEmptyDetailState(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications Center',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor system anomalies and critical events',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFff9966), Color(0xFFff5e62)],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAlerts),
          ],
        ),
        SliverToBoxAdapter(child: _buildFilterBar()),
        _buildAlertsContentSliver(),
      ],
    );
  }

  Widget _buildAlertsListContainer() {
    if (_alerts == null || _alerts!.isEmpty) return _buildEmptyState();

    final sorted = List<Alert>.from(_alerts!)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final alert = sorted[index];
              final isSelected = _selectedAlert?.id == alert.id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAlert = alert),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: EnhancedAlertCard(
                      alert: alert,
                      onTap: () => setState(() => _selectedAlert = alert),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(Alert alert) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailHeader(alert),
          const SizedBox(height: 40),
          _buildDetailGrid(alert),
          const SizedBox(height: 48),
          _buildActionButtons(alert),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildDetailHeader(Alert alert) {
    final color = getAlertPriorityColor(alert.priority);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getAlertIcon(alert.type), color: color, size: 48),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alert.priorityLabel.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Detected at ${alert.timestamp}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(Alert alert) {
    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          _buildDetailItem('Device ID', alert.deviceId, Icons.device_hub, constraints.maxWidth),
          _buildDetailItem('Tank ID', alert.tankId, Icons.opacity, constraints.maxWidth),
          _buildDetailItem('Detected Value', '${alert.detectedValue}', Icons.analytics, constraints.maxWidth),
          _buildDetailItem('Threshold', '${alert.threshold}', Icons.warning_amber, constraints.maxWidth),
        ],
      );
    });
  }

  Widget _buildDetailItem(String label, String value, IconData icon, double maxWidth) {
    final width = maxWidth > 600 ? (maxWidth - 24) / 2 : maxWidth;
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Alert alert) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Acknowledge'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('Resolve Alert'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDetailState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Select an alert to view details', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isWide) {
    return Column(
      children: [
        if (isWide) _buildDesktopHeader(),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No alerts found'));
  }

  Widget _buildAlertsContentSliver() {
    if (_alerts == null || _alerts!.isEmpty) return const SliverFillRemaining(child: Center(child: Text('No alerts')));
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EnhancedAlertCard(alert: _alerts![index]),
          ),
          childCount: _alerts!.length,
        ),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'overflow': return Icons.water_damage;
      case 'leakage': return Icons.plumbing;
      case 'low_water': return Icons.water_drop_outlined;
      default: return Icons.warning_amber;
    }
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
          (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20),
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
                child: const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success)
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
