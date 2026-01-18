class LeagueModel {
  final String id;
  final String name;
  final String type; // 'T20', 'ODI', 'TEST'
  final bool active;
  final int priority;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'active': active,
      'priority': priority,
    };
  }

  factory LeagueModel.fromMap(Map<String, dynamic> map) {
    return LeagueModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'T20',
      active: map['active'] ?? false,
      priority: map['priority'] ?? 0,
    );
  }
}
