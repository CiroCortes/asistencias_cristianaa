import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/core/services/attendee_service.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendeeProvider with ChangeNotifier {
  final AttendeeService _attendeeService = AttendeeService();
  List<AttendeeModel> _attendees = [];
  bool _isLoading = false;
  String? _errorMessage;
  UserProvider _userProvider;

  List<AttendeeModel> get attendees => _attendees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AttendeeProvider(this._userProvider) {
    _listenToAttendees();
    _userProvider.addListener(_onUserChange); // Listen to user changes
  }

  void _onUserChange() {
    // Reload attendees if user changes (e.g., login/logout or role change)
    _listenToAttendees();
  }

  void _listenToAttendees() {
    _isLoading = true;
    notifyListeners();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _userProvider.user == null) {
      _attendees = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    Stream<List<AttendeeModel>> attendeesStream;
    if (_userProvider.isAdmin) {
      attendeesStream = _attendeeService.getAllAttendeesStream();
    } else if (_userProvider.user?.sectorId != null) {
      attendeesStream = _attendeeService.getAttendeesBySectorStream(_userProvider.user!.sectorId!);
    } else {
      _attendees = []; // No sectorId for non-admin non-approved user
      _isLoading = false;
      notifyListeners();
      return;
    }

    attendeesStream.listen(
      (attendeeList) {
        _attendees = attendeeList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar asistentes: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addAttendee(AttendeeModel attendee) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendeeService.createAttendee(attendee);
    } catch (e) {
      _errorMessage = 'Error al añadir asistente: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar un asistente existente
  Future<void> updateAttendee(AttendeeModel attendee) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendeeService.updateAttendee(attendee);
    } catch (e) {
      _errorMessage = 'Error al actualizar asistente: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Añadir métodos para actualizar y eliminar asistentes si se requieren en el provider

  @override
  void dispose() {
    _userProvider.removeListener(_onUserChange);
    super.dispose();
  }
} 