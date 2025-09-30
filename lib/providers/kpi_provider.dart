import 'package:flutter/material.dart';
import '../services/kpi_calculator_service.dart';
import '../models/kpi_indicator.dart';
import '../models/sprint_metrics.dart';
import '../utils/logger.dart';

class KPIProvider with ChangeNotifier {
  final KPICalculatorService _calculatorService = KPICalculatorService(); // Service refactorisé

  // État des KPI
  List<KPIIndicator> _kpis = [];
  // List<SprintMetrics> _sprintsNeedingCauses = []; // Commenté temporairement
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedPeriod = DateTime.now();

  // Getters
  List<KPIIndicator> get kpis => _kpis;
  // List<SprintMetrics> get sprintsNeedingCauses => _sprintsNeedingCauses; // Commenté
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedPeriod => _selectedPeriod;
  bool get hasKPIs => _kpis.isNotEmpty;

  // Getters pour chaque type de KPI
  KPIIndicator? get monthlyKPI => _kpis
      .where((kpi) => kpi.type == KPIType.monthly)
      .isNotEmpty
      ? _kpis.where((kpi) => kpi.type == KPIType.monthly).first
      : null;

  KPIIndicator? get quarterlyKPI => _kpis
      .where((kpi) => kpi.type == KPIType.quarterly)
      .isNotEmpty
      ? _kpis.where((kpi) => kpi.type == KPIType.quarterly).first
      : null;

  KPIIndicator? get qualityKPI => _kpis
      .where((kpi) => kpi.type == KPIType.quality)
      .isNotEmpty
      ? _kpis.where((kpi) => kpi.type == KPIType.quality).first
      : null;

  /// Charge les KPI pour la période sélectionnée
  Future<void> loadKPIs({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      Logger.info('Chargement KPI pour ${_selectedPeriod.toString()}', tag: 'KPI');

      // Vérification préalable des credentials
      if (!await _calculatorService.hasValidCredentials()) {
        Logger.warn('Pas de credentials configurés, arrêt du chargement KPI', tag: 'KPI');
        _setLoading(false);
        _setError('Configuration requise: Veuillez configurer vos identifiants API via l\'écran de connexion');
        return;
      }

      // Calcule tous les KPI (l'initialisation se fait dans le service)
      final kpis = await _calculatorService.calculateAllKPIs(
        forDate: _selectedPeriod,
        forceRefresh: forceRefresh,
      );

      _kpis = kpis;

      Logger.success('${_kpis.length} KPI chargés', tag: 'KPI');
      _setLoading(false);
    } catch (e) {
      Logger.error('Erreur loadKPIs', error: e, tag: 'KPI');
      _setError('Impossible de charger les KPI: $e');
      _setLoading(false);
    }
  }

  /// Change la période sélectionnée et recharge les KPI
  Future<void> changePeriod(DateTime newPeriod) async {
    if (_selectedPeriod != newPeriod) {
      _selectedPeriod = newPeriod;
      notifyListeners();
      await loadKPIs();
    }
  }

  /// Ajoute une cause à un sprint - DÉSACTIVÉ TEMPORAIREMENT
  Future<void> addCauseToSprint({
    required int projectId,
    required int sprintId,
    required CauseCategory category,
    required String description,
    String? solution,
  }) async {
    // Fonctionnalité temporairement désactivée
    Logger.warn('Gestion des causes temporairement désactivée', tag: 'KPI');
    /*
    try {
      final cause = PerformanceCause(
        id: '${projectId}_${sprintId}_${DateTime.now().millisecondsSinceEpoch}',
        projectId: projectId,
        sprintId: sprintId,
        category: category,
        description: description,
        createdAt: DateTime.now(),
        solution: solution,
      );

      await _calculatorService.addCauseToSprint(
        projectId: projectId,
        sprintId: sprintId,
        cause: cause,
      );

      // Met à jour la liste des sprints nécessitant des causes
      _sprintsNeedingCauses = _calculatorService.getSprintsNeedingCauseDocumentation();

      notifyListeners();
      Logger.info('Cause ajoutée au sprint $sprintId', tag: 'KPI');
    } catch (e) {
      Logger.error('Erreur ajout cause: $e', tag: 'KPI');
      _setError('Impossible d\'ajouter la cause: $e');
    }
    */
  }

  /// Rafraîchit toutes les données
  Future<void> refresh() async {
    await loadKPIs(forceRefresh: true);
  }

