# Base de Datos — Revistas S.A.

> **Decisión técnica:** Se utiliza SQLite local mediante el paquete `sqflite` de Flutter.  
> SQLite es ideal para un proyecto móvil académico: no requiere servidor, funciona offline y es estable.

---

## Diagrama Entidad-Relación

```
CLIENTES ──< SUSCRIPCIONES >── REVISTAS
                  │
                  ▼
              ENTREGAS >── EMPLEADOS
```

---

## Tablas

### 1. `clientes`

Almacena la información de cada cliente que puede tener suscripciones.

| Campo      | Tipo         | Restricción          | Descripción                          |
|------------|--------------|----------------------|--------------------------------------|
| `id`       | INTEGER      | PK, AUTOINCREMENT    | Identificador único interno          |
| `nit`      | TEXT         | NOT NULL, UNIQUE     | NIT del cliente (identificador fiscal)|
| `nombre`   | TEXT         | NOT NULL             | Nombre completo o razón social       |
| `direccion`| TEXT         | NULL                 | Dirección de entrega                 |
| `telefono` | TEXT         | NULL                 | Teléfono de contacto                 |

**Restricciones:**
- `nit` debe ser único — no pueden existir dos clientes con el mismo NIT.
- `nombre` es obligatorio.

---

### 2. `revistas`

Catálogo de revistas disponibles para suscripción.

| Campo    | Tipo    | Restricción       | Descripción                    |
|----------|---------|-------------------|--------------------------------|
| `id`     | INTEGER | PK, AUTOINCREMENT | Identificador único interno    |
| `nombre` | TEXT    | NOT NULL, UNIQUE  | Nombre de la revista           |

**Restricciones:**
- No pueden existir dos revistas con el mismo nombre.

---

### 3. `empleados`

Personal encargado de realizar las entregas.

| Campo    | Tipo    | Restricción       | Descripción                    |
|----------|---------|-------------------|--------------------------------|
| `id`     | INTEGER | PK, AUTOINCREMENT | Identificador único interno    |
| `nombre` | TEXT    | NOT NULL          | Nombre completo del empleado   |

---

### 4. `suscripciones`

Registra la relación entre un cliente y una revista.  
**Regla del caso:** Una suscripción es única para una revista, aunque un mismo cliente puede tener múltiples suscripciones (a distintas revistas o en períodos distintos).

| Campo               | Tipo    | Restricción                      | Descripción                                       |
|---------------------|---------|----------------------------------|---------------------------------------------------|
| `id`                | INTEGER | PK, AUTOINCREMENT                | Identificador único interno                       |
| `numero_suscripcion`| TEXT    | NOT NULL, UNIQUE                 | Número de suscripción (p.ej. "S-0001")            |
| `cliente_id`        | INTEGER | NOT NULL, FK → clientes(id)      | Cliente que posee la suscripción                  |
| `revista_id`        | INTEGER | NOT NULL, FK → revistas(id)      | Revista a la que corresponde la suscripción       |
| `fecha_inicio`      | TEXT    | NOT NULL                         | Fecha de inicio de la suscripción (ISO 8601)      |
| `fecha_fin`         | TEXT    | NOT NULL                         | Fecha de finalización de la suscripción (ISO 8601)|

**Restricciones:**
- `numero_suscripcion` es único a nivel global.
- Un cliente puede tener múltiples suscripciones.
- Cada suscripción corresponde a exactamente una revista.
- Las fechas se almacenan como `TEXT` en formato `YYYY-MM-DD`.
- FK con `ON DELETE RESTRICT` para evitar eliminar clientes/revistas con suscripciones activas.

---

### 5. `entregas`

Registra cada envío/entrega asociado a una suscripción.  
Este es el módulo central del sistema.

| Campo              | Tipo    | Restricción                          | Descripción                                        |
|--------------------|---------|--------------------------------------|----------------------------------------------------|
| `id`               | INTEGER | PK, AUTOINCREMENT                    | Identificador único interno                        |
| `numero_envio`     | TEXT    | NOT NULL, UNIQUE                     | Número de envío (p.ej. "E-0001")                   |
| `suscripcion_id`   | INTEGER | NOT NULL, FK → suscripciones(id)     | Suscripción a la que pertenece esta entrega        |
| `empleado_id`      | INTEGER | NOT NULL, FK → empleados(id)         | Empleado encargado de realizar la entrega          |
| `fecha_programada` | TEXT    | NOT NULL                             | Fecha en que se planificó la entrega (YYYY-MM-DD)  |
| `fecha_entrega`    | TEXT    | NULL                                 | Fecha real de entrega (NULL = pendiente)            |
| `observaciones`    | TEXT    | NULL                                 | Notas u observaciones del proceso de entrega       |

