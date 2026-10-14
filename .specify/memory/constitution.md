<!--
Sync Impact Report
===================
Versión: N/A (plantilla sin rellenar) → 1.0.0
Tipo de cambio: Ratificación inicial (MAJOR, primera versión sustantiva).

Principios añadidos (18, agrupados en 5 secciones):
  Producto:
    I.    Multi-tenant por defecto
    II.   Roles y permisos en toda feature
    III.  Multi-vertical
    IV.   Multi-idioma (i18n) desde el día uno
    V.    Cero fricción para el ocupante
  Seguridad y Datos:
    VI.   Seguridad ante todo
    VII.  Privacy by design
    VIII. Dinero exacto
    IX.   Trazabilidad
  Arquitectura y Código:
    X.    Monolito modular con DDD + hexagonal
    XI.   Principios SOLID
    XII.  Límites de complejidad
    XIII. Nombres y código en inglés
    XIV.  Contrato primero
    XV.   Test-first
    XVI.  Eventos confiables
    XVII. Simplicidad
  Proceso:
    XVIII. No dar nada por sentado

Secciones añadidas: Producto, Seguridad y Datos, Arquitectura y Código, Proceso, Gobernanza
  (con definición de terminado ("Definition of Done") de toda feature).
Secciones eliminadas: ninguna (la plantilla no tenía contenido sustantivo previo).

Plantillas dependientes: no se modifican en este comando (alcance de /speckit-constitution
limitado a este archivo). Pendiente de revisión manual en una futura ejecución de esos
comandos para confirmar alineación con esta versión:
  - .specify/templates/plan-template.md (verificar sección de "riesgos de seguridad" y
    "Constitution Check" referencian los 18 principios).
  - .specify/templates/spec-template.md (verificar que exige matriz de permisos e i18n).
  - .specify/templates/tasks-template.md (verificar que las tareas de permisos, i18n y
    tests van incluidas por defecto).
  - README/CLAUDE.md del repo ya reflejan buena parte de estas reglas; no se tocan aquí.

TODOs / campos diferidos:
  - RATIFICATION_DATE: no existía una fecha de adopción previa documentada (el archivo
    anterior era la plantilla sin rellenar). Se usa la fecha de esta sesión (2026-10-13)
    como fecha de ratificación. Si existe una fecha real anterior de adopción del proyecto,
    actualizarla manualmente.
-->

# Constitución de Kubbo

Kubbo es un SaaS multi-vertical para administrar inmuebles de uso compartido (propiedad
horizontal residencial primero; luego comercial, hotelero y establecimientos), empezando
por Colombia. Esta constitución fija las reglas no negociables del producto, la seguridad,
la arquitectura y el proceso. Prevalece sobre cualquier spec, plan o tarea.

## Producto

### I. Multi-tenant por defecto

Toda tabla de negocio DEBE tener `property_id`. El aislamiento entre propiedades se
garantiza con Row Level Security (RLS) en PostgreSQL usando `current_setting('app.property_id')`,
fijado con `SET LOCAL` en cada transacción. Ningún endpoint ni job DEBE operar sin contexto
de propiedad, salvo las operaciones explícitamente globales (registro, login, administración
de plataforma), que deben estar declaradas como tales.

**Cómo se verifica:** tests de aislamiento (un usuario de la propiedad A nunca ve ni modifica
datos de la propiedad B) y un test de catálogo de RLS que falla si aparece una tabla de
negocio nueva sin política RLS forzada.

### II. Roles y permisos en toda feature

Ninguna feature está completa sin su modelo de acceso.

- Cada spec incluye una **matriz de permisos**: qué rol puede ver, crear, editar, eliminar
  o aprobar cada recurso, y qué ve cada rol en la interfaz.
- Denegado por defecto: si una acción no tiene un permiso declarado, nadie puede ejecutarla.
- Cada endpoint declara el permiso que exige (`módulo.acción`); el backend lo verifica
  siempre, aunque el frontend oculte el botón correspondiente.
