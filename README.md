Aplicación de Asistencia para Organización Cristiana
Este proyecto es una aplicación móvil desarrollada en Flutter para la gestión de asistencia en reuniones de una organización cristiana. Permite llevar un registro detallado de los asistentes por sector, comuna y ciudad, así como gestionar usuarios y roles.

1. Estructura del Proyecto
flutter_attendance_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   └── firebase_options.dart  (Configuración de Firebase)
│   ├── core/
│   │   ├── constants/             (Constantes de la aplicación: rutas, cadenas, etc.)
│   │   │   └── app_constants.dart
│   │   ├── errors/                (Modelos de errores personalizados)
│   │   │   └── exceptions.dart
│   │   ├── utils/                 (Utilidades generales: helpers, validadores, etc.)
│   │   │   └── app_utils.dart
│   │   └── services/              (Servicios de bajo nivel: Firebase Auth, Firestore)
│   │       ├── auth_service.dart
│   │       └── firestore_service.dart
│   ├── data/
│   │   ├── models/                (Modelos de datos: User, Attendee, Location, AttendanceRecord)
│   │   │   ├── user_model.dart
│   │   │   ├── attendee_model.dart
│   │   │   ├── location_model.dart
│   │   │   └── attendance_record_model.dart
│   │   ├── repositories/          (Interfaces de repositorios para acceso a datos)
│   │   │   ├── auth_repository.dart
│   │   │   ├── attendance_repository.dart
│   │   │   └── user_repository.dart
│   │   └── datasources/           (Implementaciones de repositorios que interactúan con Firebase)
│   │       ├── firebase_auth_datasource.dart
│   │       ├── firebase_attendance_datasource.dart
│   │       └── firebase_user_datasource.dart
│   ├── domain/
│   │   ├── entities/              (Entidades de dominio: UserEntity, AttendeeEntity, etc.)
│   │   │   ├── user_entity.dart
│   │   │   ├── attendee_entity.dart
│   │   │   ├── location_entity.dart
│   │   │   └── attendance_record_entity.dart
│   │   ├── repositories/          (Contratos de repositorios para el dominio)
│   │   │   ├── auth_repository.dart
│   │   │   ├── attendance_repository.dart
│   │   │   └── user_repository.dart
│   │   └── usecases/              (Casos de uso: LoginUser, RegisterAttendance, GetAttendees)
│   │       ├── auth/
│   │       │   └── login_user.dart
│   │       ├── attendance/
│   │       │   └── register_attendance.dart
│   │       └── user/
│   │           └── create_user.dart
│   ├── presentation/
│   │   ├── providers/             (Providers para la gestión de estado con la lógica de negocio)
│   │   │   ├── auth_provider.dart
│   │   │   ├── user_provider.dart
│   │   │   ├── attendee_provider.dart
│   │   │   └── attendance_provider.dart
│   │   ├── screens/               (Vistas de la aplicación)
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   │   └── admin_approval_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── attendance/
│   │   │   │   └── register_attendance_screen.dart
│   │   │   │   └── attendance_list_screen.dart
│   │   │   ├── admin_dashboard/
│   │   │   │   └── admin_dashboard_screen.dart
│   │   │   │   └── user_management_screen.dart
│   │   │   │   └── location_management_screen.dart
│   │   │   ├── user_dashboard/
│   │   │   │   └── user_dashboard_screen.dart
│   │   │   └── common_widgets/    (Widgets reutilizables)
│   │   │       ├── custom_button.dart
│   │   │       └── loading_indicator.dart
│   │   ├── routes/                (Manejo de rutas de navegación)
│   │   │   └── app_router.dart
│   │   └── theme/                 (Temas y estilos de la aplicación)
│   │       └── app_theme.dart
└── pubspec.yaml
└── README.md
└── firebase.json
└── project.json
2. Puntos Clave del Desarrollo
2.1. Gestión de Base de Datos en Tiempo Real (Firebase Firestore)
Colecciones Principales:
users: Almacenará los usuarios de la aplicación (quienes toman asistencia, administradores).
attendees: Almacenará a los asistentes (miembros, visitas, oyentes).
locations: Almacenará la jerarquía de Ciudad > Comuna > Sector.
attendance_records: Registrará la asistencia por reunión, incluyendo fecha, hora, tipo de reunión (miércoles, sábado, domingo AM/PM), sector, y los asistentes presentes.
Modelos de Datos (data/models/):
UserModel:
Dart

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'normal_user', 'admin'
  final String? sectorId; // ID del sector al que pertenece el usuario normal
  final bool isApproved; // Para la aprobación del administrador
  // Constructor, fromJson, toJson
}
AttendeeModel:
Dart

