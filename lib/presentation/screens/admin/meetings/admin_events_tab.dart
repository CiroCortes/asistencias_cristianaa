import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/meeting_provider.dart';
import 'package:asistencias_app/data/models/recurring_meeting_model.dart';
import 'package:asistencias_app/presentation/screens/admin/meetings/create_recurring_meeting_screen.dart';

class AdminEventsTab extends StatelessWidget {
  const AdminEventsTab({super.key});

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
                  title: Text(meeting.name),
                  subtitle: Text(
                      'Días: ${meeting.daysOfWeek.join(', ')} - Hora: ${meeting.time}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Navegar a la pantalla de edición de reunión recurrente
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRecurringMeetingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 