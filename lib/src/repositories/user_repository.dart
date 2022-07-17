import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../faceModule/user.dart';

class UserRepository {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<User?> getUser() async {
    final pref = await _prefs;

    final userJson = pref.getString('user');

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  void saveUser(User user) async {
    final pref = await _prefs;

    final userJson = jsonEncode(user.toJson());

    await pref.setString('user', userJson);
  }
}
