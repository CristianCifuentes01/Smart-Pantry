import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'viewmodels/inventory_viewmodel.dart';
import 'views/home/home_view.dart';
// Puedes dejar las demás importaciones si las necesitas en el futuro,
// pero limpié las que ya no se usan directamente aquí.

void main() async {
  // Asegura que Flutter esté listo antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InventoryViewModel())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartPantry',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        // EL CAMBIO ESTÁ AQUÍ:
        // Borramos todo el bloque de 'home: Builder(...)' y lo reemplazamos por:
        home: const HomeView(),
      ),
    );
  }
}
