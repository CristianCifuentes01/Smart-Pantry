import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../recipes/recipes_view.dart';
import '../profile/profile_view.dart';


class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0; // Controla qué pestaña está activa

  // Lista de las pantallas que mostraremos
  final List<Widget> _pages = [
    const HomeView(), // Índice 0
    const RecipesView(), // Índice 1
    const ProfileView(), // Índice 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Muestra la pantalla según el índice
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green, // Color cuando está activo
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Cambia la pantalla al tocar
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Despensa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
