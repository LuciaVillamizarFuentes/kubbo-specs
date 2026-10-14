Enmienda la constitución (versión 1.0.0 → 1.1.0, cambio MINOR) para reflejar que el proyecto pasó de un monorepo a tres repositorios. No cambies ningún otro principio.

1. Agrega una sección "Repositorios" en Gobernanza:
   - `kubbo-specs`: constitución, specs de Spec Kit y contrato `api/openapi.yaml`. Es el punto de entrada de todo trabajo.
   - `kubbo-api`: backend Go, migraciones y entorno local.
   - `kubbo-web`: frontend Next.js.
   - Una feature usa la misma rama en los repos que toca; orden de merge: specs → api → web; cada PR enlaza a los otros.
   - Cada tarea de `tasks.md` indica su repo destino: `[specs]`, `[api]` o `[web]`.

2. Actualiza el principio de Contrato primero:
   - El único contrato es `kubbo-specs/api/openapi.yaml`.
   - `kubbo-api` y `kubbo-web` generan código desde ese archivo: en local desde `../kubbo-specs/api/openapi.yaml` y en CI desde la versión fijada (tag `contract-vX.Y.Z`) en su archivo `.contract-version`.
   - Un cambio incompatible del contrato requiere versión MAJOR del contrato y actualizar ambos repos antes de desplegar.
   - Verificación: CI de `kubbo-api` y `kubbo-web` falla si el código generado no coincide con la versión del contrato fijada.

3. Actualiza el Sync Impact Report con esta enmienda.
