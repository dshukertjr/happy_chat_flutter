class Profile {
  final String id;
  final String username;

  Profile({required this.id, required this.username});

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username'];
}
