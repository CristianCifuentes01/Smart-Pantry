import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // RF-01: Iniciar Sesión
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // RF-02: Registrar Cuenta
  Future<UserCredential> register(
    String email,
    String password,
    String name,
  ) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Guardamos el nombre del usuario
    await credential.user?.updateDisplayName(name);
    return credential;
  }

  // RF-03: Recuperar Contraseña
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}
