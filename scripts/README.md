# 📁 Scripts de Desarrollo

Esta carpeta contiene herramientas de desarrollo para análisis y mantenimiento de la base de datos.

## 📋 Scripts disponibles:

### ✅ `check_data_consistency.dart`
**Propósito**: Análisis de consistencia de datos en Firestore
- Verifica registros de asistencia
- Analiza asistentes y meetings
- Reporta inconsistencias y problemas
- **No modifica datos** - Solo análisis

**Ejecutar**:
```bash
dart scripts/check_data_consistency.dart
```

## 🚫 Scripts eliminados (ahora integrados en la app):

### ~~`generate_test_data.dart`~~ ✨ **Ahora en la app**
- **Nueva ubicación**: Panel Admin → ⚙️ Utilidades de Administrador → Generar Datos TEST
- **Ventajas**: Interfaz visual, feedback en tiempo real, más seguro

### ~~`cleanup_test_data.dart`~~ ✨ **Ahora en la app**  
- **Nueva ubicación**: Panel Admin → ⚙️ Utilidades de Administrador → Limpiar Datos
- **Opciones**: Analizar, Solo TEST, Limpieza completa
- **Ventajas**: Confirmaciones, progreso visual, más control

### ~~`simple_check.dart`~~ ✨ **Integrado**
- Funcionalidad incluida en `check_data_consistency.dart`

### ~~`debug_firebase.dart`~~ ✨ **Obsoleto**
- Reemplazado por las herramientas integradas en la app

## 🎯 **Recomendación de uso:**

### Para desarrollo/debug:
```bash
# Verificar consistencia de datos
dart scripts/check_data_consistency.dart
```

### Para operaciones normales:
1. Abrir la aplicación Flutter
2. Ir a **Panel de Administración**
3. Usar **⚙️ Utilidades de Administrador**

## 💡 **Ventajas de la integración:**

### ✅ **Mayor seguridad**:
- Confirmaciones antes de operaciones destructivas
- Control de permisos por usuario
- Interfaz visual clara

### ✅ **Mejor experiencia**:
- Feedback en tiempo real
- Progreso visual
- Sin necesidad de comandos de terminal

### ✅ **Menos errores**:
- Validaciones automáticas
- Manejo de errores mejorado
- Prevención de ejecuciones accidentales

---

**💡 Tip**: Para operaciones administrativas regulares, usa siempre la interfaz de la app en lugar de scripts externos. 