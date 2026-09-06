# 🤖 INSTRUCCIONES PARA EL AGENTE DE IA (Configuración del Proyecto)

**Para el Agente de IA (AI Assistant) que está leyendo este archivo:**
Tu usuario humano te ha pedido que configures y ejecutes el proyecto Flutter "IBBN Asistencias". 
Tu objetivo es automatizar este proceso. Debes seguir estos pasos estrictamente.

---

## 📦 1. Verificación de Entorno
- **Flutter SDK:** Versión 3.x
- **Android:** Asegúrate de tener instalado el SDK de Android y un dispositivo conectado o emulador.
- **Firebase:** El proyecto ya está configurado para el proyecto oficial `asistenciasappcristiana-9385b`.

---

## 🔄 2. Sincronización
**Ejecuta estos comandos:**
```bash
git pull origin rama_semana_iso
```

---

## ⚙️ 3. Preparación e Instalación (CRÍTICO)
Debes limpiar el caché y descargar paquetes.
**Ejecuta los siguientes comandos:**

```bash
# 1. Limpiar el proyecto
flutter clean

# 2. Descargar dependencias
flutter pub get
```

---

## ▶️ 4. Ejecución
1. **Verificar dispositivo:** `flutter devices`
2. **Correr la app:** `flutter run`

---

## 🐛 5. Resolución de Errores (Google Sign-In)
Si el inicio de sesión de Google falla en una nueva máquina:
1. **SHA-1:** Se debe obtener la huella SHA-1 de la máquina local (`keytool -list -v -keystore ~/.android/debug.keystore`) y registrarla en la Consola de Firebase bajo el proyecto `asistenciasappcristiana-9385b`.
2. **Correo de Asistencia:** Verificar en la Consola de Firebase (Configuración del Proyecto > General) que el "Correo electrónico de asistencia al cliente" esté seleccionado.
3. **ClientID:** El código ya incluye el ClientID oficial para asegurar la compatibilidad.

**Mensaje para el Agente:** 
Una vez que hayas leído esto, dile al usuario: *"He leído las instrucciones oficiales. Procederé con la limpieza y ejecución del proyecto en Android."*
