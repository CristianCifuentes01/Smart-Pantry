import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recipes_viewmodel.dart';

class RecipesView extends StatelessWidget {
  const RecipesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RecipesViewModel>(context);
    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué cocinamos hoy?'),
        actions: [
          // Botón mágico para leer tu despensa
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Sugerir con mi despensa',
            onPressed: () => viewModel.suggestFromPantry(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda manual
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Chicken, Beef, Tomato...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => viewModel.searchRecipes(searchController.text),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.recipes.isEmpty
                    ? const Center(child: Text('Busca un ingrediente o usa el botón ✨ arriba.'))
                    : ListView.builder(
                        itemCount: viewModel.recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = viewModel.recipes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  recipe.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  // Previene errores si la imagen no carga
                                  errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
                                ),
                              ),
                              title: Text(recipe.name),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}