# Aplicación de Asistencia para Organización Cristiana

Este proyecto es una aplicación móvil desarrollada en Flutter para la gestión de asistencia en reuniones de una organización cristiana. Permite llevar un registro detallado de los asistentes por sector, comuna y ciudad, así como gestionar usuarios y roles.

## 1. Estructura del Proyecto
```
flutter_attendance_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   └── firebase_options.dart  (Configuración de Firebase)
│   ├── core/
│   │   ├── constants/             (Constantes de la aplicación: rutas, cadenas, etc.)
│   │   │   └── app_constants.dart
│   │   ├── models/               (Modelos de datos)
│   │   │   ├── user_model.dart
│   │   │   └── attendance_model.dart
│   │   ├── services/            (Servicios: Firebase, autenticación, etc.)
│   │   │   ├── auth_service.dart
│   │   │   └── firebase_service.dart
│   │   └── utils/               (Utilidades y helpers)
│   │       └── permission_utils.dart
│   └── presentation/            (UI y lógica de presentación)
│       ├── screens/             (Pantallas de la aplicación)
│       │   ├── auth/
│       │   │   ├── login_screen.dart
│       │   │   └── register_screen.dart
│       │   ├── admin/
│       │   │   └── admin_dashboard_screen.dart
│       │   └── user/
│       │       └── user_dashboard_screen.dart
│       └── widgets/             (Widgets reutilizables)
│           └── common/
│               └── custom_button.dart
├── android/                     (Configuración específica de Android)
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── ios/                        (Configuración específica de iOS)
│   └── Runner/
│       └── Info.plist
├── test/                       (Pruebas unitarias y de integración)
│   └── widget_test.dart
├── pubspec.yaml                (Dependencias y configuración del proyecto)
└── README.md                   (Este archivo)
```

## 2. Características Principales
- Autenticación de usuarios con Firebase
- Gestión de roles (admin, usuario)
- Registro de asistencia por sector/comuna
- Dashboard administrativo
- Interfaz de usuario intuitiva

## 3. Requisitos Previos
- Flutter SDK (versión estable más reciente)
- Dart SDK
- Android Studio / VS Code
- Cuenta de Firebase
- Dispositivo Android/iOS o emulador

## 4. Configuración del Proyecto

### 4.1. Pasos Completados
1. **Configuración Inicial de Flutter**: El proyecto ha sido inicializado con Flutter y configurado con las dependencias necesarias.
2. **Integración de Firebase**: Se ha configurado Firebase en el proyecto, incluyendo la autenticación y Firestore.
3. **Estructura de Carpetas**: Se ha establecido una estructura de carpetas organizada siguiendo las mejores prácticas de Flutter.
4. **Configuración de Android**: Se ha actualizado el archivo `build.gradle` para usar la versión 8.2.0 del Android Gradle Plugin y se ha configurado la aplicación para Android 13 (API 33).
5. **Configuración de iOS**: Se ha actualizado el archivo `Podfile` para usar la versión 1.12.1 de CocoaPods y se ha configurado la aplicación para iOS 12.0.
6. **Configuración de Firebase**: Se ha configurado Firebase en el proyecto, incluyendo la autenticación y Firestore.
7. **Configuración de Git**: Se ha configurado Git en el proyecto, incluyendo el archivo `.gitignore`.
8. **Configuración de Dependencias**: Se han configurado las dependencias necesarias en el archivo `pubspec.yaml`.
9. **Inicialización de Repositorio Git**: El repositorio Git ha sido inicializado y el primer commit realizado.
10. **Refactorización y Estabilización de Autenticación Firebase (Google Sign-In y Roles)**: Se abordaron y resolvieron múltiples errores relacionados con la autenticación de Firebase y Google Sign-In (`type List<Object?>' is not a subtype of type 'PigeonUserDetails?` y `java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'`). Esto incluyó:
    * Actualización de las versiones de `firebase_auth` (a `^5.6.0`), `firebase_core` (a `^3.14.0`) y `cloud_firestore` (a `^5.6.9`) para garantizar la compatibilidad entre paquetes.
    * Creación e integración de `lib/core/utils/permission_utils.dart` para centralizar la lógica de permisos y roles de usuario.
    * Implementación de `lib/core/providers/user_provider.dart` para gestionar el estado del usuario (`UserModel`) a través de `Provider`.
    * Modificación de `lib/presentation/screens/admin_dashboard/admin_dashboard_screen.dart` para usar `UserProvider` y aplicar permisos.
    * Verificación y ajuste de la configuración SHA-1 en Firebase.
    * Actualización del `README.md` con los avances.

### 4.2. Próximos Pasos
1. **Implementación de la UI**: Desarrollar las interfaces de usuario para todas las pantallas.
2. **Implementación de la Lógica de Negocio**: Desarrollar la lógica de negocio para todas las funcionalidades.
3. **Pruebas**: Realizar pruebas unitarias y de integración.
4. **Despliegue**: Desplegar la aplicación en las tiendas de aplicaciones.

## 5. Guía de Instalación

### 5.1. Clonar el Repositorio
```bash
git clone https://github.com/CiroCortes/asistencias_cristianaa.git
cd asistencias_cristianaa
```

### 5.2. Instalar Dependencias
```bash
flutter pub get
```

### 5.3. Configurar Firebase
1. Crear un proyecto en Firebase Console
2. Descargar el archivo `google-services.json` y colocarlo en `android/app/`
3. Descargar el archivo `GoogleService-Info.plist` y colocarlo en `ios/Runner/`

### 5.4. Ejecutar la Aplicación
```bash
flutter run
```

## 6. Contribución
1. Fork el repositorio
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 7. Licencia
Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE.md](LICENSE.md) para más detalles.

## 8. Contacto
Ciro Cortés - [@CiroCortes](https://github.com/CiroCortes)

Link del Proyecto: [https://github.com/CiroCortes/asistencias_cristianaa](https://github.com/CiroCortes/asistencias_cristianaa)
