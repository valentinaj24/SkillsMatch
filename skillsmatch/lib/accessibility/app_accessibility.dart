import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAccessibility extends ChangeNotifier {
  static final AppAccessibility instance = AppAccessibility._internal();

  AppAccessibility._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _seniorMode = false;
  bool _showFloatingButton = false;

  bool get seniorMode => _seniorMode;
  bool get showFloatingButton => _showFloatingButton;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _seniorMode = prefs.getBool('senior_mode') ?? false;
    notifyListeners();
  }

  void setFloatingVisible(bool value) {
    if (_showFloatingButton == value) return;
    _showFloatingButton = value;
    notifyListeners();
  }

  Future<void> setSeniorMode(bool value) async {
    _seniorMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('senior_mode', value);
  }
}
