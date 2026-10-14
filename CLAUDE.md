# Kubbo — repositorio de specs (punto de entrada)

SaaS multi-vertical para administrar inmuebles de uso compartido (propiedad horizontal residencial, comercial, hotelero y establecimientos), empezando por Colombia.

## Los tres repositorios
```
~/workspace/
├── kubbo-specs/   ← ESTE repo. Constitución, specs (SDD) y contrato api/openapi.yaml
├── kubbo-api/     ← backend Go (monolito modular) + migraciones + docker-compose local
└── kubbo-web/     ← frontend Next.js
```
- Claude Code se abre **siempre desde aquí**:
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../kubbo-api ../kubbo-web`
  (la variable hace que también se lean los `CLAUDE.md` de los otros dos repos).
- Las specs y planes se escriben aquí; el código va en `../kubbo-api` o `../kubbo-web` según la tarea. Cada tarea de `tasks.md` indica en qué repo va (`[api]`, `[web]` o `[specs]`).
- **Contrato:** `api/openapi.yaml` de este repo es la única fuente de verdad. `kubbo-api` y `kubbo-web` generan su código desde `../kubbo-specs/api/openapi.yaml` en local, y en CI desde la versión fijada en su archivo `.contract-version`.
- **Una feature = un worktree por repo + un PR por repo.** Se crean con `./scripts/new-feature.sh NNN-feature-name [api] [web]`, que deja todo en `~/workspace/features/NNN-feature-name/` con la misma rama en cada repo. Nunca se trabaja sobre `main`.
- **PRs:** uno por repo, con la plantilla `.github/pull_request_template.md` completa (créalos con `gh pr create`). Orden de merge: specs → api → web. Cada PR enlaza a los otros. Commits con Conventional Commits en inglés.
- **Al terminar:** `./scripts/finish-feature.sh NNN-feature-name` elimina los worktrees.
- **Documentación de la API:** el contrato es la documentación. Cada operación lleva `operationId`, `summary`, `description`, `tags`, `x-permission` (o `x-public: true`), parámetros y propiedades con `description` y `example`, y todas sus respuestas de error con Problem Details. Antes de cerrar una tarea de contrato corre `npx @stoplight/spectral-cli lint api/openapi.yaml` (reglas en `.spectral.yaml`).

## Reglas de comportamiento (obligatorias)
1. **No des nada por sentado.** Si no conoces un dato (una regla de negocio, una ley, un valor, una preferencia), no lo inventes: pregunta. Si es una spec, márcalo como `[NEEDS CLARIFICATION: ...]`.
2. **Detente y pregunta antes de una decisión importante:** elegir o cambiar una dependencia o proveedor; cambiar el modelo de datos, un contrato de API o un evento; cualquier regla de negocio, de dinero, de permisos o legal; algo que afecte la seguridad o la privacidad; o algo difícil de revertir. Presenta 2-3 opciones con pros y contras y tu recomendación, y espera la respuesta.
3. **Registra las decisiones** en el `research.md` de la spec activa (decisión, motivo, alternativas descartadas).
4. **Seguridad primero.** Si una solución rápida debilita la seguridad, no la uses; explica el riesgo y propone la alternativa segura.
5. **Toda feature trae permisos.** Confirma la matriz de permisos de la spec antes de implementar (diseño en Notion → "Roles y permisos").
6. **Nada de textos quemados.** Todo texto visible sale de i18n (`es`, `en`); el backend devuelve códigos de error.
7. **Respeta los límites de complejidad** de la constitución (principio 12); si se pasan, refactoriza antes de cerrar la tarea.
8. **SOLID y hexagonal** en todo el código.
9. **No mezcles repos en un commit:** cada repo tiene sus propios commits y PR. Antes de escribir código, confirma que estás en el worktree de la feature y no en `main`.
10. **Si algo no funciona después de dos intentos, para** y explica qué probaste.

## Cómo trabajamos
- **Spec Kit (SDD):** `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`. La constitución está en `.specify/memory/constitution.md` y prevalece sobre todo.
- **ECC para ejecutar:** `tdd-workflow` (Go: `/ecc:go-test`), `/ecc:go-review` o el agente `typescript-reviewer`, y al cerrar `/ecc:code-review` y `/ecc:security-scan` cuando toque auth, permisos, pagos o datos personales. No usar `/ecc:plan` para features.

## Convenciones de nombres (todo en inglés)
- Specs: `specs/NNN-kebab-case-name/`.
- Permisos: `<resource>.<action>` (ej. `tickets.approve`). Errores: `<entity>.<reason>`. Eventos: `kubbo.<module>.<entity>.<event_past_tense>`.
- Go, TypeScript y base de datos: ver el `CLAUDE.md` de cada repo.

## Glosario (ES → EN)
organización → organization · propiedad → property · sector/torre → sector · espacio/apartamento/local → space · ocupación → occupancy · membresía → membership · rol → role · permiso → permission · coeficiente → ownership_coefficient · cuota de administración → admin_fee · canon → rent · cartera → receivables · plan de pagos → payment_plan · proveedor → vendor · PQR → ticket · paquete → package · visitante/acceso → access_pass · trasteo/obra → space_movement · zona común → common_area · asamblea → assembly · difusión → broadcast · estadía → stay · locatario → retail_tenant

## Documentación de producto
Notion: página "Kubbo" y subpáginas (Módulos y Flujos, Roles y permisos, Lineamientos BE/FE/BD, Flujo de desarrollo, Modelo de negocio). El diagrama de BD en Notion es el modelo lógico de referencia; cada spec crea solo las tablas que necesita.