- Los roles son configurables por propiedad; las features usan permisos (p. ej.
  `tickets.approve`), nunca nombres de rol quemados en el código (p. ej. `if role == "admin"`).

**Cómo se verifica:** tests que prueban que un rol sin el permiso declarado recibe `403`,
y que un usuario de otra propiedad recibe `404` al intentar acceder a un recurso ajeno.

### III. Multi-vertical

Ningún módulo asume "apartamento" o "residente". Se usa el modelo
`organization` → `property` (con `vertical`) → `sector` → `space` → `occupancy`. Los
términos visibles al usuario salen de un vocabulario configurable por vertical, nunca de
literales acoplados a un vertical específico en el dominio o la base de datos.

**Cómo se verifica:** revisión de código que rechaza nombres de entidad o de columna
específicos de un vertical (p. ej. `apartment_id`, `resident_id`) fuera de las tablas de
vocabulario, y pruebas de la misma feature ejecutadas con al menos dos verticales
distintos configurados.

### IV. Multi-idioma (i18n) desde el día uno

- Idiomas iniciales: español (`es`, por defecto) e inglés (`en`). Agregar un idioma NO
  puede requerir cambios de código, solo archivos de traducción.
- Ningún texto visible al usuario se escribe directamente en el código: todo sale de
  archivos de mensajes (frontend con next-intl, plantillas de WhatsApp y correo por idioma).
- El backend nunca devuelve mensajes en un idioma: devuelve códigos de error estables
  (p. ej. `payment_plan.installment_overdue`) y el cliente los traduce.
- Fechas, números y moneda se formatean según el idioma y la configuración de la propiedad
  (zona horaria, moneda).
- El idioma se resuelve por usuario, con el idioma de la propiedad como respaldo.

**Cómo se verifica:** lint que detecta literales de texto sin traducir en el código de
frontend y en las plantillas de comunicaciones, y un test que confirma que toda clave de
mensaje existe en todos los idiomas soportados.

### V. Cero fricción para el ocupante

Si un flujo puede resolverse por WhatsApp, web pública u OTP, no se exige instalar una app.

**Cómo se verifica:** revisión de producto en cada spec que toque un flujo de ocupante:
confirma que existe al menos una vía sin instalación (WhatsApp, web pública u OTP) antes de
aprobar el diseño.

## Seguridad y Datos

### VI. Seguridad ante todo

Ante un conflicto entre seguridad y velocidad de entrega, gana la seguridad.

- Línea base: OWASP ASVS nivel 2 y OWASP Top 10.
- Toda entrada se valida en el borde (contrato OpenAPI + validación de dominio); nunca se
  confía en el cliente.
- Consultas SQL solo parametrizadas (sqlc); nunca se concatena SQL.
- Secretos solo en el gestor de secretos o en variables de entorno; nunca en el repositorio,
  en logs ni en respuestas de la API.
- Mínimo privilegio en roles de base de datos, servicios y usuarios.
- Rate limiting en autenticación, OTP y endpoints públicos.
- Cada `plan.md` incluye una sección de **riesgos de seguridad** de la feature (qué podría
  salir mal y cómo se mitiga).
- Dependencias escaneadas (govulncheck, npm audit) sin vulnerabilidades altas o críticas
  abiertas.

**Cómo se verifica:** `/ecc:security-scan` y revisión del agente `security-reviewer` son
obligatorios en toda feature de autenticación, permisos, pagos o datos personales; el CI
falla si el escaneo de dependencias reporta una vulnerabilidad alta o crítica sin mitigar.

### VII. Privacy by design

Cumplimiento de la Ley 1581 de 2012 (Habeas Data): minimización de datos, consentimiento
explícito, opt-out de comunicaciones y nunca registrar datos personales en logs.

**Cómo se verifica:** revisión de seguridad que confirma, para cada dato personal nuevo,
su base de recolección y su mecanismo de opt-out; grep/lint en CI que bloquea el log de
campos marcados como datos personales (PII).

