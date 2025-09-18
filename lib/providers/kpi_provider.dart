// KPI Provider - State management for KPI data
// This class manages the state of our 3 ISO objectives and provides them to the UI
// Uses the Provider pattern that Flutter developers are familiar with

import 'package:flutter/foundation.dart';
import '../models/kpi_indicator.dart';
import '../models/performance_cause.dart';
import '../services/kpi_calculator_service.dart';
import '../services/api_service.dart';

class KPIProvider extends ChangeNotifier {
  // The service that does our calculations
  late KPICalculatorService _kpiService;
  
  // Current state of our 3 KPI indicators
  List<KPIIndicator> _kpiIndicators = [];
  
  // List of causes for sprints that didn't meet targets
  List<PerformanceCause> _performanceCauses = [];
  
  // Loading states
  bool _isLoadingKPIs = false;
  bool _isLoadingCauses = false;
  
  // Error states
  String? _errorMessage;

  // Constructor - initialize the KPI service
  KPIProvider(ApiService apiService) {
    _kpiService = KPICalculatorService(apiService);
    print('🎯 KPIProvider initialized');
  }

  // =============================================================================
  // GETTERS - Allow the UI to access our data
  // =============================================================================

  /// Get the list of current KPI indicators
  List<KPIIndicator> get kpiIndicators => List.unmodifiable(_kpiIndicators);
  
  /// Get the list of performance causes
  List<PerformanceCause> get performanceCauses => List.unmodifiable(_performanceCauses);
  
  /// Check if we're currently loading KPI data
  bool get isLoadingKPIs => _isLoadingKPIs;
  
  /// Check if we're currently loading causes data
  bool get isLoadingCauses => _isLoadingCauses;
  
  /// Check if we have any loading operation in progress
  bool get isLoading => _isLoadingKPIs || _isLoadingCauses;
  
  /// Get the current error message (null if no error)
  String? get errorMessage => _errorMessage;
  
  /// Check if we have KPI data loaded
  bool get hasKPIData => _kpiIndicators.isNotEmpty;

  // =============================================================================
  // SPECIFIC KPI GETTERS - Easy access to individual objectives
  // =============================================================================

  /// Get Objective 1 (Quarterly Rate - Target: 70%)
  KPIIndicator? get objective1 {
    try {
      return _kpiIndicators.firstWhere(
        (kpi) => kpi.name.contains('Objectif 1'),
      );
    } catch (e) {
      return null; // Not found
    }
  }

  /// Get Objective 2 (Monthly Rate - Target: 80%)
  KPIIndicator? get objective2 {
    try {
      return _kpiIndicators.firstWhere(
        (kpi) => kpi.name.contains('Objectif 2'),
      );
    } catch (e) {
      return null; // Not found
    }
  }

  /// Get Objective 3 (Quality Rate - Target: 80%)
  KPIIndicator? get objective3 {
    try {
      return _kpiIndicators.firstWhere(
        (kpi) => kpi.name.contains('Objectif 3'),
      );
    } catch (e) {
      return null; // Not found
    }
  }

  // =============================================================================
  // DATA LOADING METHODS - Fetch and calculate KPI data
  // =============================================================================

  /// Load all KPI data from OpenProject
  /// This is the main method the UI will call to refresh data
  Future<void> loadAllKPIs() async {
    print('📊 Starting to load all KPI data...');
    
    // Set loading state
    _isLoadingKPIs = true;
    _errorMessage = null;
    notifyListeners(); // Tell UI to update

    try {
      // CRITICAL: Ensure ApiService has credentials before calculations
      await _kpiService.ensureCredentialsLoaded();
      
      // DEBUG: Inspect API structure first to understand data format
      await _kpiService.debugAPIStructure();
      
      // Calculate all 3 objectives
      final kpiResults = await _kpiService.calculateAllObjectives();
      
      // Update our state
      _kpiIndicators = kpiResults;
      
      // Log results for debugging
      for (var kpi in _kpiIndicators) {
        print('✅ ${kpi.name}: ${kpi.formattedValue} (Target: ${kpi.formattedTarget})');
      }
      
      // Check for causes that need to be documented
      await _checkForRequiredCauses();
      
      print('🎯 All KPIs loaded successfully!');
      
    } catch (e) {
      // Handle errors gracefully
      _errorMessage = 'Erreur lors du calcul des KPIs: $e';
      print('❌ Error loading KPIs: $e');
    } finally {
      // Always clear loading state
      _isLoadingKPIs = false;
      notifyListeners(); // Tell UI to update
    }
  }

