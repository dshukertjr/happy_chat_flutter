class Message {
  final String id;
  final DateTime createdAt;
  final String profileId;
  final String roomId;
  final String content;

  Message({
    required this.id,
    required this.createdAt,
    required this.profileId,
    required this.roomId,
    required this.content,
  });

  Message.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        createdAt = DateTime.parse(map['created_at']),
        profileId = map['profile_id'],
        roomId = map['room_id'],
        content = map['content'];
}
