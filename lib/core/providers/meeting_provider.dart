import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/recurring_meeting_model.dart';
import 'package:asistencias_app/core/services/meeting_service.dart';

class MeetingProvider with ChangeNotifier {
  final MeetingService _meetingService = MeetingService();
  List<RecurringMeetingModel> _recurringMeetings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecurringMeetingModel> get recurringMeetings => _recurringMeetings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MeetingProvider() {
    _listenToRecurringMeetings();
  }

  void _listenToRecurringMeetings() {
    _isLoading = true;
    notifyListeners();

    _meetingService.getRecurringMeetingsStream().listen(
      (meetings) {
        _recurringMeetings = meetings;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar reuniones recurrentes: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addRecurringMeeting(RecurringMeetingModel meeting) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _meetingService.createRecurringMeeting(meeting);
    } catch (e) {
      _errorMessage = 'Error al añadir reunión recurrente: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Añadir métodos para actualizar y eliminar si se requieren en el provider
} 