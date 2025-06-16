import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/presentation/screens/auth/login_screen.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/admin_dashboard_screen.dart';
import 'package:asistencias_app/presentation/screens/user_dashboard/user_dashboard_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si hay un error en la autenticación
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error en la autenticación'),
            ),
          );
        }

        // Si está cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay un usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          // Cargar los datos del usuario en el provider
          context.read<UserProvider>().loadUser();
          
          // Esperar a que el usuario esté cargado
          return Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final user = userProvider.user;
              if (user == null) {
                return const LoginScreen();
              }

              // Redirigir según el rol
              if (userProvider.isAdmin) {
                return const AdminDashboardScreen();
              } else {
                return const UserDashboardScreen();
              }
            },
          );
        }

        // Si no hay usuario autenticado
        return const LoginScreen();
      },
    );
  }
} 