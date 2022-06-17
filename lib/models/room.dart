class Room {
  final String id;
  final String name;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Room.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'] ?? 'Untitled',
        createdAt = DateTime.parse(map['created_at']);
}
