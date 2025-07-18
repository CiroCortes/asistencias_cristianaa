# IBBN Asistencias - Versión Cliente

## 📱 Información del Proyecto

**Nombre de la App:** IBBN Asistencias  
**Package Name:** `com.ibborganitation.asistencias_app_2025`  
**Versión:** Cliente específico para IBBN  
**Fecha de Entrega:** Julio 2025  

## 🔧 Configuraciones Específicas

### Autenticación
- ✅ **Solo Google Sign-In** habilitado
- ❌ Registro manual deshabilitado
- ✅ Sistema de aprobación manual para nuevos usuarios
- ✅ Usuarios desactivados (no eliminados) para mantener KPIs

### Sistema de Semanas
- ✅ **Numeración NO ISO**: Semana 1 comienza el 1 de enero
- ✅ Cada semana inicia el lunes
- ✅ Ejemplo: 17 de julio de 2025 = Semana 29

### Firebase
- ✅ Configuración específica para cliente IBB
- ✅ Reglas de Firestore configuradas hasta 2030
- ✅ Acceso controlado por roles de usuario

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.x
- Android Studio / VS Code
- Cuenta de desarrollador Google
- Proyecto Firebase configurado

### Pasos de Instalación

1. **Clonar la rama específica:**
```bash
git clone -b cliente-ibbn-asistencias https://github.com/CiroCortes/asistencias_cristianaa.git
cd asistencias_cristianaa
```

2. **Instalar dependencias:**
```bash
flutter pub get
```

3. **Configurar Firebase:**
   - Asegurar que `firebase_options.dart` esté configurado para el proyecto IBB
   - Verificar que las reglas de Firestore estén activas

4. **Compilar para Android:**
```bash
flutter build apk --release
```

## 📊 Funcionalidades Principales

### Para Usuarios
- ✅ Dashboard con estadísticas de asistencia
- ✅ Registro de asistencia en eventos
- ✅ Visualización de eventos disponibles
- ✅ Gestión de asistentes
- ✅ Perfil de usuario

### Para Administradores
- ✅ Dashboard administrativo completo
- ✅ Gestión de usuarios y sectores
- ✅ Creación y gestión de eventos
- ✅ Reportes detallados (Excel)
- ✅ Reportes semanales, mensuales y trimestrales
- ✅ Gestión de ubicaciones

## 🔍 Características Técnicas

### Estructura del Proyecto
```
lib/
├── core/
│   ├── providers/     # Estado de la aplicación
│   ├── services/      # Lógica de negocio
│   └── utils/         # Utilidades (fechas, permisos)
├── data/
│   └── models/        # Modelos de datos
└── presentation/
    └── screens/       # Pantallas de la aplicación
```

### Tecnologías Utilizadas
- **Frontend:** Flutter 3.x
- **Backend:** Firebase (Firestore, Auth)
- **Autenticación:** Google Sign-In
- **Reportes:** Excel export
- **Gráficos:** fl_chart

## 📈 Reportes Disponibles

### Reportes Semanales
- Asistencia por tipo (miembros, oyentes, visitas)
- TTL por días específicos (miércoles, sábados, domingos)
- Gráficos de tendencias

### Reportes Mensuales
- Resumen de asistencia mensual
- Comparación con meses anteriores
- Exportación a Excel

### Reportes Trimestrales
- Análisis de tendencias trimestrales
- KPIs de crecimiento
- Reportes detallados por sector

## 🔐 Seguridad

### Reglas de Firestore
- Acceso controlado por roles de usuario
- Validación de datos en servidor
- Protección contra acceso no autorizado

### Autenticación
- Verificación de dominio de email
- Aprobación manual de nuevos usuarios
- Desactivación en lugar de eliminación

## 🐛 Solución de Problemas

### Problema: Semana incorrecta en dashboard
**Causa:** Registros antiguos con numeración de semanas anterior  
**Solución:** Los nuevos registros usarán la numeración correcta automáticamente

### Problema: Usuario no puede acceder
**Causa:** Usuario no aprobado o desactivado  
**Solución:** Contactar al administrador para activar la cuenta

### Problema: Error de autenticación
**Causa:** Configuración de Firebase incorrecta  
**Solución:** Verificar `firebase_options.dart` y credenciales

## 📞 Soporte

Para soporte técnico o preguntas sobre la implementación:
- **Desarrollador:** Ciro Cortés
- **Email:** [Email de contacto]
- **GitHub:** https://github.com/CiroCortes/asistencias_cristianaa

## 📝 Notas de Versión

### v1.0.0 (Cliente IBB)
- ✅ Configuración específica para IBBN
- ✅ Sistema de semanas NO ISO implementado
- ✅ Solo Google Sign-In habilitado
- ✅ Reportes completos implementados
- ✅ Gestión de usuarios mejorada
- ✅ Dashboard administrativo completo

---

**Última actualización:** Julio 2025  
**Estado:** ✅ Listo para producción 