import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'dart:convert';
import '../utils/logger.dart';

class DataDiagnosticWidget extends StatefulWidget {
  const DataDiagnosticWidget({super.key});

  @override
  State<DataDiagnosticWidget> createState() => _DataDiagnosticWidgetState();
}

class _DataDiagnosticWidgetState extends State<DataDiagnosticWidget> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _diagnosticData;
  bool _isLoading = false;
  String? _error;
  int? _selectedProjectId;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      setState(() => _isLoading = true);
      await _apiService.init();
      _projects = await _apiService.getProjects();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnostic Données OpenProject'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectSelector(),
            SizedBox(height: 16),
            _buildAnalyzeButton(),
            if (_error != null) ...[SizedBox(height: 16), _buildErrorCard()],
            if (_diagnosticData != null) ...[
              SizedBox(height: 16),
              _buildDiagnosticResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner un projet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_projects.isEmpty && !_isLoading)
              Text('Aucun projet trouvé', style: TextStyle(color: Colors.red)),
            if (_projects.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _selectedProjectId,
                decoration: InputDecoration(
                  labelText: 'Projet',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _projects.map((project) {
                  return DropdownMenuItem<int>(
                    value: project['id'],
                    child: Text(
                      '${project['name']} (ID: ${project['id']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedProjectId = value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_selectedProjectId != null && !_isLoading)
            ? _runDiagnostic
            : null,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.analytics),
        label: Text(
          _isLoading ? 'Analyse...' : 'Analyser la Structure des Données',
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Erreur',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(_error!),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultats du Diagnostic',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Résumé général
        _buildSummaryCard(),
        SizedBox(height: 12),

        // Structure des work packages
        _buildWorkPackagesAnalysis(),
        SizedBox(height: 12),

        // Analyse des types et statuts
        _buildTypesAndStatusesAnalysis(),
        SizedBox(height: 12),

        // Données brutes (collapsible)
        _buildRawDataCard(),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final summary = _diagnosticData!['summary'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Résumé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildSummaryRow(
              'Total Work Packages',
              '${summary['totalWorkPackages']}',
            ),
            _buildSummaryRow(
              'Tâches avec pourcentage',
              '${summary['tasksWithPercentage']}',
            ),
            _buildSummaryRow('Types différents', '${summary['uniqueTypes']}'),
            _buildSummaryRow(
              'Statuts différents',
              '${summary['uniqueStatuses']}',
            ),
            _buildSummaryRow(
              'Tâches potentiellement "feuilles"',
              '${summary['leafTasks']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWorkPackagesAnalysis() {
    final analysis =
        _diagnosticData!['workPackageAnalysis'] as Map<String, dynamic>;

    return Card(
      child: ExpansionTile(
        title: Text('🔍 Analyse des Work Packages'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribution des pourcentages:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...(analysis['percentageDistribution'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${entry.key}%'),
                            Text('${entry.value} tâches'),
                          ],
                        ),
                      );
                    }),

                SizedBox(height: 16),
                Text(
                  'Exemples de tâches:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...(analysis['sampleTasks'] as List<dynamic>).map<Widget>((
                  task,
                ) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task['subject']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Type: ${task['type']} | Status: ${task['status']} | ${task['percentageDone']}%',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesAndStatusesAnalysis() {
    final types = _diagnosticData!['types'] as List<dynamic>;
    final statuses = _diagnosticData!['statuses'] as List<dynamic>;

    return Card(
      child: ExpansionTile(
        title: Text('🏷️ Types et Statuts'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Types de Work Packages:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: types
                      .map<Widget>(
                        (type) => Chip(
                          label: Text('${type['name']} (${type['count']})'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      )
                      .toList(),
                ),

                SizedBox(height: 16),
                Text('Statuts:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: statuses
                      .map<Widget>(
                        (status) => Chip(
                          label: Text('${status['name']} (${status['count']})'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard() {
    return Card(
      child: ExpansionTile(
        title: Text('📄 Données Brutes (JSON)'),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Données complètes du diagnostic')),
                    ElevatedButton.icon(
                      onPressed: _copyRawDataToClipboard,
                      icon: Icon(Icons.copy),
                      label: Text('Copier JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 300,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      JsonEncoder.withIndent('  ').convert(_diagnosticData),
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostic() async {
    if (_selectedProjectId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _diagnosticData = null;
    });

    try {
      Logger.info(
        'Début du diagnostic pour projet $_selectedProjectId',
        tag: 'Widget',
      );

      // Récupère les work packages du projet
      final workPackages = await _apiService.getWorkPackages(
        _selectedProjectId!,
      );

      if (workPackages.isEmpty) {
        throw Exception('Aucun work package trouvé pour ce projet');
      }

      Logger.info(
        '${workPackages.length} work packages récupérés',
        tag: 'Widget',
      );

      // Analyse la structure des données
      final analysis = _analyzeWorkPackages(workPackages);

      setState(() {
        _diagnosticData = analysis;
        _isLoading = false;
      });

      Logger.info('Diagnostic terminé', tag: 'Widget');
    } catch (e) {
      Logger.error('Erreur diagnostic: $e', tag: 'Widget');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _analyzeWorkPackages(
    List<Map<String, dynamic>> workPackages,
  ) {
    Logger.info(
      'Analyse de ${workPackages.length} work packages...',
      tag: 'Widget',
    );

    // Compteurs pour le résumé
    int tasksWithPercentage = 0;
    int leafTasks = 0;

    // Collections pour l'analyse
    final types = <String, int>{};
    final statuses = <String, int>{};
    final percentageDistribution = <String, int>{};
    final sampleTasks = <Map<String, dynamic>>[];

    for (final wp in workPackages) {
      // Analyse du pourcentage
      final percentageDone = wp['percentageDone'];
      if (percentageDone != null) {
        tasksWithPercentage++;

        // Distribution des pourcentages
        final percentageKey = percentageDone.toString();
        percentageDistribution[percentageKey] =
            (percentageDistribution[percentageKey] ?? 0) + 1;
      }

      // Analyse des types
      final type = wp['_links']?['type']?['title']?.toString() ?? 'Unknown';
      types[type] = (types[type] ?? 0) + 1;

      // Analyse des statuts
      final status = wp['_links']?['status']?['title']?.toString() ?? 'Unknown';
      statuses[status] = (statuses[status] ?? 0) + 1;

      // Identification des tâches "feuilles" potentielles
      final isLeaf = _isPotentialLeafTask(wp);
      if (isLeaf) {
        leafTasks++;
      }

      // Échantillons pour affichage
      if (sampleTasks.length < 5 && percentageDone != null) {
        sampleTasks.add({
          'id': wp['id'],
          'subject': wp['subject'] ?? 'Sans titre',
          'type': type,
          'status': status,
          'percentageDone': percentageDone,
          'isLeaf': isLeaf,
        });
      }
    }

    // Trie les distributions
    final sortedTypes = types.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedStatuses = statuses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = {
      'summary': {
        'totalWorkPackages': workPackages.length,
        'tasksWithPercentage': tasksWithPercentage,
        'uniqueTypes': types.length,
        'uniqueStatuses': statuses.length,
        'leafTasks': leafTasks,
      },
      'workPackageAnalysis': {
        'percentageDistribution': percentageDistribution,
        'sampleTasks': sampleTasks,
      },
      'types': sortedTypes
          .map((entry) => {'name': entry.key, 'count': entry.value})
          .toList(),
      'statuses': sortedStatuses
          .map((entry) => {'name': entry.key, 'count': entry.value})
          .toList(),
      'rawSample': workPackages.take(3).toList(), // 3 premiers pour inspection
    };

    Logger.info('📈 Analyse terminée:', tag: 'Widget');
    Logger.info(
      '  - ${tasksWithPercentage} tâches avec pourcentage sur ${workPackages.length}',
      tag: 'Widget',
    );
    Logger.info(
      '- ${leafTasks} tâches potentiellement "feuilles"',
      tag: 'Widget',
    );
    Logger.info('- ${types.length} types différents', tag: 'Widget');
    Logger.info('- ${statuses.length} statuts différents', tag: 'Widget');

    return result;
  }

  /// Heuristique simple pour identifier les tâches "feuilles"
  bool _isPotentialLeafTask(Map<String, dynamic> wp) {
    final type =
        wp['_links']?['type']?['title']?.toString().toLowerCase() ?? '';
    final subject = wp['subject']?.toString().toLowerCase() ?? '';
    final percentageDone = wp['percentageDone'];
    // Exclut les types "conteneurs"
    if (type.contains('milestone') ||
        type.contains('phase') ||
        type.contains('epic') ||
        type.contains('project')) {
      return false;
    }

    // Exclut les tâches avec des mots-clés "parent" dans le titre
    if (subject.contains('phase') ||
        subject.contains('milestone') ||
        subject.contains('epic')) {
      return false;
    }

    // Doit avoir un pourcentage défini
    if (percentageDone == null) {
      return false;
    }

    // TODO: Ajouter d'autres heuristiques basées sur vos observations
    // Par exemple, vérifier s'il y a des children via l'API

    return true;
  }

  void _copyRawDataToClipboard() {
    if (_diagnosticData != null) {
      final jsonString = JsonEncoder.withIndent('  ').convert(_diagnosticData);
      Clipboard.setData(ClipboardData(text: jsonString));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Données copiées dans le presse-papier'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
