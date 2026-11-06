# Proyecto Final - Revistas, S.A.

Aplicación móvil desarrollada en Flutter para la gestión de entregas y suscripciones de la empresa "Revistas, S.A.". 

## 📦 Información de Entrega

El archivo ejecutable para Android (**APK**) actualizado y listo para instalar se encuentra en la carpeta `Entregable`:

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

## 🚀 Nuevas Funcionalidades: Módulo de Reportes & Exportación

En esta actualización se incorporó un módulo completo de reportes ejecutivos:

### 📄 1. Reporte General Consolidado
* **Reporte General en PDF:** Documento formal con diseño corporativo en azul institucional, tabla de indicadores KPI de operaciones (Total clientes, revistas, empleados, suscripciones, entregas realizadas, pendientes y atrasadas), detalle de suscripciones y bitácora completa de entregas con numeración de páginas.
* **Reporte General en Excel (.xlsx):** Libro de cálculo con múltiples hojas de trabajo independientes con formato de celdas y cabeceras:
  1. *Resumen Ejecutivo*
  2. *Clientes*
  3. *Revistas*
  4. *Empleados*
  5. *Suscripciones*
  6. *Entregas*

### 📊 2. Reportes Específicos (Menú Desplegable)
Permite seleccionar desde un menú desplegable cualquier módulo del sistema para exportar sus datos dedicados tanto en **PDF** como en **Excel (.xlsx)**:
* 👥 **Clientes:** Listado con NIT, nombres completos, direcciones de entrega y teléfonos.
* 📖 **Revistas:** Catálogo de publicaciones y títulos registrados.
* 🪪 **Empleados:** Plantilla de personal repartidor y mensajeros.
* 📑 **Suscripciones:** Detalle de suscripciones con cliente, revista y fechas de vigencia.
* 🚚 **Entregas:** Bitácora clasificada por estado (Realizada, Pendiente, Atrasada) con empleado asignado y observaciones.

### 🔄 3. Datos de Prueba Ampliados y Herramienta de Demostración
* Base de datos SQLite enriquecida para pruebas completas y académicas:
  * **8 Clientes** en diversas zonas y departamentos de Guatemala.
  * **7 Revistas** temáticas (Negocios, Tecnología, Salud, Cocina, Ciencia, Viajes, Deportes).
  * **5 Empleados repartidores**.
  * **14 Suscripciones activas** con reglas de negocio íntegras.
  * **20 Entregas** con estados reales (8 realizadas, 6 pendientes y 6 atrasadas).
* **Botón de Restablecimiento In-App:** En la pantalla de Reportes se incluye la opción *"Cargar Datos de Demostración"* para repoblar la base de datos local en cualquier momento con un solo toque.

---

## 🛠️ Arquitectura y Tecnologías

La aplicación fue desarrollada utilizando **Clean Architecture** (Arquitectura Limpia) con el patrón Repository y persistencia de datos local a través de **SQLite**:

* **Framework:** Flutter SDK (Material 3)
* **Lenguaje:** Dart
* **Base de Datos:** SQLite (`sqflite`) con claves foráneas activas (`PRAGMA foreign_keys = ON`)
* **Generación de PDF:** `pdf` y `printing` (permite visualización interactiva, impresión y guardado nativo)
* **Generación de Excel:** `excel` (creación de libros `.xlsx` con hojas y estilos)
* **Compartición y Apertura:** `share_plus` y `open_filex`
* **Control de Versiones:** Git / GitHub

---
*Desarrollado para la evaluación académica del caso de negocio "Revistas, S.A."*
