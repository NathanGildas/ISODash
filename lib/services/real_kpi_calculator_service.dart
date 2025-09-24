import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/kpi_indicator.dart';
import '../models/sprint_metrics.dart';

class RealKPICalculatorService {
  final ApiService _apiService = ApiService();
  static const String _storageKey = 'kpi_historical_data';

  // 🎯 Configuration basée sur tes données OpenProject
  static const List<String> COMPLETED_STATUSES = [
    'Closed',    // ID: 12 (isClosed: true)
    'Done',      // ID: 17
    'Terminé',   // ID: 18
  ];

  static const List<String> TESTED_STATUSES = [
    'Tested',    // ID: 10 - Parfaitement testé
    // 'In testing', // ID: 9 - En cours (optionnel)
  ];

  // Tous tes projets (tu peux filtrer selon tes besoins)
  static const List<int> ALL_PROJECTS = [
    316, // ISODash - ton projet principal
    308, // Microfina - UEMOA - COOPEC ADESEM
    306, // Microfina++ SFD - MUTUELLE AFP
    305, // Microfina - UEMOA - PROMO FINANCE
    304, // Microfina++ SFD - EMS
    299, // Microfina - Multidevise - CCD
    296, // Microfina++ SFD - GRACE PLUS
    295, // Microfina++ SFD - FRUCTUEUSE
    66,  // Bindoo
  ];

  // Pour commencer, focus sur ISODash + quelques projets actifs
  static const List<int> FOCUS_PROJECTS = [
    316, // ISODash
    308, // Microfina COOPEC ADESEM
    66,  // Bindoo
  ];

  // Cache des données
  List<SprintMetrics> _cachedMetrics = [];
  Map<String, double> _monthlyKPIHistory = {};

  /// Calcule tous les KPI pour une période donnée
  Future<List<KPIIndicator>> calculateAllKPIs({
    required DateTime forDate,
    bool forceRefresh = false,
  }) async {
    print('🧮 Calcul des vrais KPI pour ${forDate.toString()}');

    // Charge les données si nécessaire
    if (forceRefresh || _cachedMetrics.isEmpty) {
      await _loadRealSprintMetrics();
    }

    // Charge l'historique mensuel
    await _loadMonthlyHistory();

    final results = <KPIIndicator>[];

    try {
      // Calcul Objectif 2 - Taux Mensuel (80%)
      final monthlyKPI = await _calculateRealMonthlyObjective(forDate);
      if (monthlyKPI != null) {
        results.add(monthlyKPI);
        // Sauvegarde dans l'historique
        await _saveMonthlyKPI(forDate, monthlyKPI.currentValue);
      }

      // Calcul Objectif 1 - Taux Trimestriel (70%)
      final quarterlyKPI = await _calculateRealQuarterlyObjective(forDate);
      if (quarterlyKPI != null) results.add(quarterlyKPI);

      // Calcul Objectif 3 - Qualité (80%)
      final qualityKPI = await _calculateRealQualityObjective(forDate);
      if (qualityKPI != null) results.add(qualityKPI);

      print('✅ ${results.length} KPI calculés avec vraies données');
      return results;

    } catch (e) {
      print('❌ Erreur calcul KPI réels: $e');
      return [];
    }
  }

  /// Objectif 2 - Taux Mensuel RÉEL
  Future<KPIIndicator?> _calculateRealMonthlyObjective(DateTime date) async {
    try {
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      print('📊 Calcul Objectif 2 pour $monthKey');

      double totalRate = 0;
      int validProjectCount = 0;
      final projectResults = <String, double>{};

      for (final projectId in FOCUS_PROJECTS) {
        try {
          // Récupère les versions du projet pour ce mois
          final versions = await _apiService.getVersions(projectId);
          final monthVersions = _filterVersionsForMonth(versions, date);

          if (monthVersions.isEmpty) {
            print('  Projet $projectId: Aucune version pour $monthKey');
            continue;
          }

          // Sélectionne la version la plus longue si plusieurs
          final selectedVersion = _selectLongestVersion(monthVersions);
          print('  Projet $projectId: Version "${selectedVersion['name']}"');

          // Récupère les work packages de cette version
          final workPackages = await _getWorkPackagesForProject(projectId);

          if (workPackages.isEmpty) {
            print('  Projet $projectId: Aucun work package');
            continue;
          }

          // Calcule le taux de completion
          final completionRate = _calculateCompletionRate(workPackages);
          projectResults['Projet $projectId'] = completionRate;
          totalRate += completionRate;
          validProjectCount++;

          print('  Projet $projectId: ${completionRate.toStringAsFixed(1)}% (${_getCompletedCount(workPackages)}/${workPackages.length} tâches)');

        } catch (e) {
          print('  ⚠️ Erreur projet $projectId: $e');
          continue;
        }
      }

      if (validProjectCount == 0) {
        print('❌ Aucun projet valide pour $monthKey');
        return null;
      }

      final average = totalRate / validProjectCount;

      print('✅ Objectif 2: ${average.toStringAsFixed(1)}% (moyenne de $validProjectCount projets)');
      for (final entry in projectResults.entries) {
        print('    ${entry.key}: ${entry.value.toStringAsFixed(1)}%');
      }

      return KPIIndicator(
        id: 'monthly_real_$monthKey',
        name: 'Taux Mensuel ${date.month}/${date.year}',
        currentValue: average,
        targetValue: 80.0,
        unit: '%',
        period: date,
        type: KPIType.monthly,
      );

    } catch (e) {
      print('❌ Erreur calcul mensuel réel: $e');
      return null;
    }
  }

