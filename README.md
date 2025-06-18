# Aplicación de Asistencia para Organización Cristiana

Este proyecto es una aplicación móvil desarrollada en Flutter para la gestión de asistencia en reuniones de una organización cristiana. Permite llevar un registro detallado de los asistentes por sector, comuna y ciudad, así como gestionar usuarios, roles, eventos y reportes avanzados.

---

## 1. Funcionalidades Principales

### Para Administradores
- **Dashboard de administración** con KPIs y gráficos dinámicos:
  - Asistencia total y promedio mensual
  - Asistencia por tipo de reunión
  - Acceso rápido a gestión de usuarios, localidades y reportes
- **Gestión de usuarios**: aprobar, asignar roles, activar/desactivar
- **Gestión de asistentes**: miembros y oyentes, activación/desactivación
- **Gestión de localidades**: ciudades, comunas y sectores (localidades)
- **Gestión de eventos/reuniones**: creación y visualización de reuniones recurrentes
- **Reportes detallados**:
  - Filtros por ciudad, comuna, sector y rango de fechas
  - KPIs y gráficos de asistencia por semana, por ciudad y comuna, por comuna y sector
  - Gráfico de asistencia total por número de semana (todo el año)
- **Visualización de visitas**: registro y conteo de visitas en la asistencia

### Para Usuarios
- **Dashboard de usuario**:
  - KPIs de asistencia total y promedio semanal de su sector
  - Gráfico de barras semanal de asistencia
  - Resumen de asistencia de la última semana
- **Registro de asistencia**: solo para su sector asignado
- **Visualización de eventos y asistentes**
- **Gestión de perfil y cierre de sesión**

---

## 2. Estructura del Proyecto

```
asistencias_cristianaa/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── providers/
│   │   ├── services/
│   │   └── utils/
│   ├── data/
│   │   └── models/
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── admin_dashboard/
│   │   │   ├── user_dashboard/
│   │   │   ├── admin/
│   │   │   ├── attendees/
│   │   │   ├── record_attendance/
│   │   │   ├── auth/
│   │   │   └── ...
│   │   └── widgets/
│   └── firebase_options.dart
├── android/
├── ios/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 3. Requisitos Previos
- Flutter SDK (versión estable más reciente)
- Dart SDK
- Android Studio / VS Code
- Cuenta de Firebase
- Dispositivo Android/iOS o emulador

---

## 4. Instalación y Ejecución

### 4.1. Clonar el Repositorio
```bash
git clone https://github.com/CiroCortes/asistencias_cristianaa.git
cd asistencias_cristianaa
```

### 4.2. Instalar Dependencias
```bash
flutter pub get
```

### 4.3. Configurar Firebase
1. Crear un proyecto en Firebase Console
2. Descargar el archivo `google-services.json` y colocarlo en `android/app/`
3. Descargar el archivo `GoogleService-Info.plist` y colocarlo en `ios/Runner/`

### 4.4. Ejecutar la Aplicación
```bash
flutter run
```

---

## 5. Notas Técnicas y Dependencias
- **Gráficos**: Se utiliza el paquete [`fl_chart`](https://pub.dev/packages/fl_chart) para visualización de datos y KPIs.
- **Firebase**: Autenticación y Firestore para persistencia de datos.
- **Provider**: Gestión de estado global.
- **Estructura modular**: Separación clara entre lógica de negocio, presentación y modelos de datos.

---

## 6. Contacto y Contribución
- Ciro Cortés - [@CiroCortes](https://github.com/CiroCortes)
- Link del Proyecto: [https://github.com/CiroCortes/asistencias_cristianaa](https://github.com/CiroCortes/asistencias_cristianaa)

### Contribuir
1. Fork el repositorio
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

---

## 7. Licencia
Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE.md](LICENSE.md) para más detalles.
