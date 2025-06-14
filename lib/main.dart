import 'package:flutter/material.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/admin_dashboard_screen.dart';
import 'package:asistencias_app/presentation/screens/auth/register_screen.dart';
import 'package:asistencias_app/presentation/screens/auth/login_screen.dart';
// firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:asistencias_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
