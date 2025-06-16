import 'package:flutter/material.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/utils/permission_utils.dart';
import 'package:provider/provider.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!user.isApproved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cuenta Pendiente'),
        ),
        body: const Center(
          child: Text('Tu cuenta está pendiente de aprobación por el administrador.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await userProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistencias del Mes',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '0', // TODO: Implementar contador real
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (PermissionUtils.canRecordAttendance(user)) ...[
              const Text(
                'Acciones Rápidas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionButton(
                    context,
                    'Registrar Asistencia',
                    Icons.how_to_reg,
                    () {
                      // TODO: Implementar registro de asistencia
                    },
                  ),
                  if (user.sectorId != null)
                    _buildActionButton(
                      context,
                      'Ver Mi Sector',
                      Icons.location_on,
                      () {
                        // TODO: Implementar vista de sector
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Asistencia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // TODO: Implementar navegación entre pantallas
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 