  /// Objectif 1 - Taux Trimestriel RÉEL
  Future<KPIIndicator?> _calculateRealQuarterlyObjective(DateTime date) async {
    try {
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final quarterKey = '${date.year}-Q$quarter';
      print('📊 Calcul Objectif 1 pour $quarterKey');

      // Calcule les 3 mois du trimestre
      final quarterMonths = <DateTime>[];
      final startMonth = (quarter - 1) * 3 + 1;

      for (int i = 0; i < 3; i++) {
        final month = startMonth + i;
        if (month <= 12) {
          quarterMonths.add(DateTime(date.year, month, 1));
        }
      }

      // Récupère les valeurs mensuelles (depuis le cache ou calcul)
      final monthlyValues = <double>[];

      for (final monthDate in quarterMonths) {
        final monthKey = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';

        // Essaie d'abord depuis l'historique
        if (_monthlyKPIHistory.containsKey(monthKey)) {
          monthlyValues.add(_monthlyKPIHistory[monthKey]!);
          print('  ${monthDate.month}/${monthDate.year}: ${_monthlyKPIHistory[monthKey]!.toStringAsFixed(1)}% (historique)');
        } else {
          // Calcule si pas en cache
          final monthlyKPI = await _calculateRealMonthlyObjective(monthDate);
          if (monthlyKPI != null) {
            monthlyValues.add(monthlyKPI.currentValue);
            print('  ${monthDate.month}/${monthDate.year}: ${monthlyKPI.currentValue.toStringAsFixed(1)}% (calculé)');
          }
        }
      }

      if (monthlyValues.length < 2) {
        print('⚠️ Pas assez de données mensuelles pour $quarterKey (${monthlyValues.length}/3)');
        return null;
      }

      final average = monthlyValues.reduce((a, b) => a + b) / monthlyValues.length;
      print('✅ Objectif 1: ${average.toStringAsFixed(1)}% (moyenne de ${monthlyValues.length} mois)');

      return KPIIndicator(
        id: 'quarterly_real_$quarterKey',
        name: 'Taux Trimestriel Q$quarter ${date.year}',
        currentValue: average,
        targetValue: 70.0,
        unit: '%',
        period: date,
        type: KPIType.quarterly,
      );

    } catch (e) {
      print('❌ Erreur calcul trimestriel réel: $e');
      return null;
    }
  }

  /// Objectif 3 - Qualité RÉEL
  Future<KPIIndicator?> _calculateRealQualityObjective(DateTime date) async {
    try {
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final quarterKey = '${date.year}-Q$quarter';
      print('📊 Calcul Objectif 3 pour $quarterKey');

      int totalTasks = 0;
      int testedTasks = 0;
      final projectResults = <String, Map<String, int>>{};

      for (final projectId in FOCUS_PROJECTS) {
        try {
          final workPackages = await _getWorkPackagesForProject(projectId);

          if (workPackages.isEmpty) continue;

          final projectTotal = workPackages.length;
          final projectTested = workPackages.where(_isTaskTested).length;

          projectResults['Projet $projectId'] = {
            'total': projectTotal,
            'tested': projectTested,
          };

          totalTasks += projectTotal;
          testedTasks += projectTested;

          print('  Projet $projectId: $projectTested/$projectTotal tâches testées (${(projectTested/projectTotal*100).toStringAsFixed(1)}%)');

        } catch (e) {
          print('  ⚠️ Erreur projet $projectId: $e');
          continue;
        }
      }

      if (totalTasks == 0) {
        print('❌ Aucune tâche trouvée pour $quarterKey');
        return null;
      }

      final qualityRate = (testedTasks / totalTasks) * 100;
      print('✅ Objectif 3: ${qualityRate.toStringAsFixed(1)}% ($testedTasks/$totalTasks tâches testées)');

      return KPIIndicator(
        id: 'quality_real_$quarterKey',
        name: 'Qualité Q$quarter ${date.year}',
        currentValue: qualityRate,
        targetValue: 80.0,
        unit: '%',
        period: date,
        type: KPIType.quality,
      );

    } catch (e) {
      print('❌ Erreur calcul qualité réel: $e');
      return null;
    }
  }