class AttendeeModel {
  final String id;
  final String name;
  final String type; // 'member', 'visitor', 'listener'
  final String sectorId;
  final String? contactInfo;
  // Constructor, fromJson, toJson
}
LocationModel:
Dart

class LocationModel {
  final String id;
  final String name;
  final String type; // 'city', 'commune', 'sector'
  final String? parentId; // Para la jerarquía
  // Constructor, fromJson, toJson
}
AttendanceRecordModel:
Dart

class AttendanceRecordModel {
  final String id;
  final String sectorId;
  final DateTime date;
  final String meetingType; // 'miercoles', 'sabado', 'domingo_am', 'domingo_pm'
  final List<String> attendedAttendeeIds; // IDs de los asistentes presentes
  final String recordedByUserId; // ID del usuario que registró la asistencia
  // Constructor, fromJson, toJson
}
Reglas de Seguridad de Firestore: Se configurarán reglas robustas para asegurar que solo usuarios autenticados y con los roles adecuados puedan leer y escribir datos. Por ejemplo, los usuarios normales solo podrán registrar asistencia en su sector asignado.
2.2. Autenticación (Firebase Authentication)
Google Sign-In: Implementación de inicio de sesión con Google.
Aprobación por Administrador: Tras el registro inicial con Google, el usuario quedará en un estado isApproved: false. Un administrador deberá aprobarlo para que pueda acceder a las funcionalidades de la aplicación. Esto se manejará en el AuthProvider y en la lógica de navegación.
2.3. Patrón de Gestión de Estado (Provider)
Se utilizará el patrón Provider para gestionar el estado de la aplicación de manera eficiente y escalable.
AuthProvider: Encargado de la lógica de autenticación (login, logout, manejo del estado del usuario).
UserProvider: Gestiona la información de los usuarios, incluyendo su rol y la aprobación. Permite a los administradores modificar roles y estados de aprobación.
AttendeeProvider: Maneja la creación, lectura, actualización y eliminación (CRUD) de asistentes.
AttendanceProvider: Administra el registro de asistencia, recuperación de registros y reportes.
2.4. Roles y Permisos
Usuario Normal (normal_user):
Puede registrar asistencia para su sector asignado.
Puede ver el dashboard de su sector (reportes básicos, lista de asistentes).
Puede modificar la asistencia registrada por él mismo (ej. añadir asistentes que llegaron tarde o salieron temprano).
Puede agregar nuevos asistentes a su sector (visitas/oyentes).
Administrador (admin):
Acceso completo a la gestión de usuarios (aprobación, asignación de roles, modificación de datos).
Acceso completo a la gestión de ubicaciones (ciudades, comunas, sectores).
Puede agregar asistentes a cualquier barrio o sector.
Dashboard completo con reportes globales y detallados.
2.5. Gestión de Ubicaciones
Una pantalla de mantenimiento permitirá a los administradores agregar, modificar y eliminar Ciudades, Comunas y Sectores, manteniendo la jerarquía.
2.6. Dashboards y Reportes
Dashboard de Usuario Normal:
Resumen de asistencia en su sector.
Lista de asistentes registrados en su sector.
Historial de asistencia por reunión.
Dashboard de Administrador:
Visión global de la asistencia por ciudad, comuna y sector.
Reportes de asistencia por tipo de reunión.
Lista de usuarios y su estado de aprobación/rol.
Control de gestión de ubicaciones.
Reportes sobre el tipo de asistentes (miembros, visitas, oyentes).
2.7. Entorno de Desarrollo y Producción
Configuración de Firebase: Se utilizará firebase_options.dart para configurar la conexión a Firebase. Para facilitar la exportación, se asegurará que la configuración del proyecto de Firebase (archivos google-services.json para Android y GoogleService-Info.plist para iOS) pueda ser fácilmente reemplazada por la del cliente final.
Archivos de Configuración: Los archivos firebase.json y project.json (o equivalentes para exportar configuración de Firestore/Functions si se usaran) se mantendrán genéricos o con placeholders para la configuración del cliente.
Documentación de Despliegue: Se incluirán instrucciones claras sobre cómo el cliente final puede reemplazar las credenciales de Firebase en el proyecto exportado.
3. Posibles Mejoras Futuras
Notificaciones Push: Recordatorios para registrar asistencia, o notificaciones para administradores sobre nuevas solicitudes de usuario.
Soporte Offline: Permitir a los usuarios registrar asistencia incluso sin conexión a internet y sincronizar los datos una vez que la conexión se restablezca.
Importación/Exportación de Datos: Funcionalidad para importar listas de asistentes desde un archivo CSV o exportar reportes.
Perfiles de Asistentes: Información más detallada para cada asistente (fecha de nacimiento, estado civil, fecha de ingreso a la organización, etc.).
Sistema de Eventos: Posibilidad de registrar asistencia a eventos especiales fuera de las reuniones regulares.
Análisis de Datos Avanzado: Gráficos y estadísticas más sofisticadas en los dashboards.
Historial de Cambios: Registrar quién modificó un registro de asistencia o un perfil de asistente.
QR Code / Barcode Scan: Para un registro de asistencia más rápido en reuniones grandes.
Internacionalización: Soporte para múltiples idiomas si la organización es global.
Pruebas Unitarias e Integración: Implementar pruebas exhaustivas para asegurar la calidad y estabilidad de la aplicación.
CI/CD: Configurar pipelines de Integración Continua y Despliegue Continuo para automatizar el proceso de construcción y entrega.
Funciones de Cloud (Firebase Functions): Para lógica de negocio compleja, como enviar emails automáticos, generar reportes programados o validar datos en el backend. Por ejemplo, para automatizar la aprobación de usuarios en ciertos escenarios o notificar sobre baja asistencia.