  /// Navigation entre périodes
  void goToPreviousMonth() {
    final newDate = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1, 1);
    changePeriod(newDate);
  }

  void goToNextMonth() {
    final newDate = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 1);
    changePeriod(newDate);
  }

  void goToPreviousQuarter() {
    final currentQuarter = ((_selectedPeriod.month - 1) ~/ 3) + 1;
    final previousQuarter = currentQuarter - 1;

    int newYear = _selectedPeriod.year;
    int newMonth;

    if (previousQuarter < 1) {
      newYear--;
      newMonth = 10; // Q4 de l'année précédente
    } else {
      newMonth = (previousQuarter - 1) * 3 + 1;
    }

    changePeriod(DateTime(newYear, newMonth, 1));
  }

  void goToNextQuarter() {
    final currentQuarter = ((_selectedPeriod.month - 1) ~/ 3) + 1;
    final nextQuarter = currentQuarter + 1;

    int newYear = _selectedPeriod.year;
    int newMonth;

    if (nextQuarter > 4) {
      newYear++;
      newMonth = 1; // Q1 de l'année suivante
    } else {
      newMonth = (nextQuarter - 1) * 3 + 1;
    }

    changePeriod(DateTime(newYear, newMonth, 1));
  }

  // Getters pour l'affichage des périodes
  String get currentMonthDisplay {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[_selectedPeriod.month - 1]} ${_selectedPeriod.year}';
  }

  String get currentQuarterDisplay {
    final quarter = ((_selectedPeriod.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${_selectedPeriod.year}';
  }

  // Statistiques globales
  int get totalNonCompliantSprints {
    return 0; // _sprintsNeedingCauses.length; // Commenté
  }

  int get totalDocumentedCauses {
    return 0; // Commenté
    // return _sprintsNeedingCauses
    //     .where((sprint) => sprint.causes?.isNotEmpty == true)
    //     .length;
  }

  double get overallComplianceRate {
    if (!hasKPIs) return 0.0;

    final compliantKPIs = _kpis.where((kpi) => kpi.isCompliant).length;
    return (compliantKPIs / _kpis.length) * 100;
  }

  // Méthodes privées pour gérer l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Efface toutes les données (pour les tests)
  Future<void> clearAllData() async {
    await _calculatorService.clearAllData();
    _kpis.clear();
    _clearError();
    notifyListeners();
    Logger.info('Toutes les données effacées', tag: 'KPI');
  }

  /// Informations de debug
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'kpis_loaded': _kpis.length,
      'selected_period': _selectedPeriod.toString(),
      'excluded_projects': _calculatorService.excludedProjectIds.length,
      'last_update': DateTime.now().toString(),
    };
  }

  /// ============================================================================
  /// GESTION DES EXCLUSIONS DE PROJETS
  /// ============================================================================

  /// Récupère la liste des projets exclus
  Set<int> get excludedProjectIds => _calculatorService.excludedProjectIds;

  /// Exclut un projet des calculs KPI
  Future<void> excludeProject(int projectId) async {
    try {
      await _calculatorService.excludeProject(projectId);
      Logger.success('Projet $projectId exclu des calculs', tag: 'KPI');

      // Recharge les KPI pour refléter l'exclusion
      await loadKPIs(forceRefresh: true);
    } catch (e) {
      Logger.error('Erreur exclusion projet $projectId', error: e, tag: 'KPI');
      _setError('Impossible d\'exclure le projet: $e');
    }
  }

  /// Inclut un projet dans les calculs KPI
  Future<void> includeProject(int projectId) async {
    try {
      await _calculatorService.includeProject(projectId);
      Logger.success('Projet $projectId inclus dans les calculs', tag: 'KPI');

      // Recharge les KPI pour refléter l'inclusion
      await loadKPIs(forceRefresh: true);
    } catch (e) {
      Logger.error('Erreur inclusion projet $projectId', error: e, tag: 'KPI');
      _setError('Impossible d\'inclure le projet: $e');
    }
  }

  /// Vérifie si un projet est exclu
  bool isProjectExcluded(int projectId) {
    return _calculatorService.excludedProjectIds.contains(projectId);
  }

  /// ============================================================================
  /// MODE TEST - POUR INCLURE PLUS DE DONNÉES
  /// ============================================================================

  /// Active le mode test (inclut projets/versions/tâches fermés)
  void enableTestMode() {
    _calculatorService.setTestMode(true);
    notifyListeners();
  }

  /// Désactive le mode test (mode production normal)
  void disableTestMode() {
    _calculatorService.setTestMode(false);
    notifyListeners();
  }

  /// Récupère l'état du mode test
  bool get isTestMode => _calculatorService.isTestMode;

}
