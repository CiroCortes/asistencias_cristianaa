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
      await refreshUsers(); // Refresh the list after update
    } catch (e) {
      _errorMessage = 'Error al actualizar la aprobación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.deleteUser(uid);
      await refreshUsers(); // Refresh the list after deletion
    } catch (e) {
      _errorMessage = 'Error al eliminar el usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 