## 4. Progreso y Próximos Pasos

### 4.1. Pasos Completados:

1.  **Actualización del Android Gradle Plugin (AGP)**: Se actualizó la versión del AGP a 8.2.1 o superior en `asistencias_app/android/settings.gradle` para resolver problemas de compatibilidad con Java 21.
2.  **Habilitación de la API de Cloud Firestore**: Se guió en la habilitación de la API de Firestore en la consola de Firebase para resolver errores de `PERMISSION_DENIED`.
3.  **Configuración y Consolidación de Archivos `.gitignore`**: Se revisaron y consolidaron las reglas de `.gitignore`, asegurando que archivos sensibles como `google-services.json` sean ignorados adecuadamente en `asistencias_app/android/.gitignore`, y se eliminó el archivo `.gitignore` redundante.
4.  **Discusión sobre Reglas de Seguridad de Firestore**: Se proporcionó orientación sobre las reglas de seguridad de Firestore, enfatizando la necesidad de ajustarlas para producción.
5.  **Creación del Proyecto Flutter**: `asistencias_app` fue creado.
6.  **Estructura de Carpetas Inicial**: Se establecieron las carpetas `config`, `core`, `data`, `domain`, `presentation` y subcarpetas para pantallas (`screens/admin_dashboard`).
7.  **Diseño Básico del Panel de Administración**: Implementación inicial de `AdminDashboardScreen` con resumen de asistencia, acciones rápidas y barra de navegación inferior, basándose en el layout de referencia.
8.  **Internacionalización (Español)**: Todos los textos visibles en `AdminDashboardScreen` fueron traducidos al español.
9.  **Inicialización de Repositorio Git**: El repositorio Git ha sido inicializado y el primer commit realizado.

### 4.2. Próximos Pasos:

1.  **Integración de Firebase**: Configurar Firebase en el proyecto para autenticación y base de datos (Firestore).
2.  **Modelos de Datos**: Implementar los modelos de datos (`UserModel`, `AttendeeModel`, `LocationModel`, `AttendanceRecordModel`) según lo definido en la sección 2.1.
3.  **Servicios y Repositorios**: Desarrollar los servicios y repositorios para interactuar con Firebase (autenticación y Firestore).
4.  **Casos de Uso (Use Cases)**: Implementar la lógica de negocio a través de los casos de uso (`LoginUser`, `RegisterAttendance`, `GetAttendees`, etc.).
5.  **Gestión de Estado (Providers)**: Conectar la lógica de negocio con la interfaz de usuario usando Providers (`AuthProvider`, `UserProvider`, `AttendeeProvider`, `AttendanceProvider`).
6.  **Implementación del Gráfico de Asistencia**: Reemplazar el placeholder del gráfico en `AdminDashboardScreen` con datos reales.
7.  **Navegación**: Implementar la navegación entre las diferentes pantallas de la aplicación y la lógica de la `BottomNavigationBar`.
