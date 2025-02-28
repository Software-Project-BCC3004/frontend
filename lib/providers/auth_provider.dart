import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get token => _token;

  void login({bool isAdmin = false}) {
    _isLoggedIn = true;
    _isAdmin = isAdmin;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isAdmin = false;
    _token = null;
    notifyListeners();
  }
}