### VIII. Dinero exacto

Nunca se usa `float` para dinero. Se usa `numeric(14,2)` en base de datos, un tipo decimal
exacto en Go, y la moneda siempre se representa de forma explícita junto al monto.

**Cómo se verifica:** linter de base de datos/CI que rechaza columnas de tipo `float`/`double
precision` para montos, y revisión de código que rechaza tipos de punto flotante en
cálculos monetarios en Go.

### IX. Trazabilidad

Toda operación financiera, de accesos o de permisos deja un registro inmutable en
`audit_logs` (solo inserción, encadenado por hash).

**Cómo se verifica:** tests de integración que confirman que cada operación financiera, de
accesos o de permisos genera su registro en `audit_logs`, y que `audit_logs` no admite
`UPDATE` ni `DELETE` a nivel de base de datos.

## Arquitectura y Código

### X. Monolito modular con DDD + hexagonal

Un solo binario Go con módulos por contexto de negocio (identity, property, finance,
operations, comms, integrations, analytics). Las reglas de negocio viven solo en `domain`.
Dependencias: `adapters` → `application` → `domain`. Un módulo solo puede importar el
`api.go` de otro módulo o reaccionar a sus eventos de dominio; nunca lee el esquema de
base de datos de otro módulo.

**Cómo se verifica:** linter de arquitectura en CI que falla ante un import entre módulos
que no pase por `api.go`, o ante una consulta de un módulo contra el esquema de otro.

### XI. Principios SOLID

- **S** — Cada tipo, función y componente tiene una sola razón para cambiar.
- **O** — Las variaciones por vertical o proveedor se agregan con nuevas implementaciones
  (estrategias, adaptadores), no con `if vertical == ...` repartidos por el código.
- **L** — Toda implementación de un puerto cumple el contrato de la interfaz y pasa la
  misma suite de tests de contrato.
- **I** — Interfaces pequeñas, definidas donde se consumen (idiomático en Go).
- **D** — El dominio y los casos de uso dependen de interfaces (puertos), nunca de
  infraestructura concreta; la inyección es por constructor.

**Cómo se verifica:** revisión de código (`go-reviewer`/`typescript-reviewer`) que bloquea
condicionales por vertical o proveedor fuera de una implementación de estrategia, y suite
de tests de contrato compartida que toda implementación de un puerto debe pasar.

### XII. Límites de complejidad

Si el código pasa un límite, se refactoriza en la misma entrega; no se acumula deuda.

| Métrica | Límite |
|---|---|
| Complejidad ciclomática por función | ≤ 10 |
| Complejidad cognitiva por función | ≤ 15 |
| Líneas por función | ≤ 50 |
| Parámetros por función | ≤ 5 (más → struct de opciones) |
| Anidamiento | ≤ 3 niveles |
| Líneas por archivo Go | ≤ 400 |
| Líneas por componente React | ≤ 250 |

Excepciones solo con un comentario que explique el motivo y aprobación explícita en la
revisión (por ejemplo, código generado o tablas de datos).

**Cómo se verifica:** golangci-lint (`gocyclo`, `gocognit`, `funlen`, `nestif`) y ESLint
(`complexity`, `max-lines`, `max-lines-per-function`, `max-depth`, `max-params`) fallan el
CI si se supera un límite sin excepción documentada.

### XIII. Nombres y código en inglés

Base de datos, archivos, carpetas, paquetes, variables, funciones, tipos, contratos,
eventos, ramas y commits se escriben en inglés, usando el glosario de dominio del proyecto.
Convenciones: Go en `camelCase`/`PascalCase` con archivos `snake_case.go`; TypeScript en
`camelCase`, componentes `PascalCase.tsx` y demás archivos `kebab-case.ts`; base de datos en
`snake_case`. Nombres descriptivos, sin abreviaturas ambiguas. Las specs y la documentación
pueden escribirse en español.

**Cómo se verifica:** revisión de código y linter de nombres que rechaza identificadores,
tablas o ramas en español (fuera de specs/documentación) o que no sigan la convención de
casing de su lenguaje.

