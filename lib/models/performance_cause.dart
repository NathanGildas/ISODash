// Performance Cause Model - Tracks reasons why a sprint didn't meet targets
// This is important for ISO documentation when sprints are below 80%

class PerformanceCause {
  // Unique ID for this cause entry
  final String id;
  
  // The project this cause relates to
  final int projectId;
  final String projectName;
  
  // The sprint this cause relates to
  final String sprintName;
  
  // The month this occurred in (format: "2025-09")
  final String month;
  
  // The actual completion percentage that triggered this cause entry
  final double actualPercentage;
  
  // Category of the cause - predefined options
  final CauseCategory category;
  
  // Detailed description of what went wrong
  final String description;
  
  // Impact level of this cause
  final CauseImpact impact;
  
  // Who reported this cause
  final String reportedBy;
  
  // When this cause was reported
  final DateTime reportedAt;

  // Constructor
  const PerformanceCause({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.sprintName,
    required this.month,
    required this.actualPercentage,
    required this.category,
    required this.description,
    this.impact = CauseImpact.medium,
    this.reportedBy = 'Team Dev', // Default to Team Dev
    required this.reportedAt,
  });

  // Helper method - format the percentage gap for display
  String get targetGap {
    final gap = 80.0 - actualPercentage;
    return '${gap.toStringAsFixed(1)}% sous l\'objectif';
  }

  // Helper method - get display title for this cause
  String get displayTitle {
    return '$projectName - $sprintName';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'sprintName': sprintName,
      'month': month,
      'actualPercentage': actualPercentage,
      'category': category.toString().split('.').last, // Store enum as string
      'description': description,
      'impact': impact.toString().split('.').last,
      'reportedBy': reportedBy,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }

  // Create from JSON when loading from storage
  factory PerformanceCause.fromJson(Map<String, dynamic> json) {
    return PerformanceCause(
      id: json['id'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      sprintName: json['sprintName'],
      month: json['month'],
      actualPercentage: json['actualPercentage'].toDouble(),
      category: CauseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => CauseCategory.technique,
      ),
      description: json['description'],
      impact: CauseImpact.values.firstWhere(
        (e) => e.toString().split('.').last == json['impact'],
        orElse: () => CauseImpact.medium,
      ),
      reportedBy: json['reportedBy'] ?? 'Team Dev',
      reportedAt: DateTime.parse(json['reportedAt']),
    );
  }

  // Create a simple cause from a sprint that failed to meet target
  factory PerformanceCause.fromFailedSprint({
    required int projectId,
    required String projectName,
    required String sprintName,
    required String month,
    required double actualPercentage,
  }) {
    // Generate a simple ID based on project and sprint
    final id = '${projectId}_${sprintName}_${month}';
    
    return PerformanceCause(
      id: id,
      projectId: projectId,
      projectName: projectName,
      sprintName: sprintName,
      month: month,
      actualPercentage: actualPercentage,
      category: CauseCategory.aDefinir, // Will be filled in by user
      description: 'À documenter', // Will be filled in by user
      reportedAt: DateTime.now(),
    );
  }

  // Create a copy with some values changed
  PerformanceCause copyWith({
    String? id,
    int? projectId,
    String? projectName,
    String? sprintName,
    String? month,
    double? actualPercentage,
    CauseCategory? category,
    String? description,
    CauseImpact? impact,
    String? reportedBy,
    DateTime? reportedAt,
  }) {
    return PerformanceCause(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      sprintName: sprintName ?? this.sprintName,
      month: month ?? this.month,
      actualPercentage: actualPercentage ?? this.actualPercentage,
      category: category ?? this.category,
      description: description ?? this.description,
      impact: impact ?? this.impact,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedAt: reportedAt ?? this.reportedAt,
    );
  }
}

// Enum for cause categories - predefined options to choose from
enum CauseCategory {
  technique,     // Technical issues (bugs, infrastructure, etc.)
  rh,           // Human Resources (team availability, skills, etc.)
  externe,      // External factors (client, dependencies, etc.)
  planning,     // Planning issues (estimation, scope, etc.)
  qualite,      // Quality issues (testing, reviews, etc.)
  aDefinir,     // To be defined - placeholder when creating
}

// Extensions to make enum more user-friendly
extension CauseCategoryExtension on CauseCategory {
  // Display name in French
  String get displayName {
    switch (this) {
      case CauseCategory.technique:
        return 'Technique';
      case CauseCategory.rh:
        return 'Ressources Humaines';
      case CauseCategory.externe:
        return 'Facteurs Externes';
      case CauseCategory.planning:
        return 'Planification';
      case CauseCategory.qualite:
        return 'Qualité';
      case CauseCategory.aDefinir:
        return 'À définir';
    }
  }

  // Icon for display
  String get iconName {
    switch (this) {
      case CauseCategory.technique:
        return 'build';
      case CauseCategory.rh:
        return 'people';
      case CauseCategory.externe:
        return 'business';
      case CauseCategory.planning:
        return 'calendar_today';
      case CauseCategory.qualite:
        return 'verified';
      case CauseCategory.aDefinir:
        return 'help_outline';
    }
  }
}

// Enum for impact levels
enum CauseImpact {
  low,    // Low impact
  medium, // Medium impact
  high,   // High impact
}

// Extensions for impact levels
extension CauseImpactExtension on CauseImpact {
  String get displayName {
    switch (this) {
      case CauseImpact.low:
        return 'Faible';
      case CauseImpact.medium:
        return 'Moyen';
      case CauseImpact.high:
        return 'Élevé';
    }
  }

  String get colorName {
    switch (this) {
      case CauseImpact.low:
        return 'green';
      case CauseImpact.medium:
        return 'orange';
      case CauseImpact.high:
        return 'red';
    }
  }
}