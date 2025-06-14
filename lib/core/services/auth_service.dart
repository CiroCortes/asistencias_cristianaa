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

  // Registrar un nuevo usuario con email y contraseña
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? sectorId,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar si es el primer usuario
      final QuerySnapshot userCount = await _firestore.collection('users').limit(1).get();
      final bool isFirstUser = userCount.docs.isEmpty;

      final UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: isFirstUser ? 'admin' : 'normal_user',
        sectorId: sectorId,
        isApproved: isFirstUser, // Si es el primer usuario, se aprueba automáticamente
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set(
        userModel.toFirestore(),
      );

      await userCredential.user!.updateDisplayName(displayName);

      return userModel;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil.';
          break;
        case 'email-already-in-use':
          errorMessage = 'El correo electrónico ya está en uso.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido.';
          break;
        default:
          errorMessage = 'Ocurrió un error durante el registro.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado durante el registro.');
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserModel> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc, null);
      } else {
        throw Exception('No se encontraron datos de usuario en Firestore.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No se encontró ningún usuario con ese correo electrónico.';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido.';
          break;
        case 'user-disabled':
          errorMessage = 'Este usuario ha sido deshabilitado.';
          break;
        default:
          errorMessage = 'Ocurrió un error durante el inicio de sesión.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado durante el inicio de sesión.');
    }
  }

  // Iniciar sesión con Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('El inicio de sesión con Google fue cancelado.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // Si es el primer usuario, se aprueba automáticamente y se le asigna rol de admin
        final QuerySnapshot userCount = await _firestore.collection('users').limit(1).get();
        final bool isFirstUser = userCount.docs.isEmpty;

        final UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName ?? 'Usuario',
          role: isFirstUser ? 'admin' : 'normal_user',
          isApproved: isFirstUser,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set(
          userModel.toFirestore(),
        );

        return userModel;
      } else {
        return UserModel.fromFirestore(userDoc, null);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Ya existe una cuenta con este correo electrónico usando otro método de inicio de sesión.';
          break;
        case 'invalid-credential':
          errorMessage = 'Las credenciales de Google no son válidas.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El inicio de sesión con Google no está habilitado.';
          break;
        default:
          errorMessage = 'Ocurrió un error durante el inicio de sesión con Google.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado durante el inicio de sesión con Google.');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // También cerrar sesión de Google si se usó
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
      throw Exception('Error al obtener los datos del usuario.');
    }
  }
} 
