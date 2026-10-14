Enmienda la constitución (versión 1.0.0 → 1.1.0, cambio MINOR). No cambies ningún otro principio. Actualiza el Sync Impact Report con estos cambios.

## 1. Nueva sección en Gobernanza: "Repositorios"
- `kubbo-specs`: constitución, specs de Spec Kit y contrato `api/openapi.yaml`. Es el punto de entrada de todo trabajo.
- `kubbo-api`: backend Go, migraciones y entorno local.
- `kubbo-web`: frontend Next.js.
- Cada tarea de `tasks.md` indica su repo destino: `[specs]`, `[api]` o `[web]`.

## 2. Actualiza el principio "Contrato primero"
- El único contrato es `kubbo-specs/api/openapi.yaml`.
- `kubbo-api` y `kubbo-web` generan código desde ese archivo: en local desde `../kubbo-specs/api/openapi.yaml` y en CI desde la versión fijada (tag `contract-vX.Y.Z`) en su archivo `.contract-version`.
- Un cambio incompatible del contrato requiere versión MAJOR del contrato y actualizar ambos repos antes de desplegar.
- Verificación: el CI de `kubbo-api` y `kubbo-web` falla si el código generado no coincide con la versión del contrato fijada.

## 3. Nuevo principio: "API documentada de forma exhaustiva"
La documentación de la API es el propio contrato OpenAPI; no existe documentación aparte que pueda quedar desactualizada.
- Cada operación tiene: `operationId` (camelCase, verbo + recurso), `summary` (máximo 80 caracteres), `description` (qué hace, reglas de negocio, efectos secundarios y eventos que emite), `tags` por módulo, `security` y `x-permission` con el permiso exigido.
- Cada parámetro, header, cuerpo y propiedad de esquema tiene `description`, `example` y restricciones (`format`, `minLength`, `maximum`, `enum`, `pattern`, etc.).
- Cada operación documenta **todas** sus respuestas posibles: éxito y errores (400, 401, 403, 404, 409, 422, 429, 500 según aplique), usando el esquema Problem Details (RFC 9457) con ejemplos y la lista de códigos de error (`payment_plan.installment_overdue`) que puede devolver.
- Paginación, filtros y ordenamiento siguen un estándar único documentado en el contrato.
- Los endpoints obsoletos se marcan `deprecated: true` con la fecha de retiro y su reemplazo.
- El texto de la documentación del contrato se escribe en inglés (igual que el código).
- La API sirve la documentación interactiva en `/docs` (Scalar o Swagger UI) generada del contrato: abierta en desarrollo y staging, y protegida con autenticación en producción.
- Verificación: un ruleset de Spectral en el CI de `kubbo-specs` falla si falta cualquiera de estos elementos; y un test de `kubbo-api` falla si existe una ruta HTTP que no está en el contrato.

## 4. Nuevo principio: "Una feature, un worktree, un PR"
- Cada feature se desarrolla en un **git worktree** propio por repo que toca, con el mismo nombre de rama que la carpeta de la spec (`NNN-feature-name`), creado con `scripts/new-feature.sh`. Nunca se trabaja directamente sobre `main`.
- `main` está protegida: todo entra por Pull Request con los checks de CI en verde.
- Cada repo que toca la feature abre **su propio PR**, que usa la plantilla `.github/pull_request_template.md` y describe: spec relacionada, qué se hizo y por qué, cambios por capa, matriz de permisos, i18n, seguridad, migraciones, versión del contrato, cómo probarlo, evidencias y PRs relacionados en los otros repos.
- Orden de merge: `kubbo-specs` → `kubbo-api` → `kubbo-web`.
- Commits con Conventional Commits en inglés (`feat(identity): ...`, `fix(finance): ...`).
- Al terminar, los worktrees se eliminan con `scripts/finish-feature.sh`.
- Verificación: la protección de rama en GitHub y la plantilla de PR; un PR sin descripción completa no se aprueba.

## 5. Definición de terminado
Agrega a la definición de terminado: contrato documentado y Spectral en verde, `/docs` actualizado, worktree y PR por repo con la plantilla completa, y PRs enlazados entre repos.
