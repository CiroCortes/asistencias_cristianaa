import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/users_provider.dart';
import 'package:asistencias_app/data/models/user_model.dart';

enum UserFilter {
  pendingApproval,
  allRoles,
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  UserFilter _selectedFilter = UserFilter.pendingApproval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<UserFilter>(
              segments: const [
                ButtonSegment<UserFilter>(
                  value: UserFilter.pendingApproval,
                  label: Text('Aprobación Pendiente'),
                ),
                ButtonSegment<UserFilter>(
                  value: UserFilter.allRoles,
                  label: Text('Todos los Roles'),
                ),
              ],
              selected: <UserFilter>{_selectedFilter},
              onSelectionChanged: (Set<UserFilter> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<UsersProvider>(
              builder: (context, usersProvider, child) {
                if (usersProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (usersProvider.errorMessage != null) {
                  return Center(
                      child: Text('Error: ${usersProvider.errorMessage}'));
                }

                List<UserModel> filteredUsers = usersProvider.users.where((user) {
                  if (_selectedFilter == UserFilter.pendingApproval) {
                    return !user.isApproved;
                  } else {
                    return true; // All roles
                  }
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                      child: Text('No hay usuarios para mostrar.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(user.displayName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                user.role == 'admin' ? 'Admin' : 'Usuario'),
                            const SizedBox(width: 8),
                            if (!user.isApproved) // Mostrar botón de aprobación si está pendiente
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () async {
                                  await usersProvider.updateUserApproval(user.uid, true);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // TODO: Confirmar antes de eliminar
                                await usersProvider.deleteUser(user.uid);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Navegar a la pantalla de edición de usuario
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a la pantalla de añadir nuevo usuario
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 