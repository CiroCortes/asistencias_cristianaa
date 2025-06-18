import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  Timer? _timeoutTimer;

  UserModel? get user => _user;
  bool get isAdmin => _user?.role == 'admin';
  bool get isApproved => _user?.isApproved ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    // Escuchar cambios en el estado de autenticación
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _setupUserListener(firebaseUser.uid);
      } else {
        _cleanupUserListener();
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _setupUserListener(String uid) async {
    _cleanupUserListener(); // Limpiar suscripción anterior si existe
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Configurar timeout
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_isLoading) {
        _errorMessage = 'Tiempo de espera agotado al cargar el usuario';
        _isLoading = false;
        notifyListeners();
      }
    });

    try {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data() ?? {},
            toFirestore: (_, __) => {},
          )
          .snapshots()
          .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        _timeoutTimer?.cancel();
        if (snapshot.exists) {
          _user = UserModel.fromFirestore(snapshot, null);
        } else {
          _user = null;
          _errorMessage = 'No se encontró el usuario';
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _timeoutTimer?.cancel();
        _errorMessage = 'Error en la suscripción del usuario: $error';
        _user = null;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _timeoutTimer?.cancel();
      _errorMessage = 'Error al configurar el listener del usuario: $e';
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _cleanupUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _user = null;
      _errorMessage = 'No hay usuario autenticado';
      notifyListeners();
      return;
    }

    await _setupUserListener(currentUser.uid);
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cleanupUserListener();
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanupUserListener();
    super.dispose();
  }
} 