import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:asistencias_app/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión con Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('El inicio de sesión con Google fue cancelado.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('No se pudo obtener el usuario de Firebase.');
      }

      // Verificar si el usuario ya existe en Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // ✅ NUEVA VERIFICACIÓN: Verificar si el email ya existe en otro usuario
        final existingUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .get();

        if (existingUserQuery.docs.isNotEmpty) {
          // El email ya existe, no crear duplicado
          throw Exception(
              'Ya existe una cuenta con este email. Usa el método de login original.');
        }

        // Si es el primer usuario, se aprueba automáticamente y se le asigna rol de admin
        final QuerySnapshot userCount =
            await _firestore.collection('users').limit(1).get();
        final bool isFirstUser = userCount.docs.isEmpty;

        final UserModel userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName ?? 'Usuario',
          role: isFirstUser ? 'admin' : 'normal_user',
          isApproved: isFirstUser,
          isActive: true, // Nuevos usuarios siempre activos
          // sectorId: null - Los usuarios nuevos no tienen sector asignado
          // Los administradores pueden no tener sector, los usuarios normales
          // necesitarán que el admin les asigne uno
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set(
              userModel.toFirestore(),
            );

        return userModel;
      } else {
        final userModel = UserModel.fromFirestore(userDoc, null);

        // Verificar si el usuario está activo
        if (!userModel.isActive) {
          throw Exception(
              'Tu cuenta ha sido desactivada. Contacta al administrador para más información.');
        }

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'Ya existe una cuenta con este email usando otro método de login.';
          break;
        case 'invalid-credential':
          errorMessage = 'Credenciales de Google inválidas.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El inicio de sesión con Google no está habilitado.';
          break;
        case 'user-disabled':
          errorMessage = 'Este usuario ha sido deshabilitado.';
          break;
        case 'user-not-found':
          errorMessage = 'Usuario no encontrado.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de conexión. Verifica tu internet.';
          break;
        default:
          errorMessage =
              'Error durante el inicio de sesión con Google: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Manejo más robusto de errores inesperados
      String errorMessage = 'Error durante el inicio de sesión con Google.';
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Tiempo de espera agotado. Intenta de nuevo.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Inicio de sesión cancelado.';
      }
      throw Exception(errorMessage);
    }
  }

  // Obtener el modelo de usuario actual
  Future<UserModel?> getCurrentUserModel() async {
    final User? user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc, null);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener los datos del usuario: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Obtener todos los usuarios
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc, null))
          .toList();
    });
  }

  // Actualizar el estado de aprobación de un usuario
  Future<void> updateUserApproval(String uid, bool isApproved) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isApproved': isApproved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar la aprobación del usuario: $e');
    }
  }

  // Nuevo método para actualizar un usuario completo (incluyendo rol y sectorId)
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar el usuario: $e');
    }
  }

  // Desactivar un usuario (en lugar de eliminar)
  Future<void> deactivateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al desactivar el usuario: $e');
    }
  }

  // Reactivar un usuario
  Future<void> activateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': true,
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al activar el usuario: $e');
    }
  }
}
