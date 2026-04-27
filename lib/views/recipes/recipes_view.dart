import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recipes_viewmodel.dart';
import 'recipe_detail_view.dart';

class RecipesView extends StatelessWidget {
  const RecipesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RecipesViewModel>(context);
    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas Inteligentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: 'Sugerir con mi despensa',
            onPressed: () => viewModel.suggestFromPantry(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda con estilo premium
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) => viewModel.searchRecipes(value),
                decoration: InputDecoration(
                  hintText: 'Buscar por ingrediente (en inglés)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => viewModel.searchRecipes(searchController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          
          if (viewModel.recipes.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sugerencias para ti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Lista de resultados
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : viewModel.recipes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = viewModel.recipes[index];
                          return _buildRecipeCard(context, viewModel, recipe);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '¿No sabes qué cocinar?',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Usa el botón ✨ arriba para buscar recetas con lo que tienes en tu despensa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipesViewModel viewModel, recipe) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _openRecipeDetail(context, viewModel, recipe.id),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FutureBuilder<bool>(
                    future: viewModel.isFavorite(recipe.id),
                    builder: (context, snapshot) {
                      final isFav = snapshot.data ?? false;
                      return CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => viewModel.toggleFavorite(recipe.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openRecipeDetail(context, viewModel, recipe.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cocinar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipeDetail(BuildContext context, RecipesViewModel viewModel, String mealId) async {
    // Mostrar un diálogo de carga para que el usuario sepa que se está procesando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final detail = await viewModel.getMealDetail(mealId);
      
      if (context.mounted) Navigator.pop(context); // Quitar el diálogo de carga

      if (detail != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailView(recipe: detail)),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar los detalles de la receta')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Asegurar que el diálogo se cierre
      print("Error en navegación: $e");
    }
  }
}