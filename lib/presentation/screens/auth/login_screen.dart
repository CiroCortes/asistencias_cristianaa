import 'package:flutter/material.dart';
import 'package:asistencias_app/core/services/auth_service.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/widgets/app_logo.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      // Cargar el usuario en el provider
      await context.read<UserProvider>().loadUser();

      if (mounted) {
        // La navegación será manejada por AuthWrapper
        // No es necesario navegar manualmente
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Limpiar el mensaje de error para mostrar solo la parte útil
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        // Manejar errores específicos de Google Sign-In
        if (errorMessage.contains('cancelado')) {
          // No mostrar error si el usuario canceló voluntariamente
          setState(() {
            _errorMessage = null;
          });
          return;
        }

        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IBBN Asistencia'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo de la aplicación
            const SizedBox(height: 60.0),
            const Center(
              child: AppLogo(
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 30.0),
            const Text(
              'IBBN Asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Inicia sesión con tu cuenta de Google',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40.0),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 24.0,
                    ),
              label: _isLoading
                  ? const Text('Iniciando sesión...')
                  : const Text(
                      'Iniciar Sesión con Google',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Al iniciar sesión, aceptas los términos y condiciones de uso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
