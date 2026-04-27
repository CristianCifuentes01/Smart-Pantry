import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/notification_service.dart';
import '../data/repositories/inventory_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();
  bool _isLoading = false;
  int _daysBefore = 2;
  int _hour = 9;
  int _minute = 0;

  bool get isLoading => _isLoading;
  int get daysBefore => _daysBefore;
  int get hour => _hour;
  int get minute => _minute;

  NotificationSettingsViewModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _daysBefore = prefs.getInt('notif_days_before') ?? 2;
    _hour = prefs.getInt('notif_hour') ?? 9;
    _minute = prefs.getInt('notif_minute') ?? 0;
    notifyListeners();
  }

  Future<void> updateDaysBefore(int days) async {
    _daysBefore = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_days_before', days);
    notifyListeners();
  }

  Future<void> updateTime(TimeOfDay time) async {
    _hour = time.hour;
    _minute = time.minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', _hour);
    await prefs.setInt('notif_minute', _minute);
    notifyListeners();
  }

  Future<void> rescheduleAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Cancelar todas las existentes
        await NotificationService().cancelAllNotifications();

        // 2. Obtener todos los productos del usuario
        // Nota: getProducts() devuelve un Stream, tomamos el primer evento (lo que hay en la lista)
        final products = await _repository.getProducts().first;

        // 3. Reprogramar cada uno con la nueva configuración
        for (var product in products) {
          await NotificationService().scheduleExpiryNotification(product);
        }
      }
    } catch (e) {
      print("Error reagendando notificaciones: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
