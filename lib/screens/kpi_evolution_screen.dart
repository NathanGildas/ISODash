import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/kpi_provider.dart';
import '../providers/theme_provider.dart';
import '../models/kpi_indicator.dart';

class KPIEvolutionScreen extends StatefulWidget {
  const KPIEvolutionScreen({super.key});

  @override
  State<KPIEvolutionScreen> createState() => _KPIEvolutionScreenState();
}

class _KPIEvolutionScreenState extends State<KPIEvolutionScreen> {
  @override
  void initState() {
    super.initState();
    // Don't reload KPIs here since they're already loaded in MainNavigationScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom app bar content
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Évolution des Indicateurs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      onPressed: () {
                        final newMode = themeProvider.isDarkMode
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        themeProvider.setThemeMode(newMode);
                      },
                      tooltip: 'Changer le thème',
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<KPIProvider>(
              builder: (context, kpiProvider, child) {
                if (kpiProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des données d\'évolution...'),
                      ],
                    ),
                  );
                }

                if (kpiProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kpiProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => kpiProvider.refresh(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(kpiProvider),
                      const SizedBox(height: 24),
                      _buildEvolutionCharts(kpiProvider),
                      const SizedBox(height: 24),
                      _buildKPISummaryCards(kpiProvider),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(KPIProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.goToPreviousMonth(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text('Mois précédent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      provider.currentMonthDisplay,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.goToNextMonth(),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('Mois suivant'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionCharts(KPIProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendances des KPI',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800, // Wide enough for 12 months
                  child: _buildEvolutionChart(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChart(KPIProvider provider) {
    // Mock data for full year demonstration
    final spots = [
      const FlSpot(1, 65),   // Janvier
      const FlSpot(2, 70),   // Février
      const FlSpot(3, 75),   // Mars
      const FlSpot(4, 72),   // Avril
      const FlSpot(5, 78),   // Mai
      const FlSpot(6, 82),   // Juin
      const FlSpot(7, 79),   // Juillet
      const FlSpot(8, 85),   // Août
      const FlSpot(9, 88),   // Septembre
      const FlSpot(10, 84),  // Octobre
      const FlSpot(11, 90),  // Novembre
      const FlSpot(12, 87),  // Décembre
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = [
                  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
                  'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                ];
                if (value.toInt() >= 1 && value.toInt() <= months.length) {
                  return Text(
                    months[value.toInt() - 1],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        minX: 1,
        maxX: 12,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISummaryCards(KPIProvider provider) {
    final kpis = [
      provider.monthlyKPI,
      provider.quarterlyKPI,
      provider.qualityKPI,
    ].where((kpi) => kpi != null).cast<KPIIndicator>().toList();

    if (kpis.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Aucune donnée disponible pour cette période'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résumé des indicateurs',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...kpis.map((kpi) => _buildSummaryCard(kpi)),
      ],
    );
  }

  Widget _buildSummaryCard(KPIIndicator kpi) {
    final theme = Theme.of(context);
    final primaryColor = kpi.isCompliant ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            kpi.isCompliant ? Icons.trending_up : Icons.trending_down,
            color: primaryColor,
          ),
        ),
        title: Text(
          kpi.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Objectif: ${kpi.targetValue.toStringAsFixed(0)}%',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${kpi.currentValue.toStringAsFixed(1)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Text(
              kpi.isCompliant ? 'Conforme' : 'Non conforme',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
