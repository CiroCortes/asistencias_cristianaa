import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/core/services/auth_service.dart';

class UsersProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UsersProvider() {
    _loadUsers();
  }

  Stream<List<UserModel>> get usersStream => _authService.getAllUsers();

  Future<void> _loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      usersStream.listen((userList) {
        _users = userList;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    await _loadUsers();
  }

  Future<void> updateUserApproval(String uid, bool isApproved) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updateUserApproval(uid, isApproved);
      await refreshUsers(); // Actualizar la lista después de la actualización
    } catch (e) {
      _errorMessage = 'Error al actualizar la aprobación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updateUser(user);
      await refreshUsers(); // Actualizar la lista después de la actualización
    } catch (e) {
      _errorMessage = 'Error al actualizar el usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.deactivateUser(uid);
      await refreshUsers(); // Refresh the list after deactivation
    } catch (e) {
      _errorMessage = 'Error al desactivar el usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.activateUser(uid);
      await refreshUsers(); // Refresh the list after activation
    } catch (e) {
      _errorMessage = 'Error al activar el usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