### XIV. Contrato primero

Todo endpoint existe primero en `api/openapi.yaml`. El backend genera código con
oapi-codegen y el frontend con openapi-typescript. Nunca se escriben tipos de API a mano.

**Cómo se verifica:** CI falla si existe un handler o un tipo de API en frontend que no
provenga del código generado a partir de `api/openapi.yaml`, y si el contrato no valida
contra OpenAPI 3.x.

### XV. Test-first

TDD obligatorio (RED → GREEN → REFACTOR). Cobertura mínima del 80% en `domain` y
`application`. Los repositorios, las políticas RLS y los permisos se prueban contra
PostgreSQL real con testcontainers.

**Cómo se verifica:** el pipeline de CI mide cobertura de `domain` y `application` y falla
por debajo del 80%; los tests de repositorios, RLS y permisos deben ejecutarse contra una
instancia real de PostgreSQL (testcontainers), no contra un mock.

### XVI. Eventos confiables

La comunicación asíncrona entre módulos usa el patrón outbox (el evento se guarda en la
misma transacción que el cambio de negocio) y consumidores idempotentes
(`processed_events`).

**Cómo se verifica:** tests de integración que confirman que un evento solo se publica si
su transacción de origen se confirmó, y que reprocesar el mismo evento no duplica efectos
(chequeo contra `processed_events`).

### XVII. Simplicidad

No se crean tablas, módulos ni dependencias que ninguna spec aprobada necesite. Toda
dependencia nueva se justifica en `plan.md`.

**Cómo se verifica:** `/speckit-analyze` y la revisión de `plan.md` marcan como hallazgo
cualquier tabla, módulo o dependencia sin una spec aprobada que la respalde.

## Proceso

### XVIII. No dar nada por sentado

Ni las personas ni los agentes inventan información.

- Si a una spec le falta información, se marca `[NEEDS CLARIFICATION: pregunta]` y se
  resuelve con `/speckit-clarify` antes de planear.
- Durante el plan o la implementación, si falta información o hay que tomar una
  **decisión importante**, se detiene el trabajo y se pregunta al responsable del
  producto, presentando opciones con sus pros y contras y una recomendación.
- Se considera decisión importante: elegir o cambiar una dependencia o proveedor; cambiar
  el modelo de datos, un contrato público o un evento; cualquier regla de negocio, de
  dinero, de permisos o legal; algo con impacto en seguridad o privacidad; o cualquier cosa
  difícil de revertir.
- Las decisiones tomadas se registran en el `research.md` de la spec (decisión, motivo,
  alternativas descartadas).

**Cómo se verifica:** `/speckit-analyze` marca como crítico cualquier `[NEEDS CLARIFICATION]`
sin resolver, y la revisión de `plan.md`/`research.md` rechaza una decisión importante que
no esté registrada con su motivo y alternativas descartadas.

## Gobernanza

La constitución prevalece sobre cualquier spec o plan. Cambiarla requiere una nota de
motivo y una versión nueva, siguiendo versionado semántico:

- **MAJOR**: eliminación o redefinición incompatible de un principio.
- **MINOR**: adición de un principio o una guía nueva, o expansión material de una existente.
- **PATCH**: aclaraciones, redacción, correcciones no semánticas.

`/speckit-analyze` DEBE marcar como crítico cualquier plan que viole alguno de estos
principios. La definición de terminado ("Definition of Done") de toda feature incluye:

- Matriz de permisos implementada y probada (403 por rol sin permiso, 404 entre propiedades).
- Textos disponibles en todos los idiomas soportados (`es`, `en`).
- Límites de complejidad en verde (sin excepciones sin justificar).
- Revisión de seguridad completada cuando la feature toca autenticación, permisos, pagos o
  datos personales.
- Ningún `[NEEDS CLARIFICATION]` abierto.

**Version**: 1.0.0 | **Ratified**: 2026-10-13 | **Last Amended**: 2026-10-13
