import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/constants.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/enhanced_widgets.dart';

/// Enhanced Dashboard with modern UI, animations, and new features.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  DashboardData? _dashboardData;
  AnalyticsData? _analyticsData;
  WaterShortagePrediction? _prediction;
  ControlState? _controlState;
  bool _isLoading = true;
  String? _error;
  String _selectedTank = 'TANK-MAIN';

  // Mock multi-tank data
  final List<Map<String, dynamic>> _tanks = [
    {'id': 'TANK-MAIN', 'name': 'Main Tank', 'level': 67.0},
    {'id': 'TANK-RESERVE', 'name': 'Reserve', 'level': 45.0},
    {'id': 'TANK-GARDEN', 'name': 'Garden', 'level': 82.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await _apiService.getLiveDashboard();
      final analytics = await _apiService.getDailyAnalytics(days: 7);
      final prediction = await _apiService.getWaterShortagePrediction();
      final controlState = await _apiService.getControlState();
      setState(() {
        _dashboardData = dashboard;
        _analyticsData = analytics;
        _prediction = prediction;
        _controlState = controlState;
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
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            _buildLoadingContent()
          else if (_error != null)
            _buildErrorContent()
          else
            _buildDashboardContent(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Smart Water',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const ShimmerLoading(width: double.infinity, height: 60, borderRadius: 16),
          const SizedBox(height: 24),
          const ShimmerLoading(width: double.infinity, height: 200, borderRadius: 24),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: ShimmerLoading(width: double.infinity, height: 140, borderRadius: 24)),
              SizedBox(width: 16),
              Expanded(child: ShimmerLoading(width: double.infinity, height: 140, borderRadius: 24)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildErrorContent() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400)
                .animate()
                .fadeIn()
                .scale(),
            const SizedBox(height: 24),
            Text('Connection Error', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error ?? 'Failed to connect to server', 
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final data = _dashboardData!;
    final tank = data.tankStatus;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.crossAxisExtent > 1100;
        final isMedium = constraints.crossAxisExtent > 700;

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 60 : (isMedium ? 40 : 20),
            vertical: 24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isWide) _buildDesktopHeader(data),
              
              const SizedBox(height: 32),
              
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Core Status
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTankSelector(),
                          const SizedBox(height: 32),
                          Center(
                            child: AnimatedWaterTank(
                              level: tank.waterLevelPercent,
                              size: 340,
                            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                          ),
                          const SizedBox(height: 48),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Right Column: Intelligence & Metrics
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBanner(data),
                          const SizedBox(height: 24),
                          if (_prediction != null) _buildPredictionCard(_prediction!),
                          const SizedBox(height: 32),
                          Text('System Metrics', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 20),
                          _buildMetricCards(tank),
                          const SizedBox(height: 32),
                          _buildInsightsSection(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                // Tablet/Mobile Stack
                _buildTankSelector().animate().fadeIn(),
                const SizedBox(height: 32),
                if (isMedium)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedWaterTank(
                              level: tank.waterLevelPercent,
                              size: 240,
                            ).animate().scale(),
                            const SizedBox(height: 32),
                            _buildQuickActions(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _buildStatusBanner(data),
                            const SizedBox(height: 16),
                            if (_prediction != null) _buildPredictionCard(_prediction!),
                            const SizedBox(height: 16),
                            _buildMetricCards(tank),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildStatusBanner(data),
                  const SizedBox(height: 24),
                  if (_prediction != null) _buildPredictionCard(_prediction!),
                  const SizedBox(height: 40),
                  Center(
                    child: AnimatedWaterTank(
                      level: tank.waterLevelPercent,
                      size: 220,
                    ),
                  ).animate().scale(),
                  const SizedBox(height: 40),
                  _buildMetricCards(tank),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildInsightsSection(),
                ],
              ],

              if (!isWide) ...[
                const SizedBox(height: 32),
                if (data.alerts.isNotEmpty) _buildAlertsPreview(data.alerts),
              ],
              
              const SizedBox(height: 80),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader(DashboardData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time monitoring and control system',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderStat('ACTIVE DEVICES', '12'),
            const SizedBox(width: 24),
            _buildHeaderStat('SYSTEM UPTIME', '99.9%'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTankSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tanks.map((tank) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TankSelectorChip(
              tankId: tank['id'],
              tankName: tank['name'],
              isSelected: _selectedTank == tank['id'],
              waterLevel: tank['level'],
              onTap: () => setState(() => _selectedTank = tank['id']),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBanner(DashboardData data) {
    final isNormal = data.status == 'normal';
    final color = isNormal ? AppColors.success : AppColors.warning;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3),
          width: isDark ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isNormal ? Icons.check_circle : Icons.warning_amber,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNormal ? 'System Normal' : 'Attention Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : color,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (data.alertsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.error.withOpacity(0.2) : AppColors.error,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: AppColors.error, width: 1) : null,
              ),
              child: Text(
                '${data.alertsCount}',
                style: TextStyle(
                  color: isDark ? AppColors.error : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(WaterShortagePrediction prediction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color warningColor;
    IconData warningIcon;
    
    switch (prediction.warningLevel) {
      case 'critical':
        warningColor = AppColors.error;
        warningIcon = Icons.error;
        break;
      case 'warning':
        warningColor = AppColors.warning;
        warningIcon = Icons.warning_amber;
        break;
      case 'caution':
        warningColor = AppColors.info;
        warningIcon = Icons.info;
        break;
      default:
        warningColor = AppColors.success;
        warningIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? warningColor.withOpacity(0.4) : warningColor.withOpacity(0.3),
          width: isDark ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? warningColor.withOpacity(0.15) : warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(warningIcon, color: warningColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Shortage Prediction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppColors.textPrimaryDark : warningColor,
                      ),
                    ),
                    Text(
                      'AI-powered forecast',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water will last',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prediction.hoursRemaining > 99
                            ? '99+ hours'
                            : '~${prediction.hoursRemaining.toStringAsFixed(0)} hours',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.borderDark : Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage Status',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prediction.usageStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: prediction.usageStatus == 'high'
                              ? AppColors.error
                              : prediction.usageStatus == 'low'
                                  ? AppColors.info
                                  : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.info.withOpacity(0.1) : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prediction.usageMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(TankStatus tank) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              height: 180,
              child: MetricCard(
                title: 'Water Level',
                value: tank.waterLevelPercent.toStringAsFixed(0),
                unit: '%',
                icon: Icons.water_drop,
                primaryColor: const Color(0xFF00C9FF),
                secondaryColor: const Color(0xFF92FE9D),
                trend: '+2.5%',
                isPositiveTrend: true,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              height: 180,
              child: MetricCard(
                title: 'Flow Rate',
                value: tank.flowRateLpm.toStringAsFixed(1),
                unit: 'L/min',
                icon: Icons.speed,
                primaryColor: const Color(0xFF667eea),
                secondaryColor: const Color(0xFF764ba2),
                trend: '-0.8%',
                isPositiveTrend: false,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              height: 180,
              child: MetricCard(
                title: 'Capacity',
                value: (tank.waterLevelPercent * 10).toStringAsFixed(0),
                unit: 'L',
                icon: Icons.local_drink,
                primaryColor: const Color(0xFFf093fb),
                secondaryColor: const Color(0xFFF5576c),
                trend: 'Stable',
                isPositiveTrend: true,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              height: 180,
              child: const MetricCard(
                title: 'Efficiency',
                value: '78',
                unit: '%',
                icon: Icons.eco,
                primaryColor: Color(0xFF4facfe),
                secondaryColor: Color(0xFF00f2fe),
                trend: '+5.2%',
                isPositiveTrend: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    if (_controlState == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QuickActionButton(
                icon: Icons.power_settings_new,
                label: 'Main Pump',
                color: AppColors.success,
                isActive: _controlState!.pumpMain,
                onTap: () => _togglePump('main', !_controlState!.pumpMain),
              ),
              const SizedBox(width: 12),
              QuickActionButton(
                icon: Icons.water,
                label: 'Inlet Valve',
                color: AppColors.primaryBlue,
                isActive: _controlState!.valveInlet,
                onTap: () => _toggleValve('inlet', !_controlState!.valveInlet),
              ),
              const SizedBox(width: 12),
              QuickActionButton(
                icon: Icons.output,
                label: 'Outlet Valve',
                color: AppColors.warning,
                isActive: _controlState!.valveOutlet,
                onTap: () => _toggleValve('outlet', !_controlState!.valveOutlet),
              ),
              const SizedBox(width: 12),
              QuickActionButton(
                icon: Icons.auto_mode,
                label: 'Auto Mode',
                color: AppColors.waterBlue,
                isActive: _controlState!.autoMode,
                onTap: () => _toggleAutoMode(!_controlState!.autoMode),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final efficiency = _analyticsData != null ? 78.5 : 0.0;
    final savedWater = _analyticsData != null 
        ? (_analyticsData!.totalWaterFlowLiters * 0.15).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: AppColors.borderDark) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accentDark.withOpacity(0.15) : AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights,
                  color: isDark ? AppColors.accentDark : AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Water Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    EfficiencyScore(score: efficiency, label: 'Efficiency'),
                    Column(
                      children: [
                        Text(
                          '$savedWater L',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saved This Week',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_down,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '12% Less',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'vs Last Week',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        EfficiencyScore(score: efficiency, label: 'Efficiency'),
                        Column(
                          children: [
                            Text(
                              '$savedWater L',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Saved This Week',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Column(
                      children: [
                        Icon(Icons.trending_down, color: AppColors.success, size: 32),
                        SizedBox(height: 8),
                        Text(
                          '12% Less vs Last Week',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.info.withOpacity(0.1) : AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Peak usage detected between 7-9 AM. Consider scheduling refills overnight.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsPreview(List<Alert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Alerts', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => _navigateToAlerts(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...alerts.take(2).map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAlertCard(alert),
            )),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final color = getAlertPriorityColor(alert.priority);

    return GestureDetector(
      onTap: () => _showAlertDetail(alert),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getAlertIcon(alert.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatTime(alert.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: color.withOpacity(0.1));
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'overflow':
        return Icons.water_damage;
      case 'leakage':
        return Icons.plumbing;
      case 'low_water':
        return Icons.water_drop_outlined;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return timestamp;
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _togglePump(String pump, bool newState) async {
    final success = await _apiService.controlPump(pump, newState);
    if (success) {
      await _apiService.getControlState().then((state) {
        setState(() => _controlState = state);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pump pump ${newState ? "started" : "stopped"}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _toggleValve(String valve, bool newState) async {
    final success = await _apiService.controlValve(valve, newState);
    if (success) {
      await _apiService.getControlState().then((state) {
        setState(() => _controlState = state);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$valve valve ${newState ? "opened" : "closed"}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  void _toggleAutoMode(bool newState) async {
    final success = await _apiService.controlAutoMode(newState);
    if (success) {
      await _apiService.getControlState().then((state) {
        setState(() => _controlState = state);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto mode ${newState ? "enabled" : "disabled"}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _navigateToAlerts() {
    // Navigation handled by bottom nav
  }

  void _showAlertDetail(Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AlertDetailSheet(alert: alert),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

/// Alert detail bottom sheet.
class _AlertDetailSheet extends StatelessWidget {
  final Alert alert;

  const _AlertDetailSheet({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = getAlertPriorityColor(alert.priority);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getIcon(alert.type), color: color, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            alert.priorityLabel.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(alert.message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildInfoRow(context, 'Device', alert.deviceId),
          _buildInfoRow(context, 'Tank', alert.tankId),
          _buildInfoRow(context, 'Value', '${alert.detectedValue}'),
          _buildInfoRow(context, 'Threshold', '${alert.threshold}'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alert acknowledged')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: const Text('Acknowledge'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'overflow': return Icons.water_damage;
      case 'leakage': return Icons.plumbing;
      case 'low_water': return Icons.water_drop_outlined;
      default: return Icons.warning_amber;
    }
  }
}
