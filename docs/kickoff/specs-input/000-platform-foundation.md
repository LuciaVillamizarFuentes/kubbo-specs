# Spec 000 — Platform foundation (cimientos de plataforma y base de datos)

Esta es la única spec "técnica" del proyecto: no entrega funcionalidad al usuario final, pero deja listo todo lo que las demás specs necesitan. Síguela en orden.

---

## Paso 1 · `/speckit-specify`
Pega esto:

```
/speckit-specify Cimientos de la plataforma Kubbo (000-platform-foundation).

Como equipo de desarrollo necesitamos una base técnica sobre la que construir todas las features, que garantice desde el día uno el aislamiento de datos entre propiedades (multi-tenant), la trazabilidad y la confiabilidad de los eventos entre módulos.

Historias:
1. Como desarrollador, puedo levantar todo el entorno local (base de datos, cache, API) con un solo comando y ver que la API responde que está sana.
2. Como desarrollador, puedo crear y revertir migraciones de base de datos por módulo, y la aplicación aplica las pendientes al arrancar con un comando explícito.
3. Como plataforma, garantizo que una consulta hecha en el contexto de una propiedad nunca puede leer ni escribir datos de otra propiedad, aunque el código tenga un error en el filtro.
4. Como plataforma, si una operación de negocio no tiene contexto de propiedad, no ve ningún dato de tenant (falla cerrado).
5. Como plataforma, registro organizaciones y propiedades (la raíz de los tenants) con su vertical, zona horaria y moneda.
6. Como plataforma, cualquier cambio sensible puede dejar un registro de auditoría inmutable y encadenado.
7. Como módulo, puedo publicar un evento de dominio en la misma transacción que mi cambio, y los consumidores lo procesan una sola vez aunque se entregue varias veces.

Criterios de aceptación clave:
- Un test automatizado demuestra que con la propiedad A activa no se puede leer, actualizar ni insertar datos de la propiedad B.
- Sin propiedad activa, las tablas de tenant devuelven cero filas.
- La aplicación se conecta con un rol de base de datos que no puede saltarse RLS.
- Toda tabla con property_id tiene RLS habilitado y forzado; un test lo verifica recorriendo el catálogo.
- Los registros de auditoría no se pueden modificar ni borrar con el rol de la aplicación.
- Un evento publicado y entregado dos veces se procesa una sola vez.

Fuera de alcance: usuarios, login, roles (spec 001 y 002), espacios y ocupaciones (spec 003), frontend.
```

## Paso 2 · `/speckit-clarify`
Si te pregunta, estas son las respuestas recomendadas:
- **¿Organizations y properties tienen RLS?** No. Son el registro de tenants: se protegen en la capa de aplicación. Todo lo demás con `property_id` sí tiene RLS.
- **¿Tablas sin `property_id` que son por usuario (ej. membresías)?** Quedan fuera de RLS y deben estar en una lista explícita (allowlist) que el test de catálogo valida.
- **¿Un rol de BD por módulo?** En el MVP, un único rol de runtime (`kubbo_app`). Las fronteras entre módulos se garantizan con el linter de arquitectura y la convención de esquemas. Roles por módulo cuando se extraiga un módulo.
- **¿Dónde vive la auditoría?** En `platform.audit_logs`, escrita en la misma transacción que el cambio (más fuerte que hacerlo por evento).
- **¿Jobs que recorren varias propiedades (ej. facturación mensual)?** El job lista propiedades y abre una transacción por propiedad con su `SET LOCAL`. Nunca se desactiva RLS.

## Paso 3 · `/speckit-plan`
Pega esto:

