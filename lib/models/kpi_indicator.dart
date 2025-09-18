// KPI Indicator Model - Represents one ISO objective measurement
// This is a simple data class to store information about our 3 ISO objectives

class KPIIndicator {
  // The name of the indicator (ex: "Objectif 1 - Taux Trimestriel")
  final String name;
  
  // The current calculated value (ex: 75.5 for 75.5%)
  final double currentValue;
  
  // The target we want to reach (ex: 70.0 for 70%)
  final double targetValue;
  
  // The period this KPI covers (ex: "T3 2025", "Septembre 2025")
  final String period;
  
  // The unit for display (ex: "%", "points")
  final String unit;
  
  // When this KPI was last calculated
  final DateTime lastCalculated;

  // Constructor - this is how we create a new KPIIndicator
  const KPIIndicator({
    required this.name,
    required this.currentValue,
    required this.targetValue,
    required this.period,
    this.unit = '%', // Default unit is percentage
    required this.lastCalculated,
  });

  // Helper method - check if this KPI meets its target
  bool get isTargetMet {
    return currentValue >= targetValue;
  }

  // Helper method - calculate how far we are from target (positive = above target)
  double get targetDifference {
    return currentValue - targetValue;
  }

  // Helper method - get a color based on performance
  // Green = above target, Orange = close to target, Red = below target
  String get performanceColor {
    if (isTargetMet) {
      return 'green'; // Above target
    } else if (currentValue >= (targetValue * 0.9)) {
      return 'orange'; // Within 10% of target
    } else {
      return 'red'; // More than 10% below target
    }
  }

  // Helper method - format the value for display (ex: "75.5%")
  String get formattedValue {
    return '${currentValue.toStringAsFixed(1)}$unit';
  }

  // Helper method - format the target for display (ex: "≥70.0%")
  String get formattedTarget {
    return '≥${targetValue.toStringAsFixed(1)}$unit';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'period': period,
      'unit': unit,
      'lastCalculated': lastCalculated.toIso8601String(),
    };
  }

  // Create from JSON when loading from storage
  factory KPIIndicator.fromJson(Map<String, dynamic> json) {
    return KPIIndicator(
      name: json['name'],
      currentValue: json['currentValue'].toDouble(),
      targetValue: json['targetValue'].toDouble(),
      period: json['period'],
      unit: json['unit'] ?? '%',
      lastCalculated: DateTime.parse(json['lastCalculated']),
    );
  }

  // Create a copy with some values changed (useful for updates)
  KPIIndicator copyWith({
    String? name,
    double? currentValue,
    double? targetValue,
    String? period,
    String? unit,
    DateTime? lastCalculated,
  }) {
    return KPIIndicator(
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      period: period ?? this.period,
      unit: unit ?? this.unit,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }
}