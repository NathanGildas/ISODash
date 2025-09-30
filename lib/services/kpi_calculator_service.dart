import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/kpi_indicator.dart';
import '../utils/logger.dart';

/// Service de calcul des KPI ISO selon les spécifications métier précises
class KPICalculatorService {
  final ApiService _apiService = ApiService();
  static const String _exclusionKey = 'excluded_projects';
  static const String _historicalDataKey = 'kpi_historical_data';

  // Cache pour éviter les appels API répétés
  final Map<String, dynamic> _cache = {};
  Map<String, double> _monthlyKPIHistory = {};
  Set<int> _excludedProjectIds = {};

  // Mode de test - inclut les projets/versions/tâches fermés
  // SECURITY: Default to false for production safety
  bool _testMode = false;

  /// ============================================================================
  /// POINT D'ENTRÉE PRINCIPAL
  /// ============================================================================

  /// Calcule tous les KPI pour une période donnée
  Future<List<KPIIndicator>> calculateAllKPIs({
    required DateTime forDate,
    bool forceRefresh = false,
  }) async {
    Logger.info('Calcul KPI pour ${_formatDate(forDate)}', tag: 'KPI');

    try {
      await _apiService.init();
      if (!_apiService.hasCredentials) {
        throw Exception('Aucun credential configuré');
      }

      await _loadExcludedProjects();
      await _loadMonthlyHistory();

      if (forceRefresh) {
        _cache.clear();
      }

      final results = <KPIIndicator>[];

      // Objectif 2 - Taux Mensuel (80%)
      final monthlyKPI = await _calculateObjective2Monthly(forDate);
      if (monthlyKPI != null) {
        results.add(monthlyKPI);
        await _saveMonthlyKPI(forDate, monthlyKPI.currentValue);
      }

      // Objectif 1 - Taux Trimestriel (70%) - Moyenne des 3 mois
      final quarterlyKPI = await _calculateObjective1Quarterly(forDate);
      if (quarterlyKPI != null) results.add(quarterlyKPI);

      // Objectif 3 - Qualité Trimestriel (80%) - Taux de finalisation
      final qualityKPI = await _calculateObjective3Quality(forDate);
      if (qualityKPI != null) results.add(qualityKPI);

      Logger.success('${results.length} KPI calculés avec succès', tag: 'KPI');
      return results;
    } catch (e) {
      Logger.error('Erreur calcul KPI', error: e, tag: 'KPI');
      return [];
    }
  }

  /// ============================================================================
  /// OBJECTIF 2 - TAUX MENSUEL (80%)
  /// ============================================================================

  /// Calcule l'Objectif 2: taux de progression global des projets pour le mois
  Future<KPIIndicator?> _calculateObjective2Monthly(DateTime month) async {
    try {
      final monthKey = _formatMonth(month);
      Logger.info('Calcul Objectif 2 pour $monthKey', tag: 'KPI');

      // Récupère tous les projets actifs
      final allProjects = await _getActiveProjects();
      final includedProjects = allProjects
          .where((p) => !_excludedProjectIds.contains(p['id']))
          .toList();

      if (includedProjects.isEmpty) {
        Logger.error(' Aucun projet inclus pour $monthKey', tag: 'KPI');
        return null;
      }

      Logger.info(
        '📋 ${includedProjects.length} projets inclus (${_excludedProjectIds.length} exclus)',
        tag: 'KPI',
      );

      double totalProgress = 0;
      int validProjects = 0;
      final projectResults = <String, double>{};

      for (final project in includedProjects) {
        final projectId = project['id'];
        final projectName = project['name'] ?? 'Projet $projectId';

        try {
          // 1. Trouve le sprint du mois pour ce projet
          final monthSprint = await _findMonthSprintForProject(
            projectId,
            month,
          );

          if (monthSprint == null) {
            Logger.info(
              '$projectName: Aucun sprint pour $monthKey',
              tag: 'KPI',
            );
            continue;
          }

          // 2. Calcule la progression du sprint
          final sprintProgress = await _calculateSprintProgress(
            projectId,
            monthSprint,
          );

          if (sprintProgress == null) {
            Logger.info(
              '$projectName: Impossible de calculer la progression',
              tag: 'KPI',
            );
            continue;
          }

          projectResults[projectName] = sprintProgress;
          totalProgress += sprintProgress;
          validProjects++;

          Logger.success(
            '  ✅ $projectName: ${sprintProgress.toStringAsFixed(1)}% (sprint: ${monthSprint['name']})',
            tag: 'KPI',
          );
        } catch (e) {
          Logger.error('   $projectName: Erreur $e', tag: 'KPI');
          continue;
        }
      }

      if (validProjects == 0) {
        Logger.error(' Aucun projet valide pour $monthKey', tag: 'KPI');
        return null;
      }

      final averageProgress = totalProgress / validProjects;

      Logger.info('Résultats par projet:', tag: 'KPI');
      projectResults.forEach((name, progress) {
        Logger.info('- $name: ${progress.toStringAsFixed(1)}%', tag: 'KPI');
      });

      Logger.info(
        '✅ Objectif 2: ${averageProgress.toStringAsFixed(1)}% (moyenne de $validProjects projets)',
        tag: 'KPI',
      );

      return KPIIndicator(
        id: 'obj2_$monthKey',
        name: 'Objectif 2 - ${_getMonthName(month)} ${month.year}',
        currentValue: averageProgress,
        targetValue: 80.0,
        unit: '%',
        period: month,
        type: KPIType.monthly,
      );
    } catch (e) {
      Logger.error(' Erreur Objectif 2: $e', tag: 'KPI');
      return null;
    }
  }

