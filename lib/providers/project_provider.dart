import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';

class ProjectProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // État
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProjects => _projects.isNotEmpty;

  // Charge les projets depuis l'API
  Future<void> loadProjects() async {
    _setLoading(true);
    _clearError();

    try {
      // s'assurer que les credentials sont chargés avant de faire des requêtes API nécéssitant des credentials
      await _apiService.init();
      final projectsData = await _apiService.getProjects();
      _projects = projectsData.map((json) => Project.fromJson(json)).toList();

      print('📋 ${_projects.length} projets chargés');
      _setLoading(false);
    } catch (e) {
      print('❌ Erreur loadProjects: $e');
      _setError('Impossible de charger les projets: $e');
      _setLoading(false);
    }
  }

  // Trouve un projet par ID
  Project? getProjectById(int id) {
    try {
      return _projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filtre les projets actifs
  List<Project> get activeProjects {
    return _projects.where((project) => project.active).toList();
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

  // Rafraîchit les données
  Future<void> refresh() async {
    await loadProjects();
  }
}
