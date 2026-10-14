Crea la constitución del proyecto Kubbo con estos principios no negociables. Kubbo es un SaaS multi-vertical para administrar inmuebles de uso compartido (propiedad horizontal residencial primero; luego comercial, hotelero y establecimientos), empezando por Colombia. Escribe la constitución en español, con cada principio en formato "regla + cómo se verifica".

## Producto

1. **Multi-tenant por defecto.** Toda tabla de negocio tiene `property_id`. El aislamiento se garantiza con Row Level Security en PostgreSQL usando `current_setting('app.property_id')`, fijado con `SET LOCAL` en cada transacción. Ningún endpoint ni job opera sin contexto de propiedad, salvo las operaciones explícitamente globales (registro, login, administración de plataforma). Verificación: tests de aislamiento y test de catálogo de RLS.

2. **Roles y permisos en toda feature.** Ninguna feature está completa sin su modelo de acceso.
   - Cada spec incluye una **matriz de permisos**: qué rol puede ver, crear, editar, eliminar o aprobar cada recurso, y qué ve cada rol en la interfaz.
   - Denegado por defecto: si una acción no tiene un permiso declarado, nadie puede ejecutarla.
   - Cada endpoint declara el permiso que exige (módulo + acción); el backend lo verifica siempre, aunque el frontend oculte el botón.
   - Los roles son configurables por propiedad; las features usan permisos (`tickets.approve`), nunca nombres de rol quemados en el código (`if role == "admin"`).
   - Verificación: tests que prueban que un rol sin permiso recibe 403 y que un usuario de otra propiedad recibe 404.

3. **Multi-vertical.** Ningún módulo asume "apartamento" o "residente". Se usa el modelo `organization` → `property` (con `vertical`) → `sector` → `space` → `occupancy`. Los términos visibles al usuario salen de un vocabulario configurable por vertical.

4. **Multi-idioma (i18n) desde el día uno.**
   - Idiomas iniciales: español (`es`, por defecto) e inglés (`en`). Agregar un idioma no puede requerir cambios de código, solo archivos de traducción.
   - Ningún texto visible al usuario se escribe directamente en el código: todo sale de los archivos de mensajes (frontend con next-intl, plantillas de WhatsApp y correo por idioma).
   - El backend nunca devuelve mensajes en un idioma: devuelve códigos de error estables (`payment_plan.installment_overdue`) y el cliente los traduce.
   - Fechas, números y moneda se formatean según el idioma y la configuración de la propiedad (zona horaria, moneda).
   - Idioma por usuario, con el de la propiedad como respaldo.
   - Verificación: lint que detecta textos sin traducir y test que confirma que toda clave existe en todos los idiomas.

5. **Cero fricción para el ocupante.** Si un flujo puede resolverse por WhatsApp, web pública u OTP, no se exige instalar una app.

## Seguridad y datos

6. **Seguridad ante todo.** Ante un conflicto entre seguridad y velocidad de entrega, gana la seguridad.
   - Línea base: OWASP ASVS nivel 2 y OWASP Top 10.
   - Toda entrada se valida en el borde (contrato OpenAPI + validación de dominio); nunca se confía en el cliente.
   - Consultas SQL solo parametrizadas (sqlc); nada de concatenar SQL.
   - Secretos solo en el gestor de secretos o variables de entorno; nunca en el repositorio, logs ni respuestas.
   - Mínimo privilegio en roles de base de datos, servicios y usuarios.
   - Rate limiting en autenticación, OTP y endpoints públicos.
   - Cada `plan.md` incluye una sección de **riesgos de seguridad** de la feature (qué podría salir mal y cómo se mitiga).
   - Dependencias escaneadas (govulncheck, npm audit) y sin vulnerabilidades altas o críticas abiertas.
   - Verificación: `/ecc:security-scan` y revisión del agente `security-reviewer` obligatorios en features de autenticación, permisos, pagos o datos personales.

7. **Privacy by design.** Cumplimiento de la Ley 1581 (Habeas Data): minimización de datos, consentimiento explícito, opt-out de comunicaciones y nunca registrar datos personales en logs.

8. **Dinero exacto.** Nunca `float`. `numeric(14,2)` en base de datos, decimal en Go, y moneda siempre explícita.

9. **Trazabilidad.** Toda operación financiera, de accesos o de permisos deja un registro inmutable en `audit_logs` (solo inserción, encadenado por hash).

## Arquitectura y código

