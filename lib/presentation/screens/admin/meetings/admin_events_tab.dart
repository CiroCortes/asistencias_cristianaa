import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/meeting_provider.dart';

import 'package:asistencias_app/presentation/screens/admin/meetings/create_recurring_meeting_screen.dart';

class AdminEventsTab extends StatelessWidget {
  final bool isAdminView;

  const AdminEventsTab({super.key, this.isAdminView = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MeetingProvider>(
        builder: (context, meetingProvider, child) {
          if (meetingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (meetingProvider.errorMessage != null) {
            return Center(child: Text('Error: ${meetingProvider.errorMessage}'));
          }

          if (meetingProvider.recurringMeetings.isEmpty) {
            return const Center(
                child: Text('No hay reuniones recurrentes creadas.'));
          }

          return ListView.builder(
            itemCount: meetingProvider.recurringMeetings.length,
            itemBuilder: (context, index) {
              final meeting = meetingProvider.recurringMeetings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(meeting.name)),
                      if (!meeting.isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: Text('Inactivo', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                      'Días: ${meeting.daysOfWeek.join(', ')} - Hora: ${meeting.time}'),
                  trailing: isAdminView ? const Icon(Icons.arrow_forward_ios) : null,
                  onTap: isAdminView
                      ? () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('Editar evento'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await showDialog(
                                          context: context,
                                          builder: (context) => _EditMeetingDialog(meeting: meeting),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(meeting.isActive ? Icons.visibility_off : Icons.visibility),
                                      title: Text(meeting.isActive ? 'Desactivar evento' : 'Activar evento'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final provider = Provider.of<MeetingProvider>(context, listen: false);
                                        await provider.updateRecurringMeeting(meeting.id!, {
                                          'isActive': !meeting.isActive,
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      : null, // Deshabilita el onTap si no es vista de administrador
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdminView
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRecurringMeetingScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null, // Oculta el botón si no es vista de administrador
    );
  }
}

// --- DIALOGO DE EDICION DE EVENTO ---
class _EditMeetingDialog extends StatefulWidget {
  final meeting;
  const _EditMeetingDialog({required this.meeting});

  @override
  State<_EditMeetingDialog> createState() => _EditMeetingDialogState();
}

class _EditMeetingDialogState extends State<_EditMeetingDialog> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late List<String> _selectedDays;
  TimeOfDay? _selectedTime;

  static const List<String> _diasSemanaEs = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  static const Map<String, String> _diasSemana = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
    'Lunes': 'Lunes',
    'Martes': 'Martes',
    'Miércoles': 'Miércoles',
    'Jueves': 'Jueves',
    'Viernes': 'Viernes',
    'Sábado': 'Sábado',
    'Domingo': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meeting.name);
    _timeController = TextEditingController(text: widget.meeting.time);
    // Refuerzo: asegura que daysOfWeek nunca sea null ni cause crash
    _selectedDays = (widget.meeting.daysOfWeek ?? [])
      .map((d) => _diasSemana[d] ?? d)
      .where((d) => _diasSemanaEs.contains(d))
      .toSet()
      .toList()
      .cast<String>();
    // Inicializar _selectedTime desde el string si es posible
    try {
      final parts = widget.meeting.time.split(":");
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar evento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del evento'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Hora',
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 16),
            // Selector de días de la semana
            Wrap(
              spacing: 8.0,
              children: _diasSemanaEs.map((dayEs) => FilterChip(
                    label: Text(dayEs),
                    selected: _selectedDays.contains(dayEs),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayEs);
                        } else {
                          _selectedDays.remove(dayEs);
                        }
                      });
                    },
                  )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_timeController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor selecciona una hora.')),
              );
              return;
            }
            final provider = Provider.of<MeetingProvider>(context, listen: false);
            // Solo días válidos y tipo String
            final diasValidos = _selectedDays.where((d) => _diasSemanaEs.contains(d)).toList();
            await provider.updateRecurringMeeting(widget.meeting.id!, {
              'name': _nameController.text,
              'time': _timeController.text,
              'daysOfWeek': diasValidos,
            });
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
} 