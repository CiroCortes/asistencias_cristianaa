# Plan de acción – Semanas y registro de asistencias

**Fecha:** 8 de febrero de 2026  
**Estado:** En pausa — a la espera de decisión del cliente. La app **sí está funcionando** (registro de asistencias operativo).

---

## 1. Resumen del problema

### 1.1 Síntomas reportados por el cliente
- Las semanas se ven “corridas” en reportes: por ejemplo, se esperaba que **23 de febrero de 2026** correspondiera a la **semana 9** (rango 23 feb – 1 mar).
- **Aclarado con el cliente:** No usan norma ISO; usan **semana natural**. Por eso la numeración no coincide con lo que esperaban. La decisión de qué criterio adoptar (semana natural, ISO u otro) queda en manos del cliente; se retomará cuando lo indiquen.

### 1.2 Causas identificadas en código

**Cálculo de semana actual (incorrecto para el criterio deseado):**
- Hoy la semana se calcula como **bloques de 7 días desde el 1 de enero** (sin considerar lunes–domingo).
- Con esa lógica, el 23 de febrero sale como **semana 8**, no 9.
- Los comentarios en código dicen "cada semana empieza el lunes" pero la implementación no lo respeta.

**Cálculo duplicado en varios lugares:**
- No hay un único “modelo” o utilidad de semanas: **cada pantalla/servicio tiene su propio calculador**.
- Ubicaciones:
  - **Central (única que debería usarse):** `lib/core/utils/date_utils.dart` → `getWeekNumber(date)`.
  - **Copias a eliminar:**
    - `lib/presentation/screens/admin_dashboard/ttl_weekly_report_screen.dart` → `_getWeekNumber`.
    - `lib/presentation/screens/admin_dashboard/quarterly_ttl_report_screen.dart` → `_getWeekNumber`.
    - `lib/core/services/admin_utilities_service.dart` → `_getWeekNumber`.

### 1.3 Otros puntos revisados
- **Firebase/Google Cloud:** El bloqueo por 2 pasos (2SV) en la consola **no** afecta a que la app registre asistencias; solo impide entrar a la consola desde el navegador. Las credenciales del proyecto (Android: `asistenciasappcristiana-9385b`) están configuradas.
- **Registro de asistencias (comprobado con el cliente):** La app sí está funcionando; el desajuste era por el criterio de semana (semana natural, no ISO). Pendiente probar con cuenta admin cuando sea posible.
---

## 2. Tareas del plan

### 2.1 Pendiente: modelo de semana en un solo lugar (sin repetir código)
- **Objetivo:** Un único cálculo de semana en todo el proyecto, tipo “modelo”/utilidad central.
- **Acción:** Mantener **solo** `lib/core/utils/date_utils.dart` como fuente de verdad.
- **Implementación:** Cambiar `getWeekNumber(date)` en `date_utils.dart` a **semanas ISO 8601** (lunes–domingo; semana 1 = semana que contiene el 4 de enero), para que el 23 de febrero sea semana 9.
- **Limpieza:** En las 3 ubicaciones anteriores, eliminar `_getWeekNumber` y usar siempre `getWeekNumber` importado desde `package:asistencias_app/core/utils/date_utils.dart`.

### 2.2 No tocar el modelo de datos para "year"
- El campo `year` del modelo de asistencia se mantiene como **año natural** (`date.year`).
- Solo se cambiará la **forma de calcular** `weekNumber` según lo que decida el cliente; no se agrega año ISO ni migración de datos.

### 2.3 Cuando se retome: verificación post-implementación
- Ejecutar la app en emulador.
- Comprobar en reportes que la semana mostrada coincida con el criterio acordado (ej. 23 feb = semana 9 si adoptan ISO).
- Revisar reportes por semana (totales por sectores, TTL semanal, trimestral) y que no haya errores.

### 2.4 Opcionales (cuando haga falta)
- Revisar reglas de Firestore si aparecen problemas de registro.
- Activar 2SV en la cuenta Google para poder usar la consola cuando sea necesario.

---

## 3. Impacto en Firestore y datos antiguos

### 3.1 ¿Cambia lo que está guardado en Firestore?
- **No hace falta migrar documentos.** Cada documento sigue teniendo `date`, `weekNumber`, `year`, etc.
- Al **leer** un registro, el modelo **no usa** el `weekNumber` guardado: lo **recalcula** desde `date` en el constructor (`getWeekNumber(date)`). Por tanto, en cuanto se implemente el nuevo cálculo, **todos** los registros (nuevos y antiguos) se mostrarán con el número de semana ISO al cargarlos en la app.
- Al **escribir** un registro nuevo, se guardará el `weekNumber` calculado con la nueva lógica (ISO).

### 3.2 ¿Hay problema con fechas antiguas (ej. desde agosto)?
- **No hay inconsistencia ni corrupción de datos.** Las fechas (`date`) no se tocan; solo cambia la **regla de cálculo** del número de semana.
- **Efecto visible:** Los reportes y filtros por semana mostrarán **números de semana distintos** para las mismas fechas que antes. Por ejemplo, una fecha de agosto que antes aparecía como “semana 35” podría pasar a “semana 34” o “semana 36” según la definición ISO. Los datos de asistencia (quién asistió, cuántos, etc.) **no cambian**; solo el **número de semana** mostrado/agrupado.
- **Recomendación:** Comunicar al cliente que, a partir de la implementación, las semanas pasan a ser “semanas tipo calendario” (lunes–domingo, estándar) y que los reportes históricos verán ese cambio de numeración para fechas pasadas (incluido desde agosto). No requiere ninguna acción en la base de datos.

---

## 4. Resumen ejecutivo

| Qué | Acción |
|-----|--------|
| **Estado actual** | App funcionando. Cliente usa **semana natural** (no ISO); por eso la semana sale "corrida". Decisión en pausa hasta que el cliente indique. |
| **Pendiente** | **Modelo de semana en un solo lugar:** unificar en `date_utils.dart` y **no repetir código** (eliminar `_getWeekNumber` en las 3 pantallas/servicio). Cuando el cliente decida el criterio (semana natural, ISO u otro), implementarlo solo ahí. |
| **Firestore** | No migrar. Al leer se recalcula semana desde `date`; datos no se tocan. |
