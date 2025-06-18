import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/presentation/screens/auth/login_screen.dart';
import 'package:asistencias_app/presentation/screens/auth/pending_approval_screen.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/admin_dashboard_screen.dart';
import 'package:asistencias_app/presentation/screens/user_dashboard/user_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingConnection = true;
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Cargar el usuario después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider.loadUser();
      }
    });
  }

  Future<void> _checkConnection() async {
    if (!mounted) return;

    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _hasConnection = connectivityResult != ConnectivityResult.none;
        _isCheckingConnection = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasConnection = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasConnection) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'No hay conexión a internet',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkConnection,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si hay un error en la autenticación
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error en la autenticación: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userProvider = context.read<UserProvider>();
                      userProvider.loadUser();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
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

        // Si no hay usuario autenticado
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Si hay usuario autenticado, verificar su estado
        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Si está cargando el usuario
            if (userProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Si hay un error en el provider
            if (userProvider.errorMessage != null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        userProvider.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          userProvider.loadUser();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = userProvider.user;
            
            // Si no se pudo cargar el usuario
            if (user == null) {
              // Forzar recarga del usuario
              userProvider.loadUser();
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Si el usuario no está aprobado, mostrar pantalla de espera
            if (!user.isApproved) {
              return const PendingApprovalScreen();
            }

            // Si el usuario está aprobado, mostrar el dashboard correspondiente
            return user.role == 'admin'
                ? const AdminDashboardScreen()
                : const UserDashboardScreen();
          },
        );
      },
    );
  }
} 