```
/speckit-plan Usa el stack de la constitución y los CLAUDE.md de kubbo-specs y kubbo-api. Marca cada tarea con su repo destino ([specs], [api] o [web]). Decisiones técnicas para esta spec:

Repositorios:
- kubbo-specs: crear el esqueleto de api/openapi.yaml (OpenAPI 3.1 con /healthz y /readyz, esquema Problem Details RFC 9457 y la extensión x-permission documentada) y etiquetarlo contract-v0.1.0.
- kubbo-api: todo el backend y la base de datos de esta spec; make generate lee ../kubbo-specs/api/openapi.yaml y .contract-version queda en contract-v0.1.0.
- kubbo-web: sin cambios en esta spec.

Entorno local:
- kubbo-api/deploy/docker-compose.yml con PostgreSQL 18 y Redis; la API Go corre local con recarga (air) o en contenedor.
- Makefile con: up, down, migrate-up, migrate-down, migrate-new MODULE=x NAME=y, sqlc, test, lint, seed.

Backend (repo kubbo-api, código en su raíz):
- cmd/kubbo con subcomandos api | worker | scheduler | migrate (cobra o flag simple).
- internal/platform: config (env), db (pool pgx, helper WithTenantTx que abre transacción y ejecuta SET LOCAL app.property_id), httpx (chi, request_id, recover, logging, /healthz y /readyz), tenancy (PropertyID en context), outbox, audit, logger (slog JSON), otel.
- internal/shared/kernel: tipos PropertyID, OrganizationID, Money, errores de dominio base.
- internal/modules/property con su estructura hexagonal y solo organizations + properties.

Base de datos:
- Esquemas: platform, identity, property, finance, operations, comms, integrations, analytics.
- Roles: kubbo_owner (dueño de objetos, corre migraciones) y kubbo_app (runtime, LOGIN, NOBYPASSRLS, sin ser dueño de tablas).
- Migraciones goose en db/migrations/<schema>/, aplicadas en orden: platform primero.
- PK uuid DEFAULT uuidv7() (nativo en PostgreSQL 18).
- Función platform.current_property_id() que lee current_setting('app.property_id', true) y devuelve NULL si no existe.
- Política estándar por tabla de tenant: ENABLE + FORCE ROW LEVEL SECURITY y política tenant_isolation con USING y WITH CHECK (property_id = platform.current_property_id()).
- Tablas de esta spec:
  - property.organizations (id, name, tax_id, subscription_plan, created_at, updated_at)
  - property.properties (id, organization_id FK, vertical enum, name, slug unique, address, city, tax_id, timezone, currency char(3), vocabulary jsonb, status, created_at, updated_at)
  - property.outbox_events (id, event_type, payload jsonb, property_id, created_at, published_at) + índice parcial sobre no publicados
  - platform.processed_events (event_id, consumer, processed_at, PK compuesta)
  - platform.audit_logs (id bigint identity, property_id, actor_user_id, entity, entity_id, action, before jsonb, after jsonb, prev_hash, hash, created_at); kubbo_app solo tiene INSERT y SELECT; un trigger calcula el hash encadenado.
- Enums de Postgres en inglés: property_vertical (residential, commercial, hospitality, establishment), property_status (active, suspended).
- Seed de desarrollo: 1 organización y 2 propiedades residenciales.

Pruebas (testcontainers-go con PostgreSQL 18):
- Aislamiento: con propiedad A activa, SELECT/UPDATE/INSERT sobre datos de B fallan o devuelven cero filas.
- Fail-closed: sin SET LOCAL, cero filas.
- Catálogo: toda tabla con columna property_id (fuera de la allowlist) tiene relrowsecurity y relforcerowsecurity en true.
- Rol: kubbo_app no tiene BYPASSRLS ni es dueño de tablas.
- Auditoría: UPDATE/DELETE en audit_logs con kubbo_app fallan; la cadena de hash se verifica.
- Outbox/idempotencia: un mismo event_id procesado dos veces por el mismo consumer solo ejecuta el handler una vez.

Calidad: golangci-lint con reglas de dependencias (depguard o go-arch-lint) para que domain no importe infraestructura y ningún módulo importe internal de otro, y con los límites de complejidad de la constitución (gocyclo 10, gocognit 15, funlen 50 líneas, nestif 3). Dejar también la base de permisos: un paquete platform/authz con el middleware RequirePermission("module.action") y denegado por defecto (los roles reales llegan en la spec 002), y el paquete platform/i18n con el formato de códigos de error.
```

## Paso 4 · `/speckit-tasks`
Sin texto extra. Revisa que el orden sea: entorno → esquemas y roles → función de tenancy → tablas → tests de RLS → plataforma Go → health checks → outbox/auditoría → lint.

## Paso 5 · `/speckit-analyze`
Debe salir sin hallazgos críticos. Si marca algo contra la constitución, corrige el plan antes de implementar.

## Implementación con ECC
- Por cada tarea: `/ecc:go-test` (primero el test que falla). Para las migraciones, el "test" es el test de aislamiento o de catálogo.
- El agente `database-reviewer` revisa cada migración.
- Al terminar: `/ecc:code-review`, `/ecc:security-scan` (esta spec es de seguridad pura) y `/ecc:save-session`.

## Definición de terminado
- [ ] `make up && make migrate-up && make seed` funciona en una máquina limpia
- [ ] `/healthz` y `/readyz` responden
- [ ] Tests de aislamiento, fail-closed, catálogo, rol y auditoría en verde
- [ ] `make lint` en verde con reglas de arquitectura
- [ ] `make migrate-down` revierte todo sin errores
