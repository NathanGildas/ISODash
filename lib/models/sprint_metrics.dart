class SprintMetrics {
  final int projectId;
  final String projectName;
  final int sprintId;
  final String sprintName;
  final DateTime startDate;
  final DateTime endDate;
  final double progressionPercent;
  final int totalTasks;
  final int completedTasks;
  final int testedTasks;
  final bool isCompliant;
  final List<PerformanceCause>? causes;

  SprintMetrics({
    required this.projectId,
    required this.projectName,
    required this.sprintId,
    required this.sprintName,
    required this.startDate,
    required this.endDate,
    required this.progressionPercent,
    required this.totalTasks,
    required this.completedTasks,
    required this.testedTasks,
    this.causes,
  }) : isCompliant = progressionPercent >= 80.0;

  // Getters utiles
  int get durationInDays => endDate.difference(startDate).inDays + 1;
  double get completionRate =>
      totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;
  double get testingRate =>
      totalTasks > 0 ? (testedTasks / totalTasks * 100) : 0;
  bool get needsCauseDocumentation => !isCompliant && (causes?.isEmpty ?? true);

  String get monthKey =>
      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
  String get quarterKey =>
      '${startDate.year}-Q${((startDate.month - 1) ~/ 3) + 1}';

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'sprintId': sprintId,
      'sprintName': sprintName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'progressionPercent': progressionPercent,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'testedTasks': testedTasks,
      'causes': causes?.map((c) => c.toJson()).toList(),
    };
  }

  factory SprintMetrics.fromJson(Map<String, dynamic> json) {
    return SprintMetrics(
      projectId: json['projectId'],
      projectName: json['projectName'],
      sprintId: json['sprintId'],
      sprintName: json['sprintName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      progressionPercent: json['progressionPercent'].toDouble(),
      totalTasks: json['totalTasks'],
      completedTasks: json['completedTasks'],
      testedTasks: json['testedTasks'],
      causes: json['causes']
          ?.map<PerformanceCause>((c) => PerformanceCause.fromJson(c))
          .toList(),
    );
  }

  // Méthode pour ajouter une cause
  SprintMetrics addCause(PerformanceCause cause) {
    final newCauses = List<PerformanceCause>.from(causes ?? []);
    newCauses.add(cause);

    return SprintMetrics(
      projectId: projectId,
      projectName: projectName,
      sprintId: sprintId,
      sprintName: sprintName,
      startDate: startDate,
      endDate: endDate,
      progressionPercent: progressionPercent,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      testedTasks: testedTasks,
      causes: newCauses,
    );
  }

  @override
  String toString() {
    return 'SprintMetrics(project: $projectName, sprint: $sprintName, progress: ${progressionPercent.toStringAsFixed(1)}%, compliant: $isCompliant)';
  }
}

class PerformanceCause {
  final String id;
  final int projectId;
  final int sprintId;
  final CauseCategory category;
  final String description;
  final DateTime createdAt;
  final String? solution;
  final bool isResolved;

  PerformanceCause({
    required this.id,
    required this.projectId,
    required this.sprintId,
    required this.category,
    required this.description,
    required this.createdAt,
    this.solution,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sprintId': sprintId,
      'category': category.toString(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'solution': solution,
      'isResolved': isResolved,
    };
  }

  factory PerformanceCause.fromJson(Map<String, dynamic> json) {
    return PerformanceCause(
      id: json['id'],
      projectId: json['projectId'],
      sprintId: json['sprintId'],
      category: CauseCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      solution: json['solution'],
      isResolved: json['isResolved'] ?? false,
    );
  }

  @override
  String toString() {
    return 'PerformanceCause(category: ${category.displayName}, description: $description)';
  }
}

enum CauseCategory {
  technical, // Problèmes techniques
  resources, // Manque de ressources/RH
  external, // Facteurs externes
  planning, // Problèmes de planification
  quality, // Problèmes de qualité
  dependencies, // Dépendances bloquantes
  other, // Autres
}

extension CauseCategoryExtension on CauseCategory {
  String get displayName {
    switch (this) {
      case CauseCategory.technical:
        return 'Technique';
      case CauseCategory.resources:
        return 'Ressources/RH';
      case CauseCategory.external:
        return 'Externe';
      case CauseCategory.planning:
        return 'Planification';
      case CauseCategory.quality:
        return 'Qualité';
      case CauseCategory.dependencies:
        return 'Dépendances';
      case CauseCategory.other:
        return 'Autre';
    }
  }

  String get description {
    switch (this) {
      case CauseCategory.technical:
        return 'Bugs, problèmes d\'infrastructure, complexité technique';
      case CauseCategory.resources:
        return 'Manque de personnel, congés, surcharge';
      case CauseCategory.external:
        return 'Clients, fournisseurs, partenaires externes';
      case CauseCategory.planning:
        return 'Sous-estimation, mauvaise planification';
      case CauseCategory.quality:
        return 'Problèmes de tests, régressions';
      case CauseCategory.dependencies:
        return 'Blocages par d\'autres équipes/projets';
      case CauseCategory.other:
        return 'Autres causes non listées';
    }
  }
}
