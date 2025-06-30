# 🧪 Script de Generación de Datos de Prueba - Quilicura

Este script genera datos de prueba para la ruta **Quilicura** con asistentes TEST y registros de asistencia para **junio y julio 2025**.

## 📋 ¿Qué genera el script?

### ✅ **Datos que se AGREGAN:**
- **~100 Asistentes TEST** (10 por cada sector existente en Quilicura)  
- **~800 Registros de asistencia** para junio y julio 2025 (4 tipos de reuniones × 2 meses × sectores)
- **4 Eventos recurrentes básicos** (si no existen ya)

### 🚫 **Datos que NO se tocan:**
- Ciudad Santiago (existente)
- Ruta Quilicura (existente)
- Sectores de Quilicura (existentes)
- Usuarios existentes

### 🎯 **Nota importante:**
Los datos se generan para **junio y julio 2025** específicamente para **demo con cliente**. Esto asegura que los reportes muestren información fresca y reciente durante la presentación.

## 💰 Costo estimado de Firebase
- **Escrituras**: ~900 writes × $0.18/100K = **$0.0016 USD**
- **Almacenamiento**: ~900KB × $0.00002/mes = **$0.00002/mes**
- **COSTO TOTAL: < $0.002 USD** (menos de 2 centavos) 🎯

## 🛠️ Configuración

### 1. ✅ Configuración Firebase - ¡LISTA!

**¡YA NO NECESITAS CONFIGURAR NADA!**
- ✅ El script usa automáticamente las credenciales de tu proyecto Flutter
- ✅ Lee directamente de `lib/firebase_options.dart`
- ✅ Sin configuración manual requerida

### 2. Verificar dependencias

Asegúrate de que tu `pubspec.yaml` incluye:

```yaml
dependencies:
  cloud_firestore: ^4.13.0
  firebase_core: ^2.21.0
```

## 🚀 Ejecutar el script

### 🎯 **Opción 1: Desde la App (RECOMENDADO para demo)**
**Solo para el usuario: `ciro.720@gmail.com`**

1. Inicia sesión como admin con el email autorizado
2. Ve al **Panel de Administración**  
3. Abre el **menú lateral** (drawer) ☰
4. Busca la opción **"🧪 Generar Datos de Prueba"**
5. Confirma y ¡listo! ✅

**Ventajas:**
- ✅ Sin comandos de terminal
- ✅ Feedback visual en tiempo real  
- ✅ Perfecto para demo con cliente
- ✅ Acceso controlado por email

### Opción 2: Terminal (desarrollo)
```bash
cd scripts
dart generate_test_data.dart
```

### Opción 3: Desde proyecto Flutter
```bash
# Desde la raíz del proyecto
flutter pub get
dart scripts/generate_test_data.dart
```

## 📊 Datos generados

### 👥 **Asistentes TEST** (10 por sector)
```
Nombres: Juan TEST, María TEST, Carlos TEST...
Apellidos: García 1, Rodríguez 2, González 3...
Tipos: 50% member, 50% listener
Contacto: +569XXXXXXXX (números chilenos)
Estado: isActive = true
```

### 📅 **Eventos Recurrentes** (si no existen)
1. **Reunión de Miércoles** - 19:30
2. **Predicación Sábado** - 10:00  
3. **Reunión Domingo AM** - 10:00
4. **Reunión Domingo PM** - 16:00

### 📊 **Registros de Asistencia - Junio y Julio 2025**

**📅 Fechas de JUNIO 2025:**
- **Miércoles**: 4, 11, 18, 25 (19:30)
- **Sábados**: 7, 14, 21, 28 (10:00)
- **Domingos AM**: 1, 8, 15, 22, 29 (10:00)
- **Domingos PM**: 1, 8, 15, 22, 29 (16:00)

**📅 Fechas de JULIO 2025:**
- **Miércoles**: 2, 9, 16, 23, 30 (19:30)
- **Sábados**: 5, 12, 19, 26 (10:00)
- **Domingos AM**: 6, 13, 20, 27 (10:00)
- **Domingos PM**: 6, 13, 20, 27 (16:00)

**Asistencia simulada:**
- **60-85%** de asistentes por reunión (variación realista)
- **0-5 visitas** por reunión
- **Asistentes aleatorios** cada vez

## 🔍 Verificar resultados

### En Firebase Console:
1. Ve a **Firestore Database**
2. Revisa las colecciones:
   - `attendees` - Busca nombres con "TEST"
   - `attendanceRecords` - Filtra por junio-julio 2025
   - `recurring_meetings` - Verifica eventos

### En la app Flutter:
1. **Dashboard Admin**: Selecciona ciudad y ruta Quilicura
2. **Gestión de Asistentes**: Filtra por Quilicura  
3. **Reportes**: Revisa gráficos de junio-julio 2025 🎯

## 🧹 Limpiar datos de prueba

Cuando termines la demo, puedes eliminar todos los datos TEST:

```bash
dart scripts/cleanup_test_data.dart
```

**Este script eliminará:**
- ✅ Todos los asistentes con nombres "TEST"
- ✅ Registros de asistencia de junio-julio 2025 
- ✅ Eventos recurrentes creados por el script
- ✅ Solo datos generados automáticamente

**⚠️ Datos que NO se tocan:**
- ❌ Asistentes reales existentes
- ❌ Registros de asistencia reales
- ❌ Configuración de sectores/rutas

## ⚠️ Consideraciones importantes

### ✅ **Seguro ejecutar:**
- ✅ El script NO modifica datos existentes
- ✅ Solo AGREGA datos nuevos con identificador TEST
- ✅ Costo muy bajo (< 1 centavo)
- ✅ Los datos se pueden identificar y eliminar fácilmente

### 🚨 **Precauciones:**
- 🚨 **Ejecutar solo UNA vez** (evitar duplicados)
- 🚨 **Verificar configuración Firebase** antes de ejecutar
- 🚨 **Respaldar base de datos** si tienes datos críticos
- 🚨 **Probar en ambiente de desarrollo** primero

## 🐛 Resolución de problemas

### Error: "No se encontró la ruta Quilicura"
**Solución**: Verificar que existe una comuna llamada exactamente "Quilicura"

### Error: "No hay sectores en Quilicura" 
**Solución**: Verificar que la comuna Quilicura tiene sectores asignados

### Error de configuración Firebase
**Solución**: Verificar que los valores de configuración son correctos

### Error de permisos Firestore
**Solución**: Verificar reglas de seguridad de Firestore

## 📞 Soporte

Si tienes problemas:
1. Revisa que la ruta Quilicura existe en Firebase Console
2. Verifica la configuración de Firebase
3. Ejecuta paso a paso para identificar dónde falla
4. Revisa las reglas de seguridad de Firestore

---
**💡 Tip**: Ejecuta el script un viernes para tener datos frescos el lunes para demos y pruebas. 