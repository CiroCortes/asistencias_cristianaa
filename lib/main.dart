import 'package:flutter/material.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/admin_dashboard_screen.dart';

void main() {
  runApp(const AsistenciasApp());
}

class AsistenciasApp extends StatelessWidget {
  const AsistenciasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Asistencias',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AdminDashboardScreen(),
    );
  }
}