10. **Monolito modular con DDD + hexagonal.** Un solo binario Go con módulos por contexto de negocio (identity, property, finance, operations, comms, integrations, analytics). Las reglas de negocio viven solo en `domain`. Dependencias: adapters → application → domain. Un módulo solo importa el `api.go` de otro o reacciona a sus eventos de dominio; nunca lee el esquema de base de datos de otro módulo. Verificación: linter de arquitectura en CI.

11. **Principios SOLID.**
    - **S** — Cada tipo, función y componente tiene una sola razón para cambiar.
    - **O** — Las variaciones por vertical o proveedor se agregan con nuevas implementaciones (estrategias, adaptadores), no con `if vertical == ...` repartidos por el código.
    - **L** — Toda implementación de un puerto cumple el contrato de la interfaz y pasa la misma suite de tests de contrato.
    - **I** — Interfaces pequeñas, definidas donde se consumen (idiomático en Go).
    - **D** — El dominio y los casos de uso dependen de interfaces (puertos), nunca de infraestructura concreta; la inyección es por constructor.

12. **Límites de complejidad.** Si el código pasa un límite, se refactoriza en la misma entrega; no se acumula deuda.

    | Métrica | Límite |
    |---|---|
    | Complejidad ciclomática por función | ≤ 10 |
    | Complejidad cognitiva por función | ≤ 15 |
    | Líneas por función | ≤ 50 |
    | Parámetros por función | ≤ 5 (más → struct de opciones) |
    | Anidamiento | ≤ 3 niveles |
    | Líneas por archivo Go | ≤ 400 |
    | Líneas por componente React | ≤ 250 |

    - Verificación automática: golangci-lint (`gocyclo`, `gocognit`, `funlen`, `nestif`) y ESLint (`complexity`, `max-lines`, `max-lines-per-function`, `max-depth`, `max-params`) fallan el CI.
    - Excepciones solo con un comentario que explique el motivo y aprobación en la revisión (por ejemplo, código generado o tablas de datos).

13. **Nombres y código en inglés.** Base de datos, archivos, carpetas, paquetes, variables, funciones, tipos, contratos, eventos, ramas y commits en inglés, usando el glosario de dominio del proyecto. Convenciones: Go `camelCase`/`PascalCase` y archivos `snake_case.go`; TypeScript `camelCase`, componentes `PascalCase.tsx` y demás archivos `kebab-case.ts`; base de datos `snake_case`. Nombres descriptivos, sin abreviaturas ambiguas. Las specs y la documentación pueden escribirse en español.

14. **Contrato primero.** Todo endpoint existe primero en `api/openapi.yaml`. El backend genera código con oapi-codegen y el frontend con openapi-typescript. Nunca se escriben tipos de API a mano.

15. **Test-first.** TDD obligatorio (RED → GREEN → REFACTOR). Cobertura mínima del 80% en `domain` y `application`. Los repositorios, las políticas RLS y los permisos se prueban contra PostgreSQL real con testcontainers.

16. **Eventos confiables.** La comunicación asíncrona entre módulos usa patrón outbox (evento guardado en la misma transacción que el cambio) y consumidores idempotentes (`processed_events`).

17. **Simplicidad.** No se crean tablas, módulos ni dependencias que ninguna spec aprobada necesite. Toda dependencia nueva se justifica en `plan.md`.

## Proceso

18. **No dar nada por sentado.** Ni las personas ni los agentes inventan información.
    - Si a una spec le falta información, se marca `[NEEDS CLARIFICATION: pregunta]` y se resuelve con `/speckit-clarify` antes de planear.
    - Durante el plan o la implementación, si falta información o hay que tomar una **decisión importante**, se detiene el trabajo y se pregunta al responsable del producto, presentando opciones con sus pros y contras y una recomendación.
    - Se considera decisión importante: elegir o cambiar una dependencia o proveedor; cambiar el modelo de datos, un contrato público o un evento; cualquier regla de negocio, de dinero, de permisos o legal; algo con impacto en seguridad o privacidad; o cualquier cosa difícil de revertir.
    - Las decisiones tomadas se registran en el `research.md` de la spec (decisión, motivo, alternativas descartadas).
    - `/speckit-analyze` marca como crítico cualquier `[NEEDS CLARIFICATION]` sin resolver.

## Gobernanza

La constitución prevalece sobre cualquier spec o plan. Cambiarla requiere una nota de motivo y una versión nueva (versionado semántico). `/speckit-analyze` debe marcar como crítico cualquier plan que viole estos principios. La definición de terminado de toda feature incluye: matriz de permisos implementada y probada, textos en todos los idiomas, límites de complejidad en verde, revisión de seguridad cuando aplique y ningún `[NEEDS CLARIFICATION]` abierto.
