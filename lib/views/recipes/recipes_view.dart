import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/recipes_viewmodel.dart';
import 'recipe_detail_view.dart';

class RecipesView extends StatefulWidget {
  const RecipesView({super.key});

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Cargar sugerencias automáticamente al entrar a la vista de recetas (UX Premium)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<RecipesViewModel>(context, listen: false);
      if (viewModel.recipes.isEmpty) {
        viewModel.suggestFromPantry();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RecipesViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas Inteligentes'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: IconButton(
              icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
              tooltip: 'Sugerir con mi despensa',
              onPressed: () => viewModel.suggestFromPantry(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => viewModel.searchRecipes(value),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por ingrediente (en inglés)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary, size: 20),
                  onPressed: () => viewModel.searchRecipes(_searchController.text),
                ),
              ),
            ),
          ),

          if (viewModel.recipes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sugerencias para ti',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Lista de resultados ──
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¿No sabes qué cocinar?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Usa el botón ✨ arriba para buscar recetas\ncon lo que tienes en tu despensa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipesViewModel viewModel, recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRecipeDetail(context, viewModel, recipe.id),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Image.network(
                      recipe.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 160,
                        color: AppColors.surfaceAccent,
                        child: const Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradiente sobre la imagen para contraste
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botón de favorito
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FutureBuilder<bool>(
                      future: viewModel.isFavorite(recipe.id),
                      builder: (context, snapshot) {
                        final isFav = snapshot.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? AppColors.urgent : AppColors.textSecondary,
                              size: 22,
                            ),
                            onPressed: () => viewModel.toggleFavorite(recipe.id),
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            padding: EdgeInsets.zero,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // ── Info ──
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _openRecipeDetail(context, viewModel, recipe.id),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36), // Sobrescribir el tamaño mínimo infinito del tema global
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Cocinar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecipeDetail(BuildContext context, RecipesViewModel viewModel, String mealId) async {
    // Mostrar un diálogo de carga para que el usuario sepa que se está procesando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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