  /// Trouve le sprint/version d'un projet correspondant au mois donné
  Future<Map<String, dynamic>?> _findMonthSprintForProject(
    int projectId,
    DateTime month,
  ) async {
    final cacheKey = 'versions_${projectId}_${_formatMonth(month)}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('/projects/$projectId/versions');

      if (response['_embedded'] == null) {
        return null;
      }

      final versions = List<Map<String, dynamic>>.from(
        response['_embedded']['elements'] ?? [],
      );

      if (versions.isEmpty) {
        return null;
      }

      // Calcule les bornes du mois
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      Map<String, dynamic>? bestVersion;
      int maxOverlapDays = 0;

      for (final version in versions) {
        final startDate = version['startDate'];
        final endDate = version['endDate'];

        // 🧪 Mode test: accepte les versions même sans dates complètes
        if (!_testMode && (startDate == null || endDate == null)) {
          continue;
        }

        // Si on n'a pas de dates, on essaie d'autres critères en mode test
        if (startDate == null || endDate == null) {
          if (_testMode) {
            Logger.info(
              '    📦 ${version['name']}: Version sans dates - incluse en mode test',
              tag: 'KPI',
            );
            // En mode test, on peut inclure cette version avec un score de 1 jour
            if (maxOverlapDays == 0) {
              bestVersion = version;
              maxOverlapDays = 1;
            }
          }
          continue;
        }

        final versionStart = DateTime.parse(startDate);
        final versionEnd = DateTime.parse(endDate);

        // Calcule les jours de chevauchement
        final overlapStart = DateTime.fromMillisecondsSinceEpoch(
          math.max(
            versionStart.millisecondsSinceEpoch,
            monthStart.millisecondsSinceEpoch,
          ),
        );
        final overlapEnd = DateTime.fromMillisecondsSinceEpoch(
          math.min(
            versionEnd.millisecondsSinceEpoch,
            monthEnd.millisecondsSinceEpoch,
          ),
        );

        if (overlapStart.isBefore(overlapEnd) ||
            overlapStart.isAtSameMomentAs(overlapEnd)) {
          final overlapDays = overlapEnd.difference(overlapStart).inDays + 1;

          Logger.info(
            '    📦 ${version['name']}: ${versionStart.day}/${versionStart.month} → ${versionEnd.day}/${versionEnd.month} ($overlapDays jours dans $month)',
            tag: 'KPI',
          );

          if (overlapDays > maxOverlapDays ||
              (overlapDays == maxOverlapDays &&
                  bestVersion != null &&
                  version['id'] > bestVersion['id'])) {
            maxOverlapDays = overlapDays;
            bestVersion = version;
          }
        }
      }

      if (bestVersion != null) {
        Logger.info(
          '    🎯 Sprint sélectionné: ${bestVersion['name']} ($maxOverlapDays jours)',
          tag: 'KPI',
        );
      }

      _cache[cacheKey] = bestVersion;
      return bestVersion;
    } catch (e) {
      Logger.error(
        '     Erreur recherche versions projet $projectId: $e',
        tag: 'KPI',
      );
      return null;
    }
  }

  /// Calcule la progression d'un sprint basée sur les tâches feuilles
  Future<double?> _calculateSprintProgress(
    int projectId,
    Map<String, dynamic> sprint,
  ) async {
    try {
      final sprintId = sprint['id'];
      final workPackages = await _getSprintWorkPackages(projectId, sprintId);

      if (workPackages.isEmpty) {
        return null;
      }

      // Filtre pour garder seulement les tâches feuilles avec percentageDone
      final leafTasks = _filterLeafTasksWithProgress(workPackages);

      if (leafTasks.isEmpty) {
        return null;
      }

      // Calcule la moyenne des pourcentages
      double totalPercentage = 0;
      int validTasks = 0;

      for (final task in leafTasks) {
        final percentageDone = task['percentageDone'];
        if (percentageDone != null) {
          totalPercentage += percentageDone.toDouble();
          validTasks++;
        }
      }

      if (validTasks == 0) {
        return null;
      }

      final averageProgress = totalPercentage / validTasks;

      Logger.info(
        '      🌿 ${validTasks} tâches feuilles, progression moyenne: ${averageProgress.toStringAsFixed(1)}%',
        tag: 'KPI',
      );

      return averageProgress;
    } catch (e) {
      Logger.error('       Erreur calcul progression sprint: $e', tag: 'KPI');
      return null;
    }
  }

  /// ============================================================================
  /// OBJECTIF 1 - TAUX TRIMESTRIEL (70%)
  /// ============================================================================

  /// Calcule l'Objectif 1: moyenne des Objectifs 2 sur les 3 mois du trimestre
  Future<KPIIndicator?> _calculateObjective1Quarterly(DateTime date) async {
    try {
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final quarterKey = '${date.year}-Q$quarter';
      Logger.info('Calcul Objectif 1 pour $quarterKey', tag: 'KPI');

      // Calcule les 3 mois du trimestre
      final quarterMonths = <DateTime>[];
      final startMonth = (quarter - 1) * 3 + 1;

      for (int i = 0; i < 3; i++) {
        final month = startMonth + i;
        if (month <= 12) {
          quarterMonths.add(DateTime(date.year, month, 1));
        }
      }

      // Récupère ou calcule les valeurs mensuelles
      final monthlyValues = <double>[];
      final now = DateTime.now();

      for (final monthDate in quarterMonths) {
        final monthKey = _formatMonth(monthDate);

        // Vérifie si on a l'historique
        if (_monthlyKPIHistory.containsKey(monthKey)) {
          final value = _monthlyKPIHistory[monthKey]!;
          monthlyValues.add(value);
          Logger.info(
            '  📅 ${_getMonthName(monthDate)} ${monthDate.year}: ${value.toStringAsFixed(1)}% (historique)',
            tag: 'KPI',
          );
        }
        // Calcule si c'est un mois passé ou actuel
        else if (monthDate.isBefore(DateTime(now.year, now.month + 1, 1))) {
          final monthlyKPI = await _calculateObjective2Monthly(monthDate);
          if (monthlyKPI != null) {
            monthlyValues.add(monthlyKPI.currentValue);
            Logger.info(
              '  📅 ${_getMonthName(monthDate)} ${monthDate.year}: ${monthlyKPI.currentValue.toStringAsFixed(1)}% (calculé)',
              tag: 'KPI',
            );
          } else {
            Logger.info(
              '  ⚠️ ${_getMonthName(monthDate)} ${monthDate.year}: Pas de données',
              tag: 'KPI',
            );
          }
        }
        // Mois futur - on ne peut pas calculer
        else {
          Logger.info(
            '  ⏳ ${_getMonthName(monthDate)} ${monthDate.year}: Mois futur',
            tag: 'KPI',
          );
        }
      }

      if (monthlyValues.length < 2) {
        Logger.info(
          '⚠️ Pas assez de données pour $quarterKey (${monthlyValues.length}/3 mois)',
          tag: 'KPI',
        );
        return null;
      }

      final average =
          monthlyValues.reduce((a, b) => a + b) / monthlyValues.length;

      Logger.info(
        '✅ Objectif 1: ${average.toStringAsFixed(1)}% (moyenne de ${monthlyValues.length} mois)',
        tag: 'KPI',
      );

      return KPIIndicator(
        id: 'obj1_$quarterKey',
        name: 'Objectif 1 - Q$quarter ${date.year}',
        currentValue: average,
        targetValue: 70.0,
        unit: '%',
        period: date,
        type: KPIType.quarterly,
      );
    } catch (e) {
      Logger.error(' Erreur Objectif 1: $e', tag: 'KPI');
      return null;
    }
  }

  /// ============================================================================
  /// OBJECTIF 3 - QUALITÉ TRIMESTRIEL (80%)
  /// ============================================================================

  /// Calcule l'Objectif 3: taux de finalisation (100%) sur le trimestre
  Future<KPIIndicator?> _calculateObjective3Quality(DateTime date) async {
    try {
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final quarterKey = '${date.year}-Q$quarter';
      Logger.info('Calcul Objectif 3 pour $quarterKey', tag: 'KPI');

      // Calcule les 3 mois du trimestre
      final quarterMonths = <DateTime>[];
      final startMonth = (quarter - 1) * 3 + 1;

      for (int i = 0; i < 3; i++) {
        final month = startMonth + i;
        if (month <= 12) {
          quarterMonths.add(DateTime(date.year, month, 1));
        }
      }

      // Récupère tous les projets inclus
      final allProjects = await _getActiveProjects();
      final includedProjects = allProjects
          .where((p) => !_excludedProjectIds.contains(p['id']))
          .toList();

      if (includedProjects.isEmpty) {
        return null;
      }

      int totalTasks = 0;
      int completedTasks = 0;

      // Pour chaque mois du trimestre
      for (final month in quarterMonths) {
        Logger.info(
          '📅 Analyse ${_getMonthName(month)} ${month.year}',
          tag: 'KPI',
        );

        // Pour chaque projet inclus
        for (final project in includedProjects) {
          final projectId = project['id'];
          final projectName = project['name'] ?? 'Projet $projectId';

          try {
            // Trouve le sprint du mois
            final monthSprint = await _findMonthSprintForProject(
              projectId,
              month,
            );

            if (monthSprint == null) {
              continue;
            }

            // Récupère les tâches feuilles du sprint
            final workPackages = await _getSprintWorkPackages(
              projectId,
              monthSprint['id'],
            );
            final leafTasks = _filterLeafTasksWithProgress(workPackages);

            // Compte les tâches finalisées à 100%
            for (final task in leafTasks) {
              totalTasks++;

              final percentageDone = task['percentageDone'];
              if (percentageDone != null && percentageDone >= 100) {
                completedTasks++;
              }
            }

            Logger.info('$projectName: ${leafTasks.length} tâches', tag: 'KPI');
          } catch (e) {
            Logger.error('     $projectName: $e', tag: 'KPI');
            continue;
          }
        }
      }

      if (totalTasks == 0) {
        Logger.error(' Aucune tâche trouvée pour $quarterKey', tag: 'KPI');
        return null;
      }

      final completionRate = (completedTasks / totalTasks) * 100;

      Logger.info(
        '✅ Objectif 3: ${completionRate.toStringAsFixed(1)}% ($completedTasks/$totalTasks tâches à 100%)',
        tag: 'KPI',
      );

      return KPIIndicator(
        id: 'obj3_$quarterKey',
        name: 'Objectif 3 - Q$quarter ${date.year}',
        currentValue: completionRate,
        targetValue: 80.0,
        unit: '%',
        period: date,
        type: KPIType.quality,
      );
    } catch (e) {
      Logger.error(' Erreur Objectif 3: $e', tag: 'KPI');
      return null;
    }
  }

  /// ============================================================================
  /// MÉTHODES UTILITAIRES
  /// ============================================================================

  /// Récupère tous les projets (actifs ou tous selon le mode)
  Future<List<Map<String, dynamic>>> _getActiveProjects() async {
    final cacheKey = _testMode ? 'all_projects' : 'active_projects';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final projects = await _apiService.getProjects();

      final filteredProjects = _testMode
          ? projects // 🧪 Mode test: TOUS les projets (même fermés)
          : projects.where((project) {
              return project['active'] == true; // Mode prod: seulement actifs
            }).toList();

      Logger.info(
        '📋 Mode ${_testMode ? "TEST" : "PROD"}: ${filteredProjects.length} projets (${projects.length} total)',
        tag: 'KPI',
      );

      _cache[cacheKey] = filteredProjects;
      return filteredProjects;
    } catch (e) {
      Logger.error(' Erreur récupération projets: $e', tag: 'KPI');
      return [];
    }
  }

  /// Récupère les work packages d'un sprint spécifique
  Future<List<Map<String, dynamic>>> _getSprintWorkPackages(
    int projectId,
    int sprintId,
  ) async {
    final cacheKey = 'wp_${projectId}_$sprintId';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      // SECURITY: Validate input to prevent injection
      if (sprintId <= 0) {
        throw ArgumentError('sprintId doit être un entier positif');
      }

      // Use proper JSON encoding instead of string interpolation
      final filterObject = [
        {
          "version": {
            "operator": "=",
            "values": ["$sprintId"],
          },
        },
      ];
      final filtersJson = jsonEncode(filterObject);
      final encodedFilter = Uri.encodeComponent(filtersJson);
      final response = await _apiService.get(
        '/projects/$projectId/work_packages?filters=$encodedFilter',
      );

      final workPackages = <Map<String, dynamic>>[];
      if (response['_embedded'] != null &&
          response['_embedded']['elements'] != null) {
        workPackages.addAll(
          List<Map<String, dynamic>>.from(response['_embedded']['elements']),
        );
      }

      _cache[cacheKey] = workPackages;
      return workPackages;
    } catch (e) {
      Logger.error(
        ' Erreur récupération work packages sprint $sprintId: $e',
        tag: 'KPI',
      );
      return [];
    }
  }

  /// Filtre les tâches pour garder seulement les "feuilles" avec percentageDone
  List<Map<String, dynamic>> _filterLeafTasksWithProgress(
    List<Map<String, dynamic>> workPackages,
  ) {
    final leafTasks = <Map<String, dynamic>>[];

    for (final wp in workPackages) {
      // Vérifie que c'est une tâche feuille (pas un milestone, epic, etc.)
      final type =
          wp['_links']?['type']?['title']?.toString().toLowerCase() ?? '';

      // 🧪 Mode test: inclut plus de types de tâches
      if (!_testMode) {
        if (type.contains('milestone') ||
            type.contains('phase') ||
            type.contains('epic')) {
          continue;
        }
      } else {
        // En mode test, on exclut seulement les milestones
        if (type.contains('milestone')) {
          continue;
        }
      }

      // 🧪 Mode test: accepte aussi les tâches sans percentageDone
      if (_testMode) {
        // En mode test, on prend toutes les tâches (même sans %)
        if (wp['percentageDone'] != null) {
          leafTasks.add(wp);
        } else {
          // Tâche sans pourcentage - on assigne 0% par défaut
          final wpCopy = Map<String, dynamic>.from(wp);
          wpCopy['percentageDone'] = 0;
          leafTasks.add(wpCopy);
        }
      } else {
        // Mode production: seulement les tâches avec percentageDone
        if (wp['percentageDone'] != null) {
          leafTasks.add(wp);
        }
      }
    }

    return leafTasks;
  }

  /// ============================================================================
  /// GESTION DES EXCLUSIONS ET HISTORIQUE
  /// ============================================================================

  /// Charge la liste des projets exclus
  Future<void> _loadExcludedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exclusionStr = prefs.getString(_exclusionKey);

      if (exclusionStr != null) {
        final exclusionList = List<int>.from(jsonDecode(exclusionStr));
        _excludedProjectIds = Set<int>.from(exclusionList);
        Logger.info(
          '${_excludedProjectIds.length} projets exclus chargés',
          tag: 'KPI',
        );
      }
    } catch (e) {
      Logger.error('Erreur chargement exclusions: $e', tag: 'KPI');
      _excludedProjectIds = {};
    }
  }

  /// Sauvegarde la liste des projets exclus
  Future<void> _saveExcludedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _exclusionKey,
        jsonEncode(_excludedProjectIds.toList()),
      );
      Logger.info('Exclusions sauvegardées', tag: 'KPI');
    } catch (e) {
      Logger.error('Erreur sauvegarde exclusions: $e', tag: 'KPI');
    }
  }

  /// Exclut un projet des calculs
  Future<void> excludeProject(int projectId) async {
    _excludedProjectIds.add(projectId);
    await _saveExcludedProjects();
    _cache.clear(); // Invalide le cache
  }

  /// Inclut un projet dans les calculs
  Future<void> includeProject(int projectId) async {
    _excludedProjectIds.remove(projectId);
    await _saveExcludedProjects();
    _cache.clear(); // Invalide le cache
  }

  /// Récupère la liste des projets exclus
  Set<int> get excludedProjectIds => Set<int>.from(_excludedProjectIds);

  /// Charge l'historique mensuel
  Future<void> _loadMonthlyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString(_historicalDataKey);

      if (historyStr != null) {
        final data = Map<String, dynamic>.from(jsonDecode(historyStr));
        _monthlyKPIHistory = Map<String, double>.from(data);
        Logger.info(
          '📦 Historique mensuel chargé: ${_monthlyKPIHistory.length} entrées',
          tag: 'KPI',
        );
      }
    } catch (e) {
      Logger.error('Erreur chargement historique: $e', tag: 'KPI');
      _monthlyKPIHistory = {};
    }
  }

  /// Sauvegarde un KPI mensuel dans l'historique
  Future<void> _saveMonthlyKPI(DateTime date, double value) async {
    try {
      final monthKey = _formatMonth(date);
      _monthlyKPIHistory[monthKey] = value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historicalDataKey, jsonEncode(_monthlyKPIHistory));

      Logger.info(
        'KPI mensuel sauvé: $monthKey = ${value.toStringAsFixed(1)}%',
        tag: 'KPI',
      );
    } catch (e) {
      Logger.error('Erreur sauvegarde KPI: $e', tag: 'KPI');
    }
  }

  /// Efface toutes les données
  Future<void> clearAllData() async {
    _cache.clear();
    _monthlyKPIHistory.clear();
    _excludedProjectIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historicalDataKey);
    await prefs.remove(_exclusionKey);

    Logger.info('Toutes les données effacées', tag: 'KPI');
  }

  /// Active ou désactive le mode test (debug only)
  void setTestMode(bool enabled) {
    // SECURITY: Only allow test mode in debug builds
    if (enabled && kDebugMode) {
      _testMode = true;
      _cache.clear();
      Logger.warn('Test mode ENABLED (debug only)', tag: 'KPI');
    } else if (enabled && !kDebugMode) {
      Logger.warn(
        'Test mode cannot be enabled in release builds',
        tag: 'Security',
      );
      _testMode = false;
    } else {
      _testMode = false;
      _cache.clear();
      Logger.info('Test mode DISABLED', tag: 'KPI');
    }
  }

  /// Récupère l'état du mode test
  bool get isTestMode => _testMode;

  /// Informations de debug
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'test_mode': _testMode,
      'cache_entries': _cache.length,
      'monthly_history_entries': _monthlyKPIHistory.length,
      'excluded_projects': _excludedProjectIds.length,
      'last_calculation': DateTime.now().toString(),
    };
  }

  /// ============================================================================
  /// FORMATAGE ET HELPERS
  /// ============================================================================

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMonthName(DateTime date) {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[date.month];
  }

  /// Vérifie si les credentials API sont configurés
  Future<bool> hasValidCredentials() async {
    try {
      await _apiService.init();
      return _apiService.hasCredentials;
    } catch (e) {
      return false;
    }
  }
}
