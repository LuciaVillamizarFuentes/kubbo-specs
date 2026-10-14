# Empieza aquí

Kubbo ahora vive en **tres repositorios**, uno al lado del otro en `~/workspace`:

```
~/workspace/
├── kubbo-specs/   ← constitución, specs y contrato. Aquí abres Claude Code.
├── kubbo-api/     ← backend Go
└── kubbo-web/     ← frontend Next.js
```

Pasos 1 a 4 ya hechos ✅ (herramientas, Spec Kit, ECC y constitución 1.0.0).

---

## Paso 5 · Iniciar git en los tres repos (~2 min)

En la terminal:
```bash
cd ~/workspace/kubbo-specs && git add . && git commit -m "chore: init spec kit, ecc and constitution"
cd ~/workspace/kubbo-api   && git init && git add . && git commit -m "chore: init repo"
cd ~/workspace/kubbo-web   && git init && git add . && git commit -m "chore: init repo"
```
En GitHub crea **tres repos privados** con esos nombres, y en cada carpeta conéctalo y súbelo:
```bash
git remote add origin git@github.com:<tu-usuario>/<nombre-del-repo>.git
git branch -M main
git push -u origin main
```
Activa en cada repo la protección de `main` (Settings → Branches): todo entra por PR.

✅ **Salió bien si** los tres repos aparecen en GitHub con su primer commit.

---

## Paso 6 · Abrir Claude Code con los tres repos (siempre así)

```bash
cd ~/workspace/kubbo-specs
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../kubbo-api ../kubbo-web
```
Para no escribir eso cada vez, crea un alias (una sola vez):
```bash
echo 'alias kubbo="cd ~/workspace/kubbo-specs && CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../kubbo-api ../kubbo-web"' >> ~/.zshrc && source ~/.zshrc
```
Desde ahora solo escribes `kubbo`.

✅ **Salió bien si** al preguntarle a Claude "¿qué repos tienes disponibles y qué dice cada CLAUDE.md?" menciona los tres.

---

## Paso 7 · Enmendar la constitución (~3 min)

Dentro de Claude Code:
```
/speckit-constitution Aplica la enmienda de docs/kickoff/constitution-amendment-1.1.md
```
Revisa que la versión quede en 1.1.0 y haz commit en `kubbo-specs`:
```bash
git add . && git commit -m "docs: constitution 1.1.0 (three repositories)"
```

---

## Paso 8 · Primera spec: los cimientos y la base de datos

Abre `docs/kickoff/specs-input/000-platform-foundation.md` y sigue sus bloques uno por uno dentro de Claude Code:

1. Pega el bloque de **Paso 1** (`/speckit-specify ...`) → crea `specs/000-.../spec.md`. **Léelo.**
2. Escribe `/speckit-clarify` → responde con las respuestas recomendadas del archivo.
3. Pega el bloque de **Paso 3** (`/speckit-plan ...`) → crea el plan y el `data-model.md`. **Léelos.**
4. Escribe `/speckit-tasks` → revisa que cada tarea diga su repo: `[specs]`, `[api]` o `[web]`.
5. Escribe `/speckit-analyze` → debe salir sin problemas críticos.

Commit en `kubbo-specs`: `git add . && git commit -m "docs(spec-000): spec, plan and tasks"`

Luego crea la rama `000-platform-foundation` en `kubbo-api` y empieza a implementar con:
```
/speckit-implement
```
Pide a Claude que use la skill `tdd-workflow` de ECC en cada tarea (primero el test, luego el código).

---

## Consejos
- **No avances si no entiendes lo que generó un paso.** Pregúntale a Claude "explícame este plan" antes de seguir.
- Commit después de cada paso que funcione, en el repo que corresponda.
- Si te pierdes, vuelve a este archivo o pregunta en el chat.
