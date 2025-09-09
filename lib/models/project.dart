class Project {
  final int id;
  final String name;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? status;

  Project({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.status,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Projet sans nom',
      active: json['active'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      description: json['description']?['raw'],
      status: json['status']?['name'],
    );
  }

  // Méthodes utiles
  String get statusDisplay => status ?? (active ? 'Actif' : 'Inactif');

  String get createdAtFormatted {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, active: $active)';
  }
}
