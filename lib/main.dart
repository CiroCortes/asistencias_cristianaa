import 'package:flutter/material.dart';
import 'package:asistencias_app/presentation/screens/auth/auth_wrapper.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/core/providers/users_provider.dart';
import 'package:asistencias_app/core/providers/meeting_provider.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
// firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:asistencias_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Habilitar persistencia offline de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const AsistenciasApp());
}

class AsistenciasApp extends StatelessWidget {
  const AsistenciasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProxyProvider<UserProvider, AttendeeProvider>(
          create: (context) => AttendeeProvider(context.read<UserProvider>()),
          update: (context, userProvider, previousAttendeeProvider) =>
              AttendeeProvider(userProvider),
        ),
      ],
      child: MaterialApp(
        title: 'App de Asistencias',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
