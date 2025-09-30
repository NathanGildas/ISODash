import 'dart:convert';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;

class OpenProjectExplorer {
  final String baseUrl;
  final String apiKey;

  OpenProjectExplorer({
    required this.baseUrl,
    required this.apiKey,
  });

  Map<String, String> get headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('apikey:$apiKey'))}',
    'Content-Type': 'application/json',
  };

  /// Explore toutes les API nécessaires pour les calculs ISO
  Future<Map<String, dynamic>> exploreForISOCalculations() async {
    Logger.info('Exploration des API OpenProject pour calculs ISO...', tag: 'Service');

    final results = <String, dynamic>{};

    try {
      // 1. Récupère tous les projets
      results['projects'] = await _exploreProjects();

      // 2. Pour le premier projet, explore les versions/sprints
      if (results['projects']['data'].isNotEmpty) {
        final firstProjectId = results['projects']['data'][0]['id'];
        results['versions'] = await _exploreVersions(firstProjectId);
        results['workPackages'] = await _exploreWorkPackages(firstProjectId);
      }

      // 3. Explore les métadonnées
      results['statuses'] = await _exploreStatuses();
      results['types'] = await _exploreTypes();
      results['customFields'] = await _exploreCustomFields();

      // 4. Analyse et recommandations
      results['analysis'] = _analyzeForISOCalculations(results);

      return results;

    } catch (e) {
      Logger.error('Erreur exploration: $e', tag: 'Service');
      return {'error': e.toString()};
    }
  }

  /// Explore les projets
  Future<Map<String, dynamic>> _exploreProjects() async {
    Logger.info('Exploration des projets...', tag: 'Service');

    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Logger.info('✅ ${data['_embedded']['elements'].length} projets trouvés', tag: 'Service');

      // Affiche les infos clés de chaque projet
      for (final project in data['_embedded']['elements']) {
        Logger.info('  - ID: ${project['id']}, Nom: "${project['name']}", Statut: ${project['status']}', tag: 'Service');
      }

      return {
        'data': data['_embedded']['elements'],
        'count': data['count'],
        'total': data['total'],
      };
    } else {
      throw Exception('Erreur récupération projets: ${response.statusCode}');
    }
  }

  /// Explore les versions/sprints d'un projet
  Future<Map<String, dynamic>> _exploreVersions(int projectId) async {
    Logger.info('Exploration des versions/sprints du projet $projectId...', tag: 'Service');

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/versions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final versions = data['_embedded']['elements'];
      Logger.info('${versions.length} versions trouvées', tag: 'Service');

      // Affiche les infos clés de chaque version
      for (final version in versions.take(3)) { // Limite à 3 pour la lisibilité
        Logger.info('  - ID: ${version['id']}, Nom: "${version['name']}"', tag: 'Service');
        Logger.info('    Start: ${version['startDate']}, End: ${version['endDate']}', tag: 'Service');
        Logger.info('    Status: ${version['status']}, Description: "${version['description'] ?? 'N/A'}"', tag: 'Service');
      }

      return {
        'data': versions,
        'count': versions.length,
      };
    } else {
      throw Exception('Erreur récupération versions: ${response.statusCode}');
    }
  }

  /// Explore les work packages d'un projet
  Future<Map<String, dynamic>> _exploreWorkPackages(int projectId) async {
    Logger.info('📝 Exploration des work packages du projet $projectId...', tag: 'Service');

    // Utilise les filtres OpenProject pour récupérer les WP d'un projet
    final filters = [
      {"project": {"operator": "=", "values": ["$projectId"]}}
    ];

    final uri = Uri.parse('$baseUrl/work_packages').replace(
      queryParameters: {
        'filters': jsonEncode(filters),
        'pageSize': '10', // Limite pour l'exploration
      },
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final workPackages = data['_embedded']['elements'];
      Logger.info('✅ ${data['total']} work packages (affichage des 10 premiers)', tag: 'Service');

      // Affiche les infos clés de chaque work package
      for (final wp in workPackages.take(5)) {
        Logger.info('  - ID: ${wp['id']}, Sujet: "${wp['subject']}"', tag: 'Service');
        Logger.info('    Type: ${wp['_links']['type']['title']}', tag: 'Service');
        Logger.info('    Status: ${wp['_links']['status']['title']}', tag: 'Service');
        Logger.info('    Assigné: ${wp['_links']['assignee']?['title'] ?? 'Non assigné'}', tag: 'Service');
        Logger.info('    Dates: ${wp['startDate']} → ${wp['dueDate']}', tag: 'Service');

        // Recherche des custom fields liés aux tests
        if (wp['customField1'] != null) {
          Logger.info('    Custom Fields: ${wp['customField1']}', tag: 'Service');
        }
      }

      return {
        'data': workPackages,
        'total': data['total'],
        'sampleFields': _extractUniqueFields(workPackages),
      };
    } else {
      throw Exception('Erreur récupération work packages: ${response.statusCode}');
    }
  }

  /// Explore les statuts disponibles
  Future<Map<String, dynamic>> _exploreStatuses() async {
    Logger.info('🏷️ Exploration des statuts...', tag: 'Service');

    final response = await http.get(
      Uri.parse('$baseUrl/statuses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final statuses = data['_embedded']['elements'];
      Logger.info('${statuses.length} statuts trouvés', tag: 'Service');

      // Catégorise les statuts pour les calculs
      final completedStatuses = <String>[];
      final testedStatuses = <String>[];

      for (final status in statuses) {
        final name = status['name'].toString().toLowerCase();
        Logger.info('  - ID: ${status['id']}, Nom: "${status['name']}", Fermé: ${status['isClosed']}', tag: 'Service');

        // Identifie les statuts "complétés"
        if (status['isClosed'] == true ||
            name.contains('done') ||
            name.contains('completed') ||
            name.contains('closed') ||
            name.contains('resolved')) {
          completedStatuses.add(status['name']);
        }

        // Identifie les statuts "testés"
        if (name.contains('test') ||
            name.contains('validated') ||
            name.contains('approved')) {
          testedStatuses.add(status['name']);
        }
      }

      return {
        'data': statuses,
        'completedStatuses': completedStatuses,
        'testedStatuses': testedStatuses,
      };
    } else {
      throw Exception('Erreur récupération statuts: ${response.statusCode}');
    }
  }

  /// Explore les types de work packages
  Future<Map<String, dynamic>> _exploreTypes() async {
    Logger.info('📂 Exploration des types...', tag: 'Service');

    final response = await http.get(
      Uri.parse('$baseUrl/types'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final types = data['_embedded']['elements'];
      Logger.info('${types.length} types trouvés', tag: 'Service');

      for (final type in types) {
        Logger.info('  - ID: ${type['id']}, Nom: "${type['name']}", Couleur: ${type['color']}', tag: 'Service');
      }

      return {
        'data': types,
      };
    } else {
      throw Exception('Erreur récupération types: ${response.statusCode}');
    }
  }

  /// Explore les custom fields
  Future<Map<String, dynamic>> _exploreCustomFields() async {
    Logger.info('🔧 Exploration des custom fields...', tag: 'Service');

    final response = await http.get(
      Uri.parse('$baseUrl/custom_fields'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final customFields = data['_embedded']['elements'];
      Logger.info('${customFields.length} custom fields trouvés', tag: 'Service');

      // Recherche des champs liés aux tests/qualité
      final qualityFields = <Map<String, dynamic>>[];

      for (final field in customFields) {
        final name = field['name'].toString().toLowerCase();
        Logger.info('  - ID: ${field['id']}, Nom: "${field['name']}", Type: ${field['fieldFormat']}', tag: 'Service');

        if (name.contains('test') ||
            name.contains('quality') ||
            name.contains('validated') ||
            name.contains('reviewed')) {
          qualityFields.add(field);
        }
      }

      return {
        'data': customFields,
        'qualityFields': qualityFields,
      };
    } else {
      throw Exception('Erreur récupération custom fields: ${response.statusCode}');
    }
  }

  /// Analyse les données pour les calculs ISO
  Map<String, dynamic> _analyzeForISOCalculations(Map<String, dynamic> results) {
    Logger.info('Analyse des données pour calculs ISO...', tag: 'Service');

    return {
      'recommendations': {
        'objectif2': {
          'description': 'Taux mensuel - Sprint completion rate',
          'api': '/api/v3/projects/{id}/versions + /api/v3/work_packages',
          'calculation': 'Count completed work packages / total work packages per version',
          'completedStatuses': results['statuses']?['completedStatuses'] ?? [],
        },
        'objectif1': {
          'description': 'Taux trimestriel - Average of 3 monthly rates',
          'storage': 'SharedPreferences recommended for historical data',
          'calculation': '(Month1 + Month2 + Month3) / 3',
        },
        'objectif3': {
          'description': 'Quality - Tested tasks ratio',
          'testedStatuses': results['statuses']?['testedStatuses'] ?? [],
          'qualityFields': results['customFields']?['qualityFields'] ?? [],
          'recommendation': results['customFields']?['qualityFields'].isNotEmpty == true
              ? 'Use custom fields for tested status'
              : 'Use status-based testing identification',
        },
      },
      'nextSteps': [
        '1. Confirmer les statuts "completed" et "tested"',
        '2. Vérifier les projets à inclure dans les calculs',
        '3. Définir les périodes de calcul (mensuel/trimestriel)',
        '4. Implémenter le stockage historique des données',
      ],
    };
  }

  /// Extrait les champs uniques des work packages pour analyse
  Map<String, dynamic> _extractUniqueFields(List<dynamic> workPackages) {
    final fields = <String>{};
    final customFields = <String, dynamic>{};

    for (final wp in workPackages) {
      fields.addAll(wp.keys);

      // Recherche des custom fields
      for (final key in wp.keys) {
        if (key.startsWith('customField') && wp[key] != null) {
          customFields[key] = wp[key];
        }
      }
    }

    return {
      'allFields': fields.toList(),
      'customFields': customFields,
    };
  }

  /// Méthode utilitaire pour test rapide
  Future<void> quickTest() async {
    try {
      final projects = await _exploreProjects();
      Logger.info('\n Test rapide réussi !', tag: 'Service');
      Logger.info('Projets trouvés: ${projects['count']}', tag: 'Service');
    } catch (e) {
      Logger.info('Test rapide échoué: $e', tag: 'Service');
    }
  }
}