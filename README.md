# smart_pantry

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

lib/
├── core/
│   ├── constants/       (colores y API keys)
│   ├── utils/           (Funciones de ayuda como formatear fechas)
│   └── theme/           (Estilos de la app)
├── data/
│   ├── models/          (ProductModel)
│   ├── repositories/    (Lógica de guardar/leer datos)
│   └── services/        (Conexión con OpenFoodFacts y Firebase)
├── viewmodels/          (Lógica que conecta la UI con los datos)
├── views/
│   ├── home/            (Pantalla principal)
│   ├── scanner/         (Pantalla de cámara)
│   ├── recipes/         (Pantalla de recetas)
│   └── widgets/         (Botones y tarjetas reusables)
└── main.dart            (Punto de entrada)