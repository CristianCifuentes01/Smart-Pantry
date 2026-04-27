import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inicializa las zonas horarias
    tz.initializeTimeZones();

    // Configura el ícono de la notificación
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Programar la notificación real (RF-17)
  Future<void> scheduleExpiryNotification(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Obtenemos configuración de antelación (default 2 días)
    final int daysBefore = prefs.getInt('notif_days_before') ?? 2;
    // Obtenemos configuración de hora (default 9:00 AM)
    final int hour = prefs.getInt('notif_hour') ?? 9;
    final int minute = prefs.getInt('notif_minute') ?? 0;

    // Calculamos la fecha de disparo
    DateTime notificationDate = product.expiryDate.subtract(Duration(days: daysBefore));
    notificationDate = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      hour,
      minute,
    );

    // Si la fecha calculada ya pasó, no programamos nada
    if (notificationDate.isBefore(DateTime.now())) return;

    // Usamos el ID del producto (hash) para que sea único por ítem
    final int notificationId = product.id.hashCode;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '¡Atención con tu despensa! 🚨',
      'Tu ${product.name} está a punto de caducar. ¡Hora de usarlo!',
      tz.TZDateTime.from(notificationDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pantry_channel',
          'Caducidad de Alimentos',
          channelDescription: 'Avisos cuando un alimento está por vencer',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String productId) async {
    await _notificationsPlugin.cancel(productId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Notificación Instantánea 
  Future<void> showInstantTestNotification(String productName) async {
    await _notificationsPlugin.show(
      999,
      'Prueba de SmartPantry ✅',
      'El sistema de alertas para $productName funciona perfectamente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}