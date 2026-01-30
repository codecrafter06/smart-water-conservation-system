import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/constants.dart';

/// Animated water tank indicator widget.
/// Shows the current water level with smooth fill animation.
class WaterTankIndicator extends StatefulWidget {
  final double waterLevel;
  final double height;
  final double width;
  final bool animate;

  const WaterTankIndicator({
    super.key,
    required this.waterLevel,
    this.height = 200,
    this.width = 120,
    this.animate = true,
  });

  @override
  State<WaterTankIndicator> createState() => _WaterTankIndicatorState();
}

class _WaterTankIndicatorState extends State<WaterTankIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  double _previousLevel = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: AnimationDurations.tankFill),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.waterLevel,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(WaterTankIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.waterLevel != widget.waterLevel) {
      _previousLevel = _fillAnimation.value;
      _fillAnimation = Tween<double>(
        begin: _previousLevel,
        end: widget.waterLevel,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, child) {
        final level = _fillAnimation.value;
        final color = getWaterLevelColor(level);

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLG),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusMD),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background
                Container(
                  color: Colors.grey.shade200,
                ),

                // Water fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: (widget.height - 6) * (level / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.7),
                        color,
                        color.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Wave effect at top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          size: Size(widget.width, 20),
                          painter: WavePainter(color: color.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Level text
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSM,
                      vertical: Dimensions.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                    ),
                    child: Text(
                      '${level.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for wave effect.
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height / 2 + 5 * (i / size.width) * (1 - i / size.width) * 4,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shimmer loading placeholder widget.
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Dashboard stat card with animation.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSM),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                    ),
                    child: Icon(icon, color: color, size: Dimensions.iconMD),
                  ),
                  const Spacer(),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSM,
                        vertical: Dimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM),
                      ),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSM),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: Dimensions.paddingXS),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alert card widget.
class AlertCard extends StatelessWidget {
  final String type;
  final int priority;
  final String message;
  final String timestamp;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.type,
    required this.priority,
    required this.message,
    required this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = getAlertPriorityColor(priority);
    final icon = _getAlertIcon(type);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingMD,
        vertical: Dimensions.paddingSM,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                ),
                child: Icon(icon, color: color, size: Dimensions.iconMD),
              ),
              const SizedBox(width: Dimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSM,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSM),
                          ),
                          child: Text(
                            _getPriorityLabel(priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSM),
                        Text(
                          _formatType(type),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingXS),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.paddingXS),
                    Text(
                      _formatTimestamp(timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'overflow':
        return Icons.water_damage;
      case 'leakage':
        return Icons.plumbing;
      case 'low_water':
        return Icons.water_drop_outlined;
      case 'high_flow':
        return Icons.speed;
      default:
        return Icons.warning_amber;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'LOW';
      case 2:
        return 'MEDIUM';
      case 3:
        return 'HIGH';
      case 4:
        return 'CRITICAL';
      default:
        return 'INFO';
    }
  }

  String _formatType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }
}

/// Status indicator dot.
class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'critical':
      case 'overflow_risk':
      case 'leakage_detected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}
