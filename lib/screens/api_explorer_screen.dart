import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/openproject_explorer.dart';
import 'dart:convert';

class APIExplorerScreen extends StatefulWidget {
  const APIExplorerScreen({super.key});

  @override
  _APIExplorerScreenState createState() => _APIExplorerScreenState();
}

class _APIExplorerScreenState extends State<APIExplorerScreen> {
  final _apiKeyController = TextEditingController();
  OpenProjectExplorer? _explorer;
  Map<String, dynamic>? _explorationResults;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenProject API Explorer'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApiKeyInput(),
            SizedBox(height: 24),
            _buildActionButtons(),
            if (_error != null) ...[
              SizedBox(height: 16),
              _buildErrorCard(),
            ],
            if (_explorationResults != null) ...[
              SizedBox(height: 24),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Configuration API',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key OpenProject',
                hintText: 'Votre clé API...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Coller depuis le presse-papier',
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 8),
            Text(
              'URL: https://forge2.ebindoo.com/api/v3',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _testConnection,
            icon: _isLoading
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.wifi_tethering),
            label: Text(_isLoading ? 'Test...' : 'Test Connexion'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _exploreAPIs,
            icon: _isLoading
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.search),
            label: Text(_isLoading ? 'Exploration...' : 'Explorer APIs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Erreur',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(_error!),
            SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _error = null),
                  icon: Icon(Icons.close),
                  label: Text('Fermer'),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _copyErrorToClipboard,
                  icon: Icon(Icons.copy),
                  label: Text('Copier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Résultats de l\'exploration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: _exportResults,
              icon: Icon(Icons.download),
              label: Text('Exporter'),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Projets
        if (_explorationResults!['projects'] != null)
          _buildProjectsCard(),

        SizedBox(height: 12),

        // Statuts
        if (_explorationResults!['statuses'] != null)
          _buildStatusCard(),

        SizedBox(height: 12),

        // Recommandations ISO
        if (_explorationResults!['analysis'] != null)
          _buildRecommendationsCard(),
      ],
    );
  }

  Widget _buildProjectsCard() {
    final projects = _explorationResults!['projects'];

    return Card(
      child: ExpansionTile(
        title: Text('Projets (${projects['count']})'),
        subtitle: Text('${projects['total']} projets au total'),
        leading: Icon(Icons.folder, color: Colors.blue),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: (projects['data'] as List).take(5).map<Widget>((project) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: project['status'] == 'active' ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ID: ${project['id']} • ${project['status']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statuses = _explorationResults!['statuses'];

    return Card(
      child: ExpansionTile(
        title: Text('Statuts & Calculs ISO'),
        subtitle: Text('${(statuses['data'] as List).length} statuts disponibles'),
        leading: Icon(Icons.label, color: Colors.orange),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statuts "Completed"
                Text(
                  'Statuts "Completed" identifiés:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (statuses['completedStatuses'] as List).map<Widget>((status) {
                    return Chip(
                      label: Text(status),
                      backgroundColor: Colors.green.shade100,
                      labelStyle: TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),

                SizedBox(height: 16),

                // Statuts "Tested"
                Text(
                  'Statuts "Tested" identifiés:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 8),
                if ((statuses['testedStatuses'] as List).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: (statuses['testedStatuses'] as List).map<Widget>((status) {
                      return Chip(
                        label: Text(status),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucun statut "tested" automatiquement détecté. Vérifiez les custom fields.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final analysis = _explorationResults!['analysis'];
    final recommendations = analysis['recommendations'];

    return Card(
      child: ExpansionTile(
        title: Text('Recommandations pour Calculs ISO'),
        subtitle: Text('Configuration suggérée'),
        leading: Icon(Icons.lightbulb, color: Colors.amber),
        initiallyExpanded: true,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildObjectiveRecommendation('Objectif 2 (Mensuel)', recommendations['objectif2']),
                SizedBox(height: 12),
                _buildObjectiveRecommendation('Objectif 1 (Trimestriel)', recommendations['objectif1']),
                SizedBox(height: 12),
                _buildObjectiveRecommendation('Objectif 3 (Qualité)', recommendations['objectif3']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveRecommendation(String title, Map<String, dynamic> rec) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            rec['description'] ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (rec['api'] != null) ...[
            SizedBox(height: 4),
            Text(
              'API: ${rec['api']}',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }

  // Actions
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _apiKeyController.text = data!.text!;
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez saisir votre API Key');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _explorer = OpenProjectExplorer(apiKey: _apiKeyController.text.trim());
      await _explorer!.quickTest();

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Connexion réussie !'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _exploreAPIs() async {
    if (_explorer == null) {
      await _testConnection();
      if (_explorer == null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _explorer!.exploreForISOCalculations();

      setState(() {
        _isLoading = false;
        _explorationResults = results;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _copyErrorToClipboard() {
    if (_error != null) {
      Clipboard.setData(ClipboardData(text: _error!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur copiée dans le presse-papier')),
      );
    }
  }

  void _exportResults() {
    if (_explorationResults != null) {
      final jsonString = JsonEncoder.withIndent('  ').convert(_explorationResults);
      Clipboard.setData(ClipboardData(text: jsonString));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Résultats exportés vers le presse-papier'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}