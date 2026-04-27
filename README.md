# Smart Pantry 🍎

![Smart Pantry Banner](https://raw.githubusercontent.com/CristianCifuentes01/Smart-Pantry/main/assets/banner.png)
**

Smart Pantry es una solución móvil integral diseñada para modernizar la forma en que gestionamos nuestros alimentos. Utilizando tecnologías de vanguardia, la aplicación permite un control preciso del inventario, previene el desperdicio y fomenta una alimentación creativa basada en los recursos disponibles.

## ✨ Características Principales

- **🔍 Escaneo Inteligente:** Registro instantáneo de productos mediante el escaneo de códigos de barras (integración con APIs de alimentos).
- **📦 Gestión de Inventario Real-Time:** Control detallado de stock, fechas de vencimiento y categorías de productos.
- **📶 Offline-First & Sync:** Arquitectura robusta que funciona sin conexión (SQLite) y sincroniza datos con la nube (Firebase) automáticamente.
- **👨‍🍳 Generador de Recetas:** Sugerencias inteligentes de platillos basadas exclusivamente en los ingredientes que tienes en tu despensa.
- **📊 Dashboard de Análisis:** Resumen visual del estado de tu despensa para una toma de decisiones rápida.

## 🛠️ Stack Tecnológico

La aplicación está construida sobre un stack moderno y escalable:

- **Frontend:** ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat-square&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat-square&logo=dart&logoColor=white)
- **Backend/Auth:** ![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=flat-square&logo=Firebase&logoColor=white)
- **Base de Datos:** ![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=flat-square&logo=sqlite&logoColor=white) (Local) + Firestore (Cloud)
- **Estado:** ![Provider](https://img.shields.io/badge/Provider-Gestión%20de%20Estado-blue?style=flat-square)

## 🏗️ Arquitectura del Proyecto

Implementamos el patrón **MVVM (Model-View-ViewModel)** para garantizar una separación clara de responsabilidades:

```text
lib/
├── core/           # Estilos, temas y utilidades globales
├── data/           # Modelos, Repositorios y Servicios (APIs/Firebase)
├── viewmodels/     # Lógica de negocio y gestión de estado
└── views/          # Interfaz de usuario (Pantallas y Widgets)
```

## 🚀 Instalación y Uso

Sigue estos pasos para ejecutar el proyecto localmente:

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/CristianCifuentes01/Smart-Pantry.git
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase:**
   - Descarga tu archivo `google-services.json` desde la consola de Firebase.
   - Colócalo en `android/app/`.

4. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

---
Desarrollado con ❤️ para el curso de **Computación Móvil**.
