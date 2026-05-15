# VetClick / VetManager

Software de gestión integral para clínicas veterinarias. Desarrollado con Flutter y Firebase.

## Descripción

VetClick es una aplicación multiplataforma diseñada para facilitar la administración diaria de clínicas veterinarias. Permite gestionar citas, mascotas, historial de vacunas, carnets digitales y comunicación con propietarios mediante WhatsApp.

## Stack Tecnológico

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Hosting
- **Calendario:** Syncfusion Flutter Calendar
- **QR:** qr_flutter

## Características

- 📅 **Calendario de citas** con vista diaria, semanal y mensual
- 🐾 **Gestión de mascotas** con historial médico y vacunas
- 💉 **Control de vacunación** con recordatorios
- 🆔 **Carnet digital público** accesible por QR
- 📱 **Recordatorios por WhatsApp** configurables
- 👥 **Gestión de usuarios y roles** (admin, veterinario, recepcionista)
- 🏥 **Configuración de clínica** con horarios y plantillas
- 🎨 **Interfaz moderna** con Material Design 3

## Instalación

### Requisitos previos

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Firebase CLI (para deploy)

### Pasos

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/vetmanager.git
   cd vetmanager
   ```

2. Instalar dependencias:
   ```bash
   flutter pub get
   ```

3. Configurar Firebase:
   ```bash
   flutterfire configure
   ```

4. Ejecutar la aplicación:
   ```bash
   flutter run
   ```

## Estructura del proyecto

```
lib/
├── app.dart                 # Configuración de la app y rutas
├── main.dart                # Punto de entrada
├── firebase_options.dart    # Opciones de Firebase
├── models/                  # Modelos de datos
├── providers/               # Gestión de estado (Provider)
├── screens/                 # Pantallas de la aplicación
├── services/                # Servicios de Firebase y APIs
├── utils/                   # Constantes y utilidades
└── widgets/                 # Widgets reutilizables
```

## Scripts útiles

### Build para web
```bash
flutter build web --release
```

### Build APK
```bash
flutter build apk --release
```

### Deploy a Firebase Hosting
```bash
firebase deploy --only hosting
```

### Deploy rápido (Windows)
Ejecutar `deploy-web.bat`:
```batch
@echo off
echo Building VetClick for web...
flutter build web --release
echo Deploying to Firebase...
firebase deploy --only hosting
echo Done!
pause
```

## Reglas de seguridad

- `firestore.rules` — Reglas de desarrollo (permissivas)
- `firestore.rules.prod` — Reglas de producción (restringidas por clínica y rol)

## Licencia

Copyright © 2024 VetClick. Todos los derechos reservados.

Este software es propietario. Su uso, distribución o modificación sin autorización expresa está prohibida.
