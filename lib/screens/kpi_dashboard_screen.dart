import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/kpi_provider.dart';
import '../models/kpi_indicator.dart';

class KPIDashboardScreen extends StatefulWidget {
  const KPIDashboardScreen({super.key});

  @override
  _KPIDashboardScreenState createState() => _KPIDashboardScreenState();
}

class _KPIDashboardScreenState extends State<KPIDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charge les KPI au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KPIProvider>().loadKPIs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ISODash - Indicateurs ISO'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<KPIProvider>().refresh(),
            tooltip: 'Actualiser les données',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () => _exportReport(context),
            tooltip: 'Exporter le rapport',
          ),
        ],
      ),
      body: Consumer<KPIProvider>(
        builder: (context, kpiProvider, child) {
          if (kpiProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calcul des indicateurs ISO...'),
                ],
              ),
            );
          }

          if (kpiProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    kpiProvider.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => kpiProvider.refresh(),
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur de période
                _buildPeriodSelector(context, kpiProvider),
                SizedBox(height: 24),

                // Résumé global
                _buildGlobalSummary(kpiProvider),
                SizedBox(height: 24),

                // KPI Cards
                _buildKPICards(kpiProvider),
                SizedBox(height: 24),

                // Graphique placeholder
                _buildTrendChart(kpiProvider),
                SizedBox(height: 24),

                // Actions rapides
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, KPIProvider provider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                // Navigation mensuelle
                Expanded(
                  child: Column(
                    children: [
                      Text('Mensuel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: provider.goToPreviousMonth,
                            icon: Icon(Icons.chevron_left),
                          ),
                          Text(
                            provider.currentMonthDisplay,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: provider.goToNextMonth,
                            icon: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16),

                // Navigation trimestrielle
                Expanded(
                  child: Column(
                    children: [
                      Text('Trimestriel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: provider.goToPreviousQuarter,
                            icon: Icon(Icons.chevron_left),
                          ),
                          Text(
                            provider.currentQuarterDisplay,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: provider.goToNextQuarter,
                            icon: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSummary(KPIProvider provider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Conformité Globale',
                '${provider.overallComplianceRate.toStringAsFixed(1)}%',
                provider.overallComplianceRate >= 80 ? Colors.green : Colors.red,
                Icons.assessment,
              ),
            ),
            Expanded(
              child: _buildSummaryItem(
                'KPI Calculés',
                '${provider.kpis.length}',
                provider.kpis.isNotEmpty ? Colors.blue : Colors.grey,
                Icons.analytics,
              ),
            ),
            Expanded(
              child: _buildSummaryItem(
                'Période',
                provider.currentMonthDisplay,
                Colors.purple,
                Icons.calendar_month,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKPICards(KPIProvider provider) {
    final kpis = [
      provider.monthlyKPI,
      provider.quarterlyKPI,
      provider.qualityKPI,
    ].where((kpi) => kpi != null).cast<KPIIndicator>().toList();

    if (kpis.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.data_usage, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun indicateur disponible',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Les KPI seront calculés une fois les APIs correctement configurées',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/explorer'),
                icon: Icon(Icons.api),
                label: Text('Explorer les APIs'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs ISO',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),

        ...kpis.map((kpi) => Container(
          margin: EdgeInsets.only(bottom: 12),
          child: _buildKPICard(kpi),
        )).toList(),
      ],
    );
  }

  Widget _buildKPICard(KPIIndicator kpi) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Gauge circulaire
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 25,
                      sections: [
                        PieChartSectionData(
                          value: kpi.currentValue.clamp(0, 100),
                          color: _getKPIColor(kpi.status),
                          showTitle: false,
                          radius: 15,
                        ),
                        PieChartSectionData(
                          value: (100 - kpi.currentValue).clamp(0, 100),
                          color: Colors.grey.shade200,
                          showTitle: false,
                          radius: 15,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      '${kpi.currentValue.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getKPIColor(kpi.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        kpi.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Spacer(),
                      _buildStatusChip(kpi.status),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    kpi.type.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Valeur: ${kpi.displayValue}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getKPIColor(kpi.status),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Objectif: ${kpi.displayTarget}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (kpi.currentValue / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(_getKPIColor(kpi.status)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(KPIStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case KPIStatus.success:
        color = Colors.green;
        label = 'Conforme';
        icon = Icons.check_circle;
        break;
      case KPIStatus.warning:
        color = Colors.orange;
        label = 'À surveiller';
        icon = Icons.warning;
        break;
      case KPIStatus.danger:
        color = Colors.red;
        label = 'Non-conforme';
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Color _getKPIColor(KPIStatus status) {
    switch (status) {
      case KPIStatus.success:
        return Colors.green;
      case KPIStatus.warning:
        return Colors.orange;
      case KPIStatus.danger:
        return Colors.red;
    }
  }

  Widget _buildTrendChart(KPIProvider provider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution des Indicateurs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timeline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Graphique de tendance',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'À implémenter dans Sprint 3',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/explorer'),
                  icon: Icon(Icons.api),
                  label: Text('Explorer APIs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(color: Colors.purple),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportReport(context),
                  icon: Icon(Icons.file_download),
                  label: Text('Exporter PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportDocx(context),
                  icon: Icon(Icons.description),
                  label: Text('Exporter DOCX'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showSettings(context),
                  icon: Icon(Icons.settings),
                  label: Text('Paramètres'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Actions des boutons
  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export PDF - À implémenter dans Sprint 3'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportDocx(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export DOCX - À implémenter dans Sprint 3'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paramètres - À implémenter'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}