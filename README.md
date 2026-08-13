# Proyecto Final - Revistas, S.A.

Aplicación móvil desarrollada en Flutter para la gestión de entregas y suscripciones de la empresa "Revistas, S.A.". 

## 📦 Información de Entrega

El archivo ejecutable para Android (**APK**) necesario para instalar y evaluar la aplicación se encuentra en la carpeta `Entregable`:

👉 **[Descargar APK (app-release.apk)](Entregable/app-release.apk)**

---

## 📱 Instrucciones de Instalación en Android

Para instalar la aplicación en un dispositivo Android físico, sigue estos pasos:

1. **Descarga el archivo APK** desde la carpeta `Entregable` de este repositorio a tu teléfono.
2. **Abre el archivo** desde el explorador de archivos o la carpeta de "Descargas" de tu teléfono.
3. Si es la primera vez que instalas una app fuera de la Google Play Store, Android te pedirá permisos para **"Instalar aplicaciones desconocidas"**. 
4. Otorga el permiso a tu navegador o administrador de archivos y toca **Instalar**.
5. ¡Listo! Busca la app **"Revistas S.A."** en tu cajón de aplicaciones.

---

## 🛠️ Características Implementadas

La aplicación fue desarrollada utilizando **Clean Architecture** (Arquitectura Limpia) con el patrón Repository y persistencia de datos local a través de **SQLite**.

### 1. Base de Datos (SQLite)
* Tablas implementadas con todas las restricciones de integridad y **Foreign Keys (PRAGMA foreign_keys = ON)**:
  * `clientes`
  * `revistas`
  * `empleados`
  * `suscripciones`
  * `entregas`
* Inserción automática de **datos de demostración** al crear la base de datos por primera vez.
* Manejo robusto de excepciones para evitar eliminar o modificar registros que están siendo referenciados (ej. no se puede eliminar un cliente si ya tiene suscripciones).

### 2. Módulos y Flujos (CRUD Completo)
* **Dashboard:** Tarjetas informativas con contadores en tiempo real sobre los registros en la base de datos.
* **Clientes:** Registro, actualización, eliminación y búsqueda (por nombre o NIT).
* **Revistas:** Gestión del catálogo de revistas y frecuencias.
* **Empleados:** Gestión del personal encargado de las entregas.
* **Suscripciones:** Relación entre Cliente y Revista con fechas de inicio y fin (usando selectores de fecha nativos).
* **Entregas (Módulo Núcleo):**
  * Vista dividida en 3 pestañas: **Pendientes**, **Atrasadas** (fecha programada vencida) y **Realizadas**.
  * Restricción: No se puede crear una entrega si no existe una suscripción y un empleado asignado.
  * **Flujo "Marcar Entregada":** Las entregas pendientes pueden deslizarse (Swipe) o tocarse para confirmarlas y pasarlas al estado de "Realizadas", guardando la fecha exacta en la que se entregaron.

### 3. Interfaz de Usuario (UI)
* Diseño corporativo y profesional basado en **Material Design 3** con una paleta de colores azul institucional.
* Manejo centralizado de formularios mediante diálogos reutilizables para mantener la consistencia en todas las pantallas.
* Validaciones en tiempo real para evitar campos obligatorios vacíos.

---

## 👨‍💻 Tecnologías Utilizadas

* **Framework:** Flutter SDK
* **Lenguaje:** Dart
* **Base de Datos:** SQLite (paquete `sqflite`)
* **Arquitectura:** Patrón Repositorio
* **Control de Versiones:** Git / GitHub

---
*Desarrollado para la evaluación final académica del caso práctico "Revistas, S.A."*
