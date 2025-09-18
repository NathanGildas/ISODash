// Dashboard Screen - Main screen showing ISO KPI objectives
// This screen displays the 3 ISO objectives with visual indicators
// Written with comprehensive comments for junior developer understanding

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/kpi_provider.dart';
import '../models/project.dart';
import '../models/kpi_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load both projects and KPI data when screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load project data first
      context.read<ProjectProvider>().loadProjects();
      
      // Then load KPI calculations
      context.read<KPIProvider>().loadAllKPIs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISODash - Tableaux de bord KPI'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button - reloads all data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAllData(),
            tooltip: 'Actualiser les données',
          ),
        ],
      ),
      body: Consumer2<ProjectProvider, KPIProvider>(
        builder: (context, projectProvider, kpiProvider, child) {
          // Check if we're still loading initial data
          if (projectProvider.isLoading && kpiProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données ISO...'),
                ],
              ),
            );
          }

          // Check for errors in either provider
          if (projectProvider.errorMessage != null || kpiProvider.errorMessage != null) {
            final errorMessage = projectProvider.errorMessage ?? kpiProvider.errorMessage ?? '';
            final isAuthError = errorMessage.contains('credential') || errorMessage.contains('Aucune credential');
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAuthError ? Icons.login : Icons.error, 
                    size: 64, 
                    color: isAuthError ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthError ? 'Authentification requise' : 'Erreur de chargement',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      isAuthError 
                        ? 'Veuillez vous connecter d\'abord pour calculer les KPI'
                        : errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAuthError) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate back to auth screen
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Se connecter'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => _refreshAllData(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ],
              ),
            );
          }

          // Main dashboard content
          return RefreshIndicator(
            onRefresh: () => _refreshAllData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with summary
                  _buildDashboardHeader(kpiProvider),
                  const SizedBox(height: 24),
                  
                  // Main KPI Cards - The 3 ISO Objectives
                  _buildKPISection(kpiProvider),
                  const SizedBox(height: 24),
                  
                  // Projects overview (simplified)
                  if (projectProvider.hasProjects) ...[
                    _buildProjectsOverview(projectProvider),
                    const SizedBox(height: 24),
                  ],
                  
                  // Footer with last update info
                  _buildFooterInfo(kpiProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================================================
  // HELPER METHODS - Build different sections of the dashboard
  // =============================================================================

  /// Refresh all data from both providers
  Future<void> _refreshAllData() async {
    // Show loading indicator in providers
    context.read<ProjectProvider>().refresh();
    context.read<KPIProvider>().refreshAll();
  }

  /// Refresh a specific KPI
  Future<void> _refreshSpecificKPI(String kpiName) async {
    // Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualisation de $kpiName...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Refresh the specific KPI
    await context.read<KPIProvider>().loadSpecificKPI(kpiName);
  }

  /// Show detailed view of a KPI
  void _showKPIDetails(KPIIndicator kpi) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(kpi.name),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current performance section
                _buildDetailSection('Performance Actuelle', [
                  _buildDetailRow('Valeur', kpi.formattedValue),
                  _buildDetailRow('Cible', kpi.formattedTarget),
                  _buildDetailRow('Écart', 
                    kpi.targetDifference >= 0 
                      ? '+${kpi.targetDifference.toStringAsFixed(1)}%'
                      : '${kpi.targetDifference.toStringAsFixed(1)}%'
                  ),
                  _buildDetailRow('Statut', 
                    kpi.isTargetMet ? '✅ Objectif atteint' : '❌ Objectif non atteint'
                  ),
                ]),
                
                const SizedBox(height: 16),
                
                // Period and calculation info
                _buildDetailSection('Informations de Calcul', [
                  _buildDetailRow('Période', kpi.period),
                  _buildDetailRow('Dernière mise à jour', _formatLastUpdate(kpi.lastCalculated)),
                  _buildDetailRow('Formule', _getKPIFormula(kpi.name)),
                ]),
                
                const SizedBox(height: 16),
                
                // Improvement suggestions
                if (!kpi.isTargetMet) ...[
                  _buildDetailSection('Suggestions d\'Amélioration', [
                    Text(
                      _getImprovementSuggestion(kpi.name),
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _refreshSpecificKPI(kpi.name);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        );
      },
    );
  }

  /// Build the header section with overall KPI summary
  Widget _buildDashboardHeader(KPIProvider kpiProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.dashboard,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tableau de Bord ISO',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Overall health status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getHealthStatusColor(kpiProvider.overallHealthStatus),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'État: ${kpiProvider.overallHealthStatus}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (kpiProvider.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              'Suivi des 3 objectifs qualité ISO pour la Team Dev',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the main KPI section with the 3 objective cards
  Widget _buildKPISection(KPIProvider kpiProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectifs ISO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Check if we have KPI data
        if (!kpiProvider.hasKPIData && !kpiProvider.isLoading) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.assessment,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune donnée KPI disponible',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cliquez sur actualiser pour calculer les objectifs',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => kpiProvider.loadAllKPIs(),
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculer les KPI'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Display the 3 KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Wide screen: show 3 cards in a row
                return Row(
                  children: [
                    Expanded(child: _buildKPICard(kpiProvider.objective1)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKPICard(kpiProvider.objective2)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKPICard(kpiProvider.objective3)),
                  ],
                );
              } else {
                // Narrow screen: show cards vertically
                return Column(
                  children: [
                    _buildKPICard(kpiProvider.objective1),
                    const SizedBox(height: 16),
                    _buildKPICard(kpiProvider.objective2),
                    const SizedBox(height: 16),
                    _buildKPICard(kpiProvider.objective3),
                  ],
                );
              }
            },
          ),
        ],
      ],
    );
  }

  /// Build a single KPI card
  Widget _buildKPICard(KPIIndicator? kpi) {
    if (kpi == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Calcul en cours...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Title with action buttons
            Row(
              children: [
                Expanded(
                  child: Text(
                    kpi.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Details button (magnifying glass)
                IconButton(
                  onPressed: () => _showKPIDetails(kpi),
                  icon: const Icon(Icons.search, size: 20),
                  tooltip: 'Voir détails',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                // Individual refresh button
                IconButton(
                  onPressed: () => _refreshSpecificKPI(kpi.name),
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Actualiser',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Visual indicator (circular progress)
            Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: kpi.currentValue / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getKPIColor(kpi),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            kpi.formattedValue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'sur ${kpi.formattedTarget}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status and period info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getKPIColor(kpi),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    kpi.isTargetMet ? 'Atteint' : 'Non atteint',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  kpi.period,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a simplified projects overview section
  Widget _buildProjectsOverview(ProjectProvider projectProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projets OpenProject',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.folder,
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${projectProvider.projects.length} projets connectés',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Source: ${projectProvider.projects.isNotEmpty ? "forge2.ebindoo.com" : "Non connecté"}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to detailed projects view
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vue détaillée des projets - À implémenter'),
                      ),
                    );
                  },
                  child: const Text('Voir détails'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build footer with last update information
  Widget _buildFooterInfo(KPIProvider kpiProvider) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations système',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (kpiProvider.hasKPIData) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Dernière mise à jour: ${_formatLastUpdate(kpiProvider.kpiIndicators.first.lastCalculated)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les calculs sont basés sur les données temps réel d\'OpenProject',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // UTILITY METHODS - Helper methods for colors and formatting
  // =============================================================================

  /// Get color based on KPI performance
  Color _getKPIColor(KPIIndicator kpi) {
    if (kpi.isTargetMet) {
      return Colors.green;
    } else if (kpi.currentValue >= (kpi.targetValue * 0.9)) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Get color for overall health status
  Color _getHealthStatusColor(String status) {
    switch (status) {
      case 'Excellent':
        return Colors.green;
      case 'Bon':
        return Colors.orange;
      case 'À améliorer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Format last update time for display
  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Build a detail section for the KPI details dialog
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  /// Build a detail row for KPI information
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the formula description for a KPI
  String _getKPIFormula(String kpiName) {
    if (kpiName.contains('Objectif 1')) {
      return 'Moyenne des 3 taux mensuels du trimestre';
    } else if (kpiName.contains('Objectif 2')) {
      return 'Moyenne des % d\'achèvement des projets du mois';
    } else if (kpiName.contains('Objectif 3')) {
      return 'Nombre de tâches testées / Nombre total de tâches';
    }
    return 'Formule de calcul non définie';
  }

  /// Get improvement suggestion for a KPI
  String _getImprovementSuggestion(String kpiName) {
    if (kpiName.contains('Objectif 1')) {
      return 'Améliorer la performance mensuelle pour augmenter la moyenne trimestrielle. Identifier les causes des retards dans les sprints.';
    } else if (kpiName.contains('Objectif 2')) {
      return 'Réviser l\'estimation des sprints, améliorer la planification, et identifier les blocages récurrents.';
    } else if (kpiName.contains('Objectif 3')) {
      return 'Renforcer les processus de test, automatiser davantage de tests, et s\'assurer que toutes les tâches passent par la phase de test.';
    }
    return 'Analyser les causes profondes et mettre en place un plan d\'amélioration.';
  }
}