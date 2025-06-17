import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/core/providers/user_provider.dart'; // Necesario para filtrar por sectorId

class AttendanceRecordProvider with ChangeNotifier {
  final AttendanceRecordService _attendanceRecordService = AttendanceRecordService();
  List<AttendanceRecordModel> _attendanceRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceRecordModel> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AttendanceRecordProvider(UserProvider userProvider) {
    // Escuchar cambios en el usuario para recargar registros si el sector cambia o si el usuario cambia
    userProvider.addListener(() {
      if (userProvider.user?.sectorId != null) {
        _listenToAttendanceRecords(userProvider.user!.sectorId!);
      } else if (userProvider.isAdmin) {
        // Si es admin, podríamos querer todos los registros, o dejarlo sin filtrar aquí si ya se filtra en la vista
        // Por ahora, solo cargaremos si hay sector para el usuario normal
      } else {
        _attendanceRecords = [];
        notifyListeners();
      }
    });
  }

  void _listenToAttendanceRecords(String sectorId) {
    _isLoading = true;
    notifyListeners();

    _attendanceRecordService.getAttendanceRecordsStreamBySector(sectorId).listen(
      (records) {
        _attendanceRecords = records;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar registros de asistencia: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addAttendanceRecord(AttendanceRecordModel record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _attendanceRecordService.addAttendanceRecord(record);
    } catch (e) {
      _errorMessage = 'Error al añadir registro de asistencia: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Puedes añadir métodos para actualizar y eliminar si se requieren
} 