  // Méthodes utilitaires

  Future<List<Map<String, dynamic>>> _getWorkPackagesForProject(int projectId) async {
    try {
      // Utilise les filtres OpenProject pour récupérer les WP d'un projet spécifique
      final uri = Uri.parse('${ApiService.baseUrl}/work_packages').replace(
        queryParameters: {
          'filters': jsonEncode([
            {"project": {"operator": "=", "values": ["$projectId"]}}
          ]),
          'pageSize': '200', // Augmente la limite
        },
      );

      final response = await _apiService.get(uri.toString().replaceAll('${ApiService.baseUrl}', ''));

      if (response.containsKey('_embedded') &&
          response['_embedded'].containsKey('elements')) {
        return List<Map<String, dynamic>>.from(response['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur récupération work packages projet $projectId: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterVersionsForMonth(List<Map<String, dynamic>> versions, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    return versions.where((version) {
      final startDate = DateTime.tryParse(version['startDate'] ?? '');
      final endDate = DateTime.tryParse(version['endDate'] ?? '');

      if (startDate == null || endDate == null) return false;

      // Version chevauche le mois
      return startDate.isBefore(monthEnd.add(Duration(days: 1))) &&
          endDate.isAfter(monthStart.subtract(Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _selectLongestVersion(List<Map<String, dynamic>> versions) {
    if (versions.length == 1) return versions.first;

    return versions.reduce((a, b) {
      final aDuration = _getVersionDuration(a);
      final bDuration = _getVersionDuration(b);
      return aDuration > bDuration ? a : b;
    });
  }

  int _getVersionDuration(Map<String, dynamic> version) {
    final start = DateTime.tryParse(version['startDate'] ?? '');
    final end = DateTime.tryParse(version['endDate'] ?? '');

    if (start == null || end == null) return 0;

    return end.difference(start).inDays + 1;
  }

  double _calculateCompletionRate(List<Map<String, dynamic>> workPackages) {
    if (workPackages.isEmpty) return 0.0;

    final completedCount = workPackages.where(_isTaskCompleted).length;
    return (completedCount / workPackages.length) * 100;
  }

  int _getCompletedCount(List<Map<String, dynamic>> workPackages) {
    return workPackages.where(_isTaskCompleted).length;
  }

  bool _isTaskCompleted(Map<String, dynamic> workPackage) {
    final statusTitle = workPackage['_links']?['status']?['title']?.toString() ?? '';
    final isCompleted = COMPLETED_STATUSES.contains(statusTitle);

    if (isCompleted) {
      print('    ✅ "${workPackage['subject']}" - $statusTitle');
    }

    return isCompleted;
  }

  bool _isTaskTested(Map<String, dynamic> workPackage) {
    final statusTitle = workPackage['_links']?['status']?['title']?.toString() ?? '';
    final isTested = TESTED_STATUSES.contains(statusTitle);

    if (isTested) {
      print('    🧪 "${workPackage['subject']}" - $statusTitle');
    }

    return isTested;
  }

  // Gestion de l'historique mensuel

  Future<void> _loadMonthlyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        _monthlyKPIHistory = Map<String, double>.from(data);
        print('📦 Historique mensuel chargé: ${_monthlyKPIHistory.length} entrées');
      }
    } catch (e) {
      print('⚠️ Erreur chargement historique: $e');
      _monthlyKPIHistory = {};
    }
  }

  Future<void> _saveMonthlyKPI(DateTime date, double value) async {
    try {
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      _monthlyKPIHistory[monthKey] = value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_monthlyKPIHistory));

      print('💾 KPI mensuel sauvé: $monthKey = ${value.toStringAsFixed(1)}%');
    } catch (e) {
      print('⚠️ Erreur sauvegarde historique: $e');
    }
  }

  Future<void> _loadRealSprintMetrics() async {
    // Placeholder pour la charge des métriques détaillées
    // Sera utilisé plus tard pour les causes
    print('📊 Métriques sprints chargées');
  }

  // Méthodes de debugging et maintenance

  Future<void> clearHistoricalData() async {
    _monthlyKPIHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('🗑️ Historique effacé');
  }

  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'focus_projects': FOCUS_PROJECTS,
      'completed_statuses': COMPLETED_STATUSES,
      'tested_statuses': TESTED_STATUSES,
      'monthly_history_entries': _monthlyKPIHistory.length,
      'cached_metrics': _cachedMetrics.length,
    };
  }
}