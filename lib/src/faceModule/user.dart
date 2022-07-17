import 'dart:convert';

class User {
  final String name;
  final List<dynamic> facePoint;

  const User({required this.name, required this.facePoint});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      facePoint: List.from(jsonDecode(json['facePoint'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'facePoint': jsonEncode(facePoint),
    };
  }
}
