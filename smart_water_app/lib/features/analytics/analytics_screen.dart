import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/constants.dart';
import '../../../data/models/models.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/widgets.dart';

/// Enhanced Analytics screen with tabs and advanced charts.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  AnalyticsData? _analyticsData;
  ConservationReport? _conservationReport;
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _loadAnalytics();
  }

  void _onTabChanged(int index) {
    final days = [7, 14, 30][index];
    if (days != _selectedDays) {
      setState(() => _selectedDays = days);
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getDailyAnalytics(days: _selectedDays);
      final report = await _apiService.getConservationReport(period: 'weekly');
      setState(() {
        _analyticsData = data;
        _conservationReport = report;
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
  void dispose() {
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 160,
          floating: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: Icon(Icons.analytics, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Week'),
              Tab(text: '2 Weeks'),
              Tab(text: 'Month'),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ),
      ],
      body: _isLoading
          ? _buildLoadingContent()
          : _error != null
              ? _buildErrorContent()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          ShimmerLoading(width: double.infinity, height: 100, borderRadius: 16),
          SizedBox(height: 20),
          ShimmerLoading(width: double.infinity, height: 250, borderRadius: 16),
          SizedBox(height: 20),
          ShimmerLoading(width: double.infinity, height: 250, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading data'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    final data = _analyticsData!;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Cards
          _buildSummaryCards(data)
              .animate()
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Water Level Trend Chart
          _buildChartCard(
            title: 'Water Level Trend',
            icon: Icons.show_chart,
            child: _buildAreaChart(data),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Daily Consumption Chart
          _buildChartCard(
            title: 'Daily Consumption',
            icon: Icons.bar_chart,
            child: _buildBarChart(data),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Usage Pattern
          _buildUsagePattern().animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 24),

          // Predictions
          _buildPredictions(data).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 24),

          // Conservation Report
          if (_conservationReport != null)
            _buildConservationReport(_conservationReport!).animate().fadeIn(delay: 900.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
              child: _buildMiniCard(
                'Total Usage',
                '${data.totalWaterFlowLiters.toStringAsFixed(0)} L',
                Icons.water,
                AppColors.waterBlue,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
              child: _buildMiniCard(
                'Avg Level',
                '${data.averageDailyLevel.toStringAsFixed(1)}%',
                Icons.trending_flat,
                AppColors.success,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
              child: _buildMiniCard(
                'Readings',
                '${data.totalReadings}',
                Icons.sensors,
                AppColors.primaryBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3),
          width: isDark ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accentDark.withOpacity(0.15) : AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.accentDark : AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }

  Widget _buildAreaChart(AnalyticsData data) {
    if (data.dailyData.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (data.dailyData.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.dailyData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.dailyData[idx].date.substring(5),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.dailyData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.averageWaterLevel);
            }).toList(),
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF00C9FF),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00C9FF).withOpacity(0.3),
                  const Color(0xFF92FE9D).withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(AnalyticsData data) {
    if (data.dailyData.isEmpty) return const Center(child: Text('No data'));

    final maxFlow = data.dailyData
        .map((d) => d.totalFlowLiters)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxFlow * 1.2,
        barGroups: data.dailyData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.totalFlowLiters,
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxFlow / 4,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.dailyData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.dailyData[idx].date.substring(8),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}L',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildUsagePattern() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.08),
            AppColors.waterBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Usage Pattern',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                    _buildPatternItem('Morning', '35%', Icons.wb_sunny_outlined, Colors.orange),
                    _buildPatternItem('Afternoon', '25%', Icons.wb_sunny, Colors.amber),
                    _buildPatternItem('Evening', '30%', Icons.nights_stay_outlined, Colors.indigo),
                    _buildPatternItem('Night', '10%', Icons.nightlight, Colors.blueGrey),
                  ],
                );
              } else {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _buildPatternItem('Morning', '35%', Icons.wb_sunny_outlined, Colors.orange),
                    _buildPatternItem('Afternoon', '25%', Icons.wb_sunny, Colors.amber),
                    _buildPatternItem('Evening', '30%', Icons.nights_stay_outlined, Colors.indigo),
                    _buildPatternItem('Night', '10%', Icons.nightlight, Colors.blueGrey),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictions(AnalyticsData data) {
    final avgDaily = data.totalWaterFlowLiters / _selectedDays;
    final predicted = (avgDaily * 7).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.waterBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.3),
                      AppColors.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Predictions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.2),
                      AppColors.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.psychology, size: 14, color: AppColors.primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildPredictionCard(
                        'Next Week Usage',
                        '$predicted L',
                        Icons.trending_up,
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPredictionCard(
                        'Refill Needed',
                        'In 3 days',
                        Icons.water_drop,
                        AppColors.warning,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPredictionCard(
                      'Next Week Usage',
                      '$predicted L',
                      Icons.trending_up,
                      AppColors.info,
                    ),
                    const SizedBox(height: 12),
                    _buildPredictionCard(
                      'Refill Needed',
                      'In 3 days',
                      Icons.water_drop,
                      AppColors.warning,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConservationReport(ConservationReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.success.withOpacity(0.4) : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Conservation Report',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Text(
                  report.period.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildReportMetric(
                  'Water Saved',
                  '${report.waterSavedLiters.toStringAsFixed(0)} L',
                  Icons.water_drop,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportMetric(
                  'Efficiency',
                  '${report.efficiencyPercent.toStringAsFixed(0)}%',
                  Icons.speed,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportMetric(
                  'Savings',
                  '${report.savingsPercent.toStringAsFixed(0)}%',
                  Icons.trending_down,
                  isDark ? AppColors.accentDark : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              insight,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Efficiency calculated based on water level stability and usage patterns',
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

  Widget _buildReportMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
