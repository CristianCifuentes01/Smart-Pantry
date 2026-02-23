import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/inventory_viewmodel.dart';
import 'views/home/home_screen.dart';
import 'views/scanner/scanner_view.dart';
// import 'package:firebase_core/firebase_core.dart'; // Descomentar cuando configures Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Descomentar cuando configures Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InventoryViewModel())],
      child: MaterialApp(
        title: 'SmartPantry',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text(
                'SmartPantry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: const Color.fromARGB(255, 4, 89, 100),
            ),
            body: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Escanear Producto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  // Navegar a la pantalla del escáner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScannerView(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
