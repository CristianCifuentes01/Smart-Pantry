import 'package:flutter/material.dart';
import '../../data/models/meal_detail_model.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recipes_viewmodel.dart';

class RecipeDetailView extends StatelessWidget {
  final MealDetailModel recipe;

  const RecipeDetailView({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 100),
              ),
            ),
            actions: [
              Consumer<RecipesViewModel>(
                builder: (context, viewModel, child) {
                  return FutureBuilder<bool>(
                    future: viewModel.isFavorite(recipe.id),
                    builder: (context, snapshot) {
                      final isFav = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          viewModel.toggleFavorite(recipe.id);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(recipe.category),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                      ),
                      Chip(
                        label: Text(recipe.area),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingredientes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Instrucciones',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.instructions,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
