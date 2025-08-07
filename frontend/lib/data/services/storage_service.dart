import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yefa/data/models/user_model.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Remove operations
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}

extension UserStorage on StorageService {
  static const String _userKey = 'user';

  Future<void> saveUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await setString(_userKey, jsonString);
  }

  Future<UserModel?> getUser() async {
    final jsonString = getString(_userKey);
    if (jsonString == null) return null;

    try {
      final jsonMap = jsonDecode(jsonString);
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      print('❌ Error decoding user: $e');
      return null;
    }
  }
}
