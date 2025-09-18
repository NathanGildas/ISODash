// Sprint Metrics Model - Represents metrics for one project's sprint
// This stores the completion data we need to calculate our KPIs

import 'dart:math' as math;

class SprintMetrics {
  // The project ID from OpenProject
  final int projectId;
  
  // The project name for easy display
  final String projectName;
  
  // The sprint/version name (ex: "Sprint 2", "Version 1.0")
  final String sprintName;
  
  // When this sprint started
  final DateTime startDate;
  
  // When this sprint should end
  final DateTime endDate;
  
  // The completion percentage (0-100) from OpenProject
  final double completionPercentage;
  
  // How many days this sprint covers
  final int totalDays;
  
  // Whether this sprint is still active or completed
  final bool isActive;
  
  // Month this sprint belongs to (for grouping)
  final String month; // Format: "2025-09" for September 2025

  // Constructor
  const SprintMetrics({
    required this.projectId,
    required this.projectName,
    required this.sprintName,
    required this.startDate,
    required this.endDate,
    required this.completionPercentage,
    required this.totalDays,
    this.isActive = true,
    required this.month,
  });

  // Helper method - check if this sprint meets the 80% monthly target
  bool get meetsMonthlyTarget {
    return completionPercentage >= 80.0;
  }

  // Helper method - calculate how many days are left (negative if overdue)
  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  // Helper method - check if sprint is overdue
  bool get isOverdue {
    return daysRemaining < 0 && isActive;
  }

  // Helper method - get sprint status as string
  String get statusDisplay {
    if (!isActive) {
      return 'Terminé';
    } else if (isOverdue) {
      return 'En retard';
    } else {
      return 'En cours';
    }
  }

  // Helper method - format completion percentage for display
  String get formattedCompletion {
    return '${completionPercentage.toStringAsFixed(1)}%';
  }

  // Helper method - format date range for display
  String get dateRangeDisplay {
    final startFormatted = '${startDate.day}/${startDate.month}';
    final endFormatted = '${endDate.day}/${endDate.month}';
    return '$startFormatted - $endFormatted';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'sprintName': sprintName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'completionPercentage': completionPercentage,
      'totalDays': totalDays,
      'isActive': isActive,
      'month': month,
    };
  }

  // Create from JSON when loading from storage
  factory SprintMetrics.fromJson(Map<String, dynamic> json) {
    return SprintMetrics(
      projectId: json['projectId'],
      projectName: json['projectName'],
      sprintName: json['sprintName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      completionPercentage: json['completionPercentage'].toDouble(),
      totalDays: json['totalDays'],
      isActive: json['isActive'] ?? true,
      month: json['month'],
    );
  }

  // Create from OpenProject API data
  factory SprintMetrics.fromOpenProjectVersion(
    Map<String, dynamic> versionData,
    Map<String, dynamic> projectData,
  ) {
    try {
      // Handle different date field possibilities and provide defaults
      String? startDateString = versionData['startDate'] ?? 
                               versionData['createdAt'] ?? 
                               DateTime.now().toIso8601String();
      
      String? endDateString = versionData['dueDate'] ?? 
                             versionData['endDate'] ?? 
                             versionData['updatedAt'] ??
                             DateTime.now().add(Duration(days: 30)).toIso8601String();
      
      final startDate = DateTime.parse(startDateString!);
      final endDate = DateTime.parse(endDateString!);
      
      // Calculate total days (minimum 1 day)
      final totalDays = math.max(1, endDate.difference(startDate).inDays);
      
      // Get month in YYYY-MM format
      final month = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
      
      // Handle different completion percentage fields
      double completionPercentage = 0.0;
      if (versionData['percentageDone'] != null) {
        completionPercentage = (versionData['percentageDone']).toDouble();
      } else if (versionData['percentDone'] != null) {
        completionPercentage = (versionData['percentDone']).toDouble();
      } else if (versionData['progress'] != null) {
        completionPercentage = (versionData['progress']).toDouble();
      }
      
      // Ensure percentage is between 0 and 100
      completionPercentage = math.max(0.0, math.min(100.0, completionPercentage));
      
      // Handle status field variations
      bool isActive = true;
      if (versionData['status'] != null) {
        final status = versionData['status'].toString().toLowerCase();
        isActive = status == 'open' || status == 'active' || status == 'in_progress';
      }
      
      print('📈 Created SprintMetrics: ${versionData['name']} - ${completionPercentage}%');
      
      return SprintMetrics(
        projectId: projectData['id'],
        projectName: projectData['name'] ?? 'Unknown Project',
        sprintName: versionData['name'] ?? 'Unknown Sprint',
        startDate: startDate,
        endDate: endDate,
        completionPercentage: completionPercentage,
        totalDays: totalDays,
        isActive: isActive,
        month: month,
      );
    } catch (e) {
      print('❌ Error creating SprintMetrics: $e');
      print('📄 Version data: $versionData');
      print('📄 Project data: $projectData');
      
      // Return a default/fallback SprintMetrics
      final now = DateTime.now();
      return SprintMetrics(
        projectId: projectData['id'] ?? 0,
        projectName: projectData['name'] ?? 'Unknown Project',
        sprintName: versionData['name'] ?? 'Unknown Sprint',
        startDate: now,
        endDate: now.add(Duration(days: 30)),
        completionPercentage: 0.0,
        totalDays: 30,
        isActive: true,
        month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      );
    }
  }

  // Create a copy with some values changed
  SprintMetrics copyWith({
    int? projectId,
    String? projectName,
    String? sprintName,
    DateTime? startDate,
    DateTime? endDate,
    double? completionPercentage,
    int? totalDays,
    bool? isActive,
    String? month,
  }) {
    return SprintMetrics(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      sprintName: sprintName ?? this.sprintName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalDays: totalDays ?? this.totalDays,
      isActive: isActive ?? this.isActive,
      month: month ?? this.month,
    );
  }
}