  /// Load a specific KPI by type
  Future<void> loadSpecificKPI(String objectiveName) async {
    print('📊 Loading specific KPI: $objectiveName');
    
    _isLoadingKPIs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // CRITICAL: Ensure ApiService has credentials before calculations
      await _kpiService.ensureCredentialsLoaded();
      KPIIndicator? newKPI;
      
      // Determine which calculation to run
      if (objectiveName.contains('Objectif 1')) {
        final quarter = _kpiService.getCurrentQuarter();
        newKPI = await _kpiService.calculateObjective1Quarterly(quarter);
      } else if (objectiveName.contains('Objectif 2')) {
        final month = _kpiService.getCurrentMonth();
        newKPI = await _kpiService.calculateObjective2Monthly(month);
      } else if (objectiveName.contains('Objectif 3')) {
        final quarter = _kpiService.getCurrentQuarter();
        newKPI = await _kpiService.calculateObjective3Quality(quarter);
      }

      if (newKPI != null) {
        // Update the specific KPI in our list
        final index = _kpiIndicators.indexWhere(
          (kpi) => kpi.name.contains(objectiveName),
        );
        
        if (index >= 0) {
          _kpiIndicators[index] = newKPI;
        } else {
          _kpiIndicators.add(newKPI);
        }
        
        print('✅ Updated $objectiveName: ${newKPI.formattedValue}');
      }

    } catch (e) {
      _errorMessage = 'Erreur lors du calcul de $objectiveName: $e';
      print('❌ Error loading specific KPI: $e');
    } finally {
      _isLoadingKPIs = false;
      notifyListeners();
    }
  }

  // =============================================================================
  // CAUSE MANAGEMENT METHODS - Handle performance causes
  // =============================================================================

  /// Check for sprints that need cause documentation
  /// This automatically creates cause entries for sprints below 80%
  Future<void> _checkForRequiredCauses() async {
    print('🔍 Checking for required cause documentation...');
    
    // Only check if we have Objective 2 data (monthly rate)
    final obj2 = objective2;
    if (obj2 == null) return;

    // If monthly rate is below 80%, we need to document causes
    if (obj2.currentValue < 80.0) {
      print('⚠️  Monthly rate ${obj2.formattedValue} is below target - causes needed');
      
      // TODO: In a future version, we could automatically create
      // PerformanceCause entries for each failed sprint
      // For now, we'll just log that causes are needed
    } else {
      print('✅ Monthly rate ${obj2.formattedValue} meets target - no causes needed');
    }
  }

  /// Add a new performance cause
  Future<void> addPerformanceCause(PerformanceCause cause) async {
    print('📝 Adding performance cause: ${cause.displayTitle}');
    
    _performanceCauses.add(cause);
    
    // TODO: In a future version, save to local storage
    
    notifyListeners();
  }

  /// Update an existing performance cause
  Future<void> updatePerformanceCause(String causeId, PerformanceCause updatedCause) async {
    final index = _performanceCauses.indexWhere((cause) => cause.id == causeId);
    
    if (index >= 0) {
      _performanceCauses[index] = updatedCause;
      print('✅ Updated cause: ${updatedCause.displayTitle}');
      
      // TODO: In a future version, save to local storage
      
      notifyListeners();
    }
  }

  /// Remove a performance cause
  Future<void> removePerformanceCause(String causeId) async {
    _performanceCauses.removeWhere((cause) => cause.id == causeId);
    print('🗑️ Removed cause with ID: $causeId');
    
    // TODO: In a future version, remove from local storage
    
    notifyListeners();
  }

  // =============================================================================
  // UTILITY METHODS - Helper methods for the UI
  // =============================================================================

  /// Get a summary of KPI performance
  Map<String, int> getKPIPerformanceSummary() {
    int metTarget = 0;
    int belowTarget = 0;
    int closeToTarget = 0;

    for (var kpi in _kpiIndicators) {
      if (kpi.isTargetMet) {
        metTarget++;
      } else if (kpi.currentValue >= (kpi.targetValue * 0.9)) {
        closeToTarget++;
      } else {
        belowTarget++;
      }
    }

    return {
      'metTarget': metTarget,
      'closeToTarget': closeToTarget,
      'belowTarget': belowTarget,
      'total': _kpiIndicators.length,
    };
  }

  /// Get the overall health status
  String get overallHealthStatus {
    final summary = getKPIPerformanceSummary();
    final total = summary['total'] ?? 0;
    
    if (total == 0) return 'Aucune donnée';
    
    final metTarget = summary['metTarget'] ?? 0;
    
    if (metTarget == total) {
      return 'Excellent'; // All targets met
    } else if (metTarget >= (total * 0.67)) {
      return 'Bon'; // 2/3 or more targets met
    } else {
      return 'À améliorer'; // Less than 2/3 targets met
    }
  }

  /// Clear all data (useful for logout or reset)
  void clearAllData() {
    _kpiIndicators.clear();
    _performanceCauses.clear();
    _errorMessage = null;
    _isLoadingKPIs = false;
    _isLoadingCauses = false;
    
    print('🧹 Cleared all KPI data');
    notifyListeners();
  }

  /// Refresh all data (convenience method)
  Future<void> refreshAll() async {
    print('🔄 Refreshing all KPI data...');
    await loadAllKPIs();
  }
}