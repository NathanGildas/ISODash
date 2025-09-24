class KPIIndicator {
  final String id;
  final String name;
  final double currentValue;
  final double targetValue;
  final String unit; // "%" pour pourcentage
  final DateTime period;
  final KPIType type;
  final bool isCompliant;

  KPIIndicator({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.period,
    required this.type,
  }) : isCompliant = currentValue >= targetValue;

  // Getters utiles
  double get completionRate => (currentValue / targetValue * 100).clamp(0, 200);
  String get displayValue => '${currentValue.toStringAsFixed(1)}$unit';
  String get displayTarget => '${targetValue.toStringAsFixed(0)}$unit';

  // Status visuel
  KPIStatus get status {
    if (currentValue >= targetValue) return KPIStatus.success;
    if (currentValue >= targetValue * 0.8) return KPIStatus.warning;
    return KPIStatus.danger;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unit': unit,
      'period': period.toIso8601String(),
      'type': type.toString(),
    };
  }

  factory KPIIndicator.fromJson(Map<String, dynamic> json) {
    return KPIIndicator(
      id: json['id'],
      name: json['name'],
      currentValue: json['currentValue'].toDouble(),
      targetValue: json['targetValue'].toDouble(),
      unit: json['unit'],
      period: DateTime.parse(json['period']),
      type: KPIType.values.firstWhere(
            (e) => e.toString() == json['type'],
      ),
    );
  }

  @override
  String toString() {
    return 'KPIIndicator(name: $name, value: $displayValue, target: $displayTarget, compliant: $isCompliant)';
  }
}

enum KPIType {
  monthly,     // Objectif 2 - Taux mensuel
  quarterly,   // Objectif 1 - Taux trimestriel
  quality,     // Objectif 3 - Qualité
}

enum KPIStatus {
  success,   // >= 100% de l'objectif
  warning,   // >= 80% de l'objectif
  danger,    // < 80% de l'objectif
}

extension KPITypeExtension on KPIType {
  String get displayName {
    switch (this) {
      case KPIType.monthly:
        return 'Taux Mensuel';
      case KPIType.quarterly:
        return 'Taux Trimestriel';
      case KPIType.quality:
        return 'Qualité';
    }
  }

  String get description {
    switch (this) {
      case KPIType.monthly:
        return 'Moyenne mensuelle des progressions de sprints (Objectif: 80%)';
      case KPIType.quarterly:
        return 'Moyenne trimestrielle des taux mensuels (Objectif: 70%)';
      case KPIType.quality:
        return 'Ratio tâches testées / tâches totales (Objectif: 80%)';
    }
  }

  double get defaultTarget {
    switch (this) {
      case KPIType.monthly:
        return 80.0;
      case KPIType.quarterly:
        return 70.0;
      case KPIType.quality:
        return 80.0;
    }
  }
}