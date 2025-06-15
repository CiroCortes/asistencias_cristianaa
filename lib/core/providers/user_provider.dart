import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/core/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  bool get isAdmin => _user?.role == 'admin';
  bool get isApproved => _user?.isApproved ?? false;

  Future<void> loadUser() async {
    _user = await _authService.getCurrentUserModel();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
} 