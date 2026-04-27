import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para leer el estado de sesión
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'viewmodels/inventory_viewmodel.dart';
import 'views/main/main_view.dart'; // Importar el MainView verdadero
import 'viewmodels/recipes_viewmodel.dart';
import 'viewmodels/notification_settings_viewmodel.dart';
import 'viewmodels/scanner_viewmodel.dart';
import 'data/services/notification_service.dart';

void main() async {
  // Asegura que Flutter esté listo antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => RecipesViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ScannerViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartPantry',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        // Aquí usamos StreamBuilder para escuchar cambios de sesión en tiempo real
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Mientras lee los datos de caché
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Si el snapshot tiene un usuario guardado:
            if (snapshot.hasData) {
              return const MainView();
            }
            // De lo contrario va al login
            return const LoginView();
          },
        ),
      ),
    );
  }
}
