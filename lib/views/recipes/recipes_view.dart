import 'package:flutter/material.dart';

class RecipesView extends StatelessWidget {
  const RecipesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recetas sugeridas')),
      body: const Center(
        child: Text('Aquí mostraremos qué cocinar con tus ingredientes.'),
      ),
    );
  }
}
