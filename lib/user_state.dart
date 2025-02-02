import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class UserState extends ChangeNotifier {
  /* UserState tracks the user's id and other preferences */
  static final UserState _instance = UserState._internal();

  factory UserState() => _instance;

  UserState._internal() {
    _loadUser();
  }

  String _id = "0";
  String uuidKey = 'UserState.uuid';
  late SharedPreferences prefs;
  final Completer<void> _completer = Completer<void>();

  Future<void> _loadUser() async {
    prefs = await SharedPreferences.getInstance();
    var uuidFromDisk = prefs.getString(uuidKey);

    if (uuidFromDisk == null) {
      _id = const Uuid().v4();
      prefs.setString(uuidKey, _id);
    } else {
      _id = uuidFromDisk;
    }
    _completer.complete(); // Mark as initialized
    notifyListeners();
  }

  void reset() {
    _id = const Uuid().v4();
    prefs.setString(uuidKey, _id);
    notifyListeners();
  }

  String get id => _id;

  Future<String> get idAsync async {
    await _completer.future; // Wait for initialization if needed
    return _id;
  }
}