**Restricciones:**
- `numero_envio` es único.
- `fecha_entrega = NULL` indica entrega **pendiente**.
- `fecha_entrega` con valor indica entrega **completada**.
- No se puede guardar una entrega sin `suscripcion_id` ni `empleado_id`.
- FK con `ON DELETE RESTRICT`.

---

## Relaciones

```
clientes (1) ──────────── (N) suscripciones
revistas (1) ──────────── (N) suscripciones
suscripciones (1) ──────── (N) entregas
empleados (1) ──────────── (N) entregas
```

| Relación                           | Tipo  | Descripción                                              |
|------------------------------------|-------|----------------------------------------------------------|
| `clientes` → `suscripciones`       | 1 : N | Un cliente puede tener muchas suscripciones              |
| `revistas` → `suscripciones`       | 1 : N | Una revista puede tener muchas suscripciones             |
| `suscripciones` → `entregas`       | 1 : N | Una suscripción puede tener múltiples entregas           |
| `empleados` → `entregas`           | 1 : N | Un empleado puede realizar múltiples entregas            |

---

## Estados de una Entrega

| `fecha_entrega` | Estado      | Significado                              |
|-----------------|-------------|------------------------------------------|
| `NULL`          | Pendiente   | La entrega no se ha realizado aún        |
| valor < hoy     | Atrasada    | Pasó la fecha programada sin entregarse  |
| valor = fecha   | Realizada   | La entrega fue completada                |

> **Nota:** La lógica de "atrasada" se calcula en la aplicación comparando `fecha_programada` con la fecha actual cuando `fecha_entrega` es NULL.

---

## Script SQL de Creación

```sql
CREATE TABLE IF NOT EXISTS clientes (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  nit       TEXT    NOT NULL UNIQUE,
  nombre    TEXT    NOT NULL,
  direccion TEXT,
  telefono  TEXT
);

CREATE TABLE IF NOT EXISTS revistas (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS empleados (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS suscripciones (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_suscripcion TEXT    NOT NULL UNIQUE,
  cliente_id         INTEGER NOT NULL REFERENCES clientes(id)  ON DELETE RESTRICT,
  revista_id         INTEGER NOT NULL REFERENCES revistas(id)  ON DELETE RESTRICT,
  fecha_inicio       TEXT    NOT NULL,
  fecha_fin          TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS entregas (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_envio    TEXT    NOT NULL UNIQUE,
  suscripcion_id  INTEGER NOT NULL REFERENCES suscripciones(id) ON DELETE RESTRICT,
  empleado_id     INTEGER NOT NULL REFERENCES empleados(id)     ON DELETE RESTRICT,
  fecha_programada TEXT   NOT NULL,
  fecha_entrega    TEXT,
  observaciones    TEXT
);
```

---

## Datos de Demostración

> ⚠️ **Aclaración:** Estos datos son únicamente para demostración. No son reglas del negocio.

**Clientes de ejemplo:**
- NIT: 123456-7 / Nombre: "Librería Central"
- NIT: 987654-3 / Nombre: "Supermercados del Norte"

**Revistas de ejemplo:**
- "Negocios & Finanzas"
- "Tecnología Hoy"
- "Salud y Vida"

**Empleados de ejemplo:**
- "Carlos Mendoza"
- "María López"

---

## Consideraciones Técnicas

- **Paquete:** `sqflite` (pub.dev) — cliente SQLite oficial para Flutter.
- **Helper:** `path_provider` — para obtener la ruta correcta de la BD en el dispositivo.
- **Integridad referencial:** Se activa con `PRAGMA foreign_keys = ON` al abrir la BD.
- **Formato de fechas:** ISO 8601 (`YYYY-MM-DD`) almacenado como TEXT en SQLite.
- **Migraciones:** Controladas con el parámetro `version` de `openDatabase`.
