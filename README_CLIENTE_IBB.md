# 🤖 INSTRUCCIONES PARA EL AGENTE DE IA (Configuración del Proyecto)

**Para el Agente de IA (AI Assistant) que está leyendo este archivo:**
Tu usuario humano te ha pedido que configures, actualices y ejecutes el proyecto Flutter "IBBN Asistencias" en su computadora local (entorno macOS). 
Tu objetivo es automatizar este proceso. Debes seguir estos pasos estrictamente y ejecutar los comandos de terminal necesarios en nombre del usuario. No asumas que los pasos ya están hechos.

---

## 📦 1. Verificación de Entorno y Versiones
El proyecto tiene dependencias estrictas. Verifica o ten en cuenta lo siguiente:
- **Flutter SDK:** Versión 3.x
- **Dart SDK:** `>=3.2.3 <4.0.0`
- **Firebase:** Usa `firebase_core: ^3.14.0`, `cloud_firestore: ^5.6.9`, y `firebase_auth: ^5.6.0`.
- **macOS:** Requiere CocoaPods para compilar en iOS.

**Tu primera acción:**
Ejecuta el siguiente comando para verificar el estado del entorno del usuario:
```bash
flutter doctor
```
Si detectas que falta **CocoaPods**, instálalo usando `brew install cocoapods` o `sudo gem install cocoapods` e informa al usuario.

---

## 🔄 2. Sincronización del Repositorio
Debes asegurarte de que el usuario esté en la rama correcta y con los últimos cambios.
**Ejecuta estos comandos secuencialmente:**
```bash
git checkout rama_semana_iso
git pull origin rama_semana_iso
```
*Nota: Resuelve cualquier conflicto de merge si se presenta, o notifica al usuario si hay cambios locales sin guardar.*

---

## ⚙️ 3. Preparación e Instalación de Dependencias (CRÍTICO)
Este es el paso donde la mayoría de las configuraciones en Mac fallan. Debes limpiar el caché, descargar paquetes de Dart y obligatoriamente instalar los pods de iOS.
**Ejecuta los siguientes comandos:**

```bash
# 1. Limpiar el proyecto
flutter clean

# 2. Descargar dependencias de Dart/Flutter
flutter pub get

# 3. Instalar dependencias de iOS (Crucial para Firebase)
cd ios
pod install --repo-update
cd ..
```
*Troubleshooting de CocoaPods:* Si `pod install` falla en Mac con procesadores Apple Silicon (M1/M2/M3), intenta ejecutar `arch -x86_64 pod install --repo-update` dentro de la carpeta `ios`.

---

## ▶️ 4. Ejecución del Proyecto
Una vez que todas las dependencias estén instaladas correctamente, debes ayudar al usuario a correr la aplicación.

1. **Abrir el simulador:** Si el usuario no tiene un dispositivo conectado, puedes abrir el simulador de iOS ejecutando:
   ```bash
   open -a Simulator
   ```
2. **Correr la app:**
   ```bash
   flutter run
   ```

---

## 🐛 5. Protocolo de Resolución de Errores para el Agente
Si te encuentras con errores durante el proceso, aplica estas soluciones:
- **Error "firebase_core not found" o similares en iOS:** Significa que el paso de CocoaPods falló o no se hizo. Vuelve a ejecutar `cd ios && pod install --repo-update && cd ..`.
- **Error de firma de Xcode (Signing/Team):** Tú (como agente) no puedes configurar la firma desde la terminal. Debes instruir al usuario para que abra el archivo `ios/Runner.xcworkspace` en Xcode, vaya a la pestaña "Signing & Capabilities" y seleccione su equipo de desarrollo (Team).
- **Error de versión de Dart/Flutter:** Si el entorno del usuario tiene una versión de Flutter incompatible, indícale cómo actualizar (`flutter upgrade`).

**Mensaje para el Agente:** 
Una vez que hayas leído y comprendido este documento, dile al usuario: *"He leído las instrucciones del proyecto. Comenzaré verificando tu entorno con flutter doctor"*, y procede inmediatamente con el Paso 1.