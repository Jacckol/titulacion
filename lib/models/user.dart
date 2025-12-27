class User {
  final String? id;
  final String? username;
  final String? role;

  User({this.id, this.username, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      username: json['name'],
      role: json['role'],
    );
  }
}
