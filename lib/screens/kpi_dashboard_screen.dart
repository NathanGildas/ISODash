import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kpi_provider.dart';
import '../providers/theme_provider.dart';
import '../models/kpi_indicator.dart';
import '../widgets/kpi_parallax_list.dart';
import '../utils/logger.dart';

class KPIDashboardScreen extends StatefulWidget {
  const KPIDashboardScreen({super.key});

  @override
  State<KPIDashboardScreen> createState() => _KPIDashboardScreenState();
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
    return PopScope(
      canPop: false, // Empêche la sortie automatique
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ISODash - Indicateurs ISO'),
          actions: [
            Consumer<KPIProvider>(
              builder: (context, kpiProvider, child) {
                return IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => _handleRefresh(context, kpiProvider),
                  tooltip: 'Actualiser les données',
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return PopupMenuButton<ThemeMode>(
                  icon: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                  ),
                  tooltip: 'Changer le thème',
                  onSelected: (ThemeMode mode) {
                    themeProvider.setThemeMode(mode);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ThemeMode.light,
                      child: Row(
                        children: [
                          Icon(
                            Icons.light_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Clair'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Row(
                        children: [
                          Icon(
                            Icons.dark_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Sombre'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.system,
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Système'),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
                      onPressed: () => _handleRefresh(context, kpiProvider),
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 600 ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de période
                  _buildPeriodSelector(context, kpiProvider),
                  SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
                  ),

                  // Résumé global
                  _buildGlobalSummary(kpiProvider),
                  SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
                  ),

                  // KPI Cards
                  _buildKPICards(kpiProvider),
                  SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
                  ),

                  // Bottom safe area for mobile
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Gère le rafraîchissement avec vérification du statut de chargement
  void _handleRefresh(BuildContext context, KPIProvider kpiProvider) {
    if (kpiProvider.isLoading) {
      _showLoadingSnackBar(context);
      return;
    }
    kpiProvider.refresh();
  }

  /// Affiche un snackbar discret pour indiquer qu'un chargement est en cours
  void _showLoadingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Chargement en cours... Veuillez patienter'),
          ],
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Affiche une dialog de confirmation pour quitter l'app
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Quitter l\'application ?')),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir fermer ISODash ?\n\nVos données seront sauvegardées automatiquement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                // Quitter l'application
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context, KPIProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            if (isSmallScreen) ...[
              // Layout vertical pour petits écrans
              _buildMobilePeriodSelector(provider),
            ] else ...[
              // Layout horizontal pour grands écrans
              _buildDesktopPeriodSelector(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePeriodSelector(KPIProvider provider) {
    return Column(
      children: [
        // Navigation mensuelle
        _buildPeriodSection(
          'Mensuel',
          provider.currentMonthDisplay,
          provider.goToPreviousMonth,
          provider.goToNextMonth,
          Icons.calendar_month,
        ),
        SizedBox(height: 16),

        // Navigation trimestrielle
        _buildPeriodSection(
          'Trimestriel',
          provider.currentQuarterDisplay,
          provider.goToPreviousQuarter,
          provider.goToNextQuarter,
          Icons.calendar_view_month,
        ),
      ],
    );
  }

  Widget _buildDesktopPeriodSelector(KPIProvider provider) {
    return Row(
      children: [
        // Navigation mensuelle
        Expanded(
          child: _buildPeriodSection(
            'Mensuel',
            provider.currentMonthDisplay,
            provider.goToPreviousMonth,
            provider.goToNextMonth,
            Icons.calendar_month,
          ),
        ),
        SizedBox(width: 16),

        // Navigation trimestrielle
        Expanded(
          child: _buildPeriodSection(
            'Trimestriel',
            provider.currentQuarterDisplay,
            provider.goToPreviousQuarter,
            provider.goToNextQuarter,
            Icons.calendar_view_month,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSection(
    String title,
    String currentPeriod,
    VoidCallback onPrevious,
    VoidCallback onNext,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: Icon(Icons.chevron_left),
                iconSize: 20,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Expanded(
                child: Text(
                  currentPeriod,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(Icons.chevron_right),
                iconSize: 20,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSummary(KPIProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: isSmallScreen
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Conformité Globale',
                          '${provider.overallComplianceRate.toStringAsFixed(1)}%',
                          provider.overallComplianceRate >= 80
                              ? Colors.green
                              : Colors.red,
                          Icons.assessment,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          'KPI Calculés',
                          '${provider.kpis.length}',
                          provider.kpis.isNotEmpty ? Colors.blue : Colors.grey,
                          Icons.analytics,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildSummaryItem(
                    'Période',
                    provider.currentMonthDisplay,
                    Theme.of(context).colorScheme.primary,
                    Icons.calendar_month,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Conformité Globale',
                      '${provider.overallComplianceRate.toStringAsFixed(1)}%',
                      provider.overallComplianceRate >= 80
                          ? Colors.green
                          : Colors.red,
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
                      Theme.of(context).colorScheme.primary,
                      Icons.calendar_month,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Indicateurs ISO',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 12),

        // New parallax KPI cards
        KPIParallaxList(
          kpis: kpis,
          onKPISelected: (kpi) {
            // Handle KPI selection if needed
            Logger.info('Selected KPI: ${kpi.name}', tag: 'KPI');
          },
        ),
      ],
    );
  }
}
