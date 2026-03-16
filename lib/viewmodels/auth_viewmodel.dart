import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NUEVO: Importamos esto para leer los errores
import '../data/services/firebase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //Funcion inicio de sesion
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _firebaseService.signIn(email, password);
      _setLoading(false);
      return true; // Login exitoso
    } on FirebaseAuthException catch (e) {
      // AQUÍ ATRAPAMOS EL ERROR REAL DE FIREBASE
      print("🔥 Error de Firebase (Login): ${e.code}");

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _errorMessage = "Usuario no encontrado o contraseña incorrecta.";
      } else if (e.code == 'invalid-email') {
        _errorMessage = "El formato del correo es inválido.";
      } else if (e.code == 'too-many-requests') {
        _errorMessage = "Demasiados intentos fallidos. Intenta más tarde.";
      } else {
        _errorMessage = "Error de Firebase: ${e.message}";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print("🔥 Error general: $e");
      _errorMessage = "Error inesperado al iniciar sesión.";
      _setLoading(false);
      return false;
    }
  }

  //Funcion Registro
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _firebaseService.register(email, password, name);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      // AQUÍ ATRAPAMOS EL ERROR REAL DE FIREBASE
      print("🔥 Error de Firebase (Registro): ${e.code}");

      if (e.code == 'email-already-in-use') {
        _errorMessage = "Este correo ya está registrado. Ve a Iniciar Sesión.";
      } else if (e.code == 'weak-password') {
        _errorMessage = "La contraseña es muy débil (mínimo 6 caracteres).";
      } else {
        _errorMessage = "Error de Firebase: ${e.message}";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print("🔥 Error general: $e");
      _errorMessage = "Error inesperado: $e";
      _setLoading(false);
      return false;
    }
  }

  // Función para cerrar sesión
  Future<void> logout() async {
    await _firebaseService.logout();
    notifyListeners();
  }
}
