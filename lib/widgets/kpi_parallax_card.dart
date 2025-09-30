import 'package:flutter/material.dart';
import '../models/kpi_indicator.dart';

class KPIParallaxCard extends StatelessWidget {
  final KPIIndicator kpi;
  final double cardWidth;
  final double cardHeight;
  final double normalizedOffset;

  const KPIParallaxCard({
    super.key,
    required this.kpi,
    required this.cardWidth,
    required this.cardHeight,
    required this.normalizedOffset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompliant = kpi.isCompliant;

    // Color based on compliance
    final primaryColor = isCompliant
        ? Colors.green
        : (kpi.status == KPIStatus.warning ? Colors.orange : Colors.red);

    final bgColor = theme.brightness == Brightness.dark
        ? primaryColor.withValues(alpha: 0.15)
        : primaryColor.withValues(alpha: 0.1);

    // Parallax offset calculation
    final parallaxOffset = normalizedOffset * 50;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Card(
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern with parallax
                Positioned(
                  right: -20 + parallaxOffset,
                  top: -20 + parallaxOffset * 0.5,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30 + parallaxOffset * 0.8,
                  bottom: -30 + parallaxOffset * 0.3,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getKPITypeLabel(kpi.type),
                              style: TextStyle(
                                color: primaryColor.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            isCompliant ? Icons.check_circle : Icons.warning,
                            color: primaryColor,
                            size: 24,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        kpi.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Value section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Valeur',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${kpi.currentValue.toStringAsFixed(1)}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Objectif',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${kpi.targetValue.toStringAsFixed(0)}%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final progress = (kpi.currentValue / kpi.targetValue).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                Container(
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        primaryColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getKPITypeLabel(KPIType type) {
    switch (type) {
      case KPIType.monthly:
        return 'MENSUEL';
      case KPIType.quarterly:
        return 'TRIMESTRIEL';
      case KPIType.quality:
        return 'QUALITÉ';
    }
  }
}