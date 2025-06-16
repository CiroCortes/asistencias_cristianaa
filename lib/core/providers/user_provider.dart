import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAdmin => _user?.role == 'admin';
  bool get isApproved => _user?.isApproved ?? false;
  bool get isLoading => _isLoading;

  UserProvider() {
    // Escuchar cambios en el estado de autenticación
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await loadUser();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUser() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUserModel();
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 