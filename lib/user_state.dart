import 'package:chat_tqw/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import 'user.dart';

class UserState extends ChangeNotifier {
  /* UserState tracks the user's id and other preferences */
  static final UserState _instance = UserState._internal();

  factory UserState() => _instance;

  UserState._internal() {
    _init();
  }

  late SharedPreferences prefs;
  final Completer<void> _completer = Completer<void>();
  String _id = "0";
  String uuidKey = 'UserState.uuid';
  User? _currentUser;

  // Called the first time the singleton is initialized
  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    var uuidFromDisk = prefs.getString(uuidKey);

    if (uuidFromDisk == null) {
      _id = const Uuid().v4();
      prefs.setString(uuidKey, _id);
    } else {
      _id = uuidFromDisk;
    }
    _completer.complete(); // Mark as initialized
    notifyListeners();

    _loadUser();
  }

  // load the user from the server using the existing userId
  void _loadUser() async {
    try {
      _currentUser = await ApiService().fetchSingle<User>(
        "/user/get",
        User.fromJson,
      );
      notifyListeners();
    } catch (e) {
      print("user not found: $e");
    }
  }

  // user login flow
  Future<String?> login(String email, String password) async {
    try {
      _currentUser = await ApiService()
          .fetchSingle<User>("/user/login", User.fromJson, body: {
        "email": email,
        "password": password,
      });
      _id = _currentUser!.userId;
      prefs.setString(uuidKey, _id);
      notifyListeners();
      return null;
    } catch (e) {
      return "Login failed";
    }
  }

  void logout() {
    _id = const Uuid().v4();
    _currentUser = null;
    prefs.setString(uuidKey, _id);
    notifyListeners();
  }

  // user signup flow
  Future<String?> signup(
      String email, String password, String firstName, String lastName) async {
    try {
      _currentUser = await ApiService()
          .fetchSingle<User>("/user/signup", User.fromJson, body: {
        "email": email,
        "password": password,
        "firstName": firstName,
        "lastName": lastName,
      });
      _id = _currentUser!.userId;
      prefs.setString(uuidKey, _id);
      notifyListeners();
      return null;
    } catch (e) {
      return "Signup failed";
    }
  }

  String get id => _id;

  Future<String> get idAsync async {
    await _completer.future; // Wait for initialization if needed
    return _id;
  }

  User? get currentUser => _currentUser;
}
