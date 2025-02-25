import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  bool _isAdmin = false;

  String? get token => _token;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _token != null;

  void setAuth(String token, bool isAdmin) {
    _token = token;
    _isAdmin = isAdmin;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _isAdmin = false;
    notifyListeners();
  }
}
