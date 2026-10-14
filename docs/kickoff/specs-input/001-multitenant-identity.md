# Spec 001 — Multi-tenant identity (registro, verificación, login y selección de propiedad)

Empieza solo cuando la spec 000 esté terminada.

---

## Paso 1 · `/speckit-specify`

```
/speckit-specify Identidad multi-propiedad (001-multitenant-identity).

Una persona puede pertenecer a varias propiedades (por ejemplo, una administradora que maneja varios conjuntos, o un propietario con apartamentos en dos edificios). Debe tener una sola cuenta y elegir a qué propiedad entra.

Historias:
1. Como persona nueva, me registro con nombre, apellido, correo, celular y contraseña, y acepto la política de tratamiento de datos.
2. Como persona registrada, recibo un código de verificación de 6 dígitos en mi correo; mientras no lo verifique mi cuenta queda pendiente y no puedo ver información de ninguna propiedad.
3. Como usuario verificado, inicio sesión con correo y contraseña.
4. Si pertenezco a una sola propiedad activa, entro directo; si pertenezco a varias, veo "¿A qué propiedad deseas ingresar hoy?" y elijo una; si no pertenezco a ninguna, veo un mensaje que me indica pedir acceso a la administración.
5. Como usuario, puedo cambiar de propiedad sin volver a iniciar sesión.
6. Como usuario, mi sesión se mantiene activa de forma segura y puedo cerrarla; también puedo cerrar todas mis sesiones.
7. Como usuario, puedo recuperar mi contraseña con un código enviado a mi correo.
8. Como plataforma, bloqueo temporalmente los intentos repetidos de login o de códigos inválidos.

Criterios de aceptación:
- Una cuenta pendiente no puede obtener una sesión con propiedad activa.
- Un usuario nunca puede activar una propiedad en la que no tiene membresía activa.
- Los códigos expiran a los 10 minutos y se invalidan tras 5 intentos fallidos.
- Las contraseñas y los códigos nunca se guardan en texto plano.
- Los mensajes de error de login no revelan si el correo existe.
- El consentimiento de datos queda registrado con fecha y versión de la política.
- Cada login, cambio de propiedad y cierre de sesión queda en auditoría.

Fuera de alcance: roles y permisos (002), invitaciones de administradores a residentes (llegan con 002/003), login por WhatsApp, frontend completo (solo las pantallas de este flujo).
```

## Paso 2 · `/speckit-clarify` — respuestas recomendadas
- **Canal del código:** correo en esta spec. WhatsApp llega con el módulo `comms`.
- **Duración de sesión:** access token de 15 minutos y refresh token de 30 días, rotado en cada uso y revocable.
- **Política de contraseña:** mínimo 10 caracteres y validación contra contraseñas comunes; sin reglas de mayúsculas o símbolos obligatorios.
- **¿Quién crea membresías en esta spec?** Solo el seed de desarrollo y un endpoint de plataforma (super admin). Las invitaciones llegan en 002.
- **¿Las membresías tienen RLS?** No: son por usuario (están en la allowlist de la spec 000). El acceso se controla en la aplicación.

## Paso 3 · `/speckit-plan`

```
/speckit-plan Marca cada tarea con su repo destino ([specs], [api] o [web]). Módulo identity en kubbo-api (internal/modules/identity) con estructura hexagonal.

Tablas (esquema identity, inglés, uuidv7):
- users (id, first_name, last_name, email citext unique, phone, password_hash, status enum pending|active|disabled, email_verified_at, created_at, updated_at)
- verification_codes (id, user_id, purpose enum email_verification|password_reset, code_hash, expires_at, attempts, consumed_at, created_at)
- sessions (id, user_id, refresh_token_hash, active_property_id null, user_agent, ip, expires_at, revoked_at, created_at, last_used_at)
- memberships (id, user_id, property_id, status enum invited|active|suspended, created_at); los roles se asignan en la spec 002 con membership_roles — sin FK física a property.properties; unique (user_id, property_id)
- consents (id, user_id, type, policy_version, granted, granted_at)
users, verification_codes, sessions y consents no tienen property_id; agregar memberships y estas tablas a la allowlist de RLS.

Seguridad:
- Contraseñas con argon2id; códigos de 6 dígitos guardados como hash.
- Access token JWT (15 min) con claims sub, sid, pid (propiedad activa); refresh token opaco (30 días) rotado en cada uso, guardado como hash; ambos en cookies httpOnly, Secure, SameSite=Lax.
- Rate limiting con Redis: login, verificación y recuperación.
- Middleware de tenancy: lee pid del token, valida que la membresía siga activa (cache en Redis) y pone PropertyID en el context.
- Emails con un puerto Mailer; adaptador SMTP local (Mailpit en docker-compose) y luego proveedor real.

API (agregar primero a kubbo-specs/api/openapi.yaml y subir la versión del contrato):
POST /auth/register, POST /auth/verify-email, POST /auth/resend-code, POST /auth/login, POST /auth/refresh, POST /auth/logout, POST /auth/logout-all, POST /auth/password/forgot, POST /auth/password/reset, GET /me, GET /me/properties, POST /me/active-property.
GET /me/properties obtiene los nombres de las propiedades llamando al api.go del módulo property (nunca leyendo su esquema).

Eventos de dominio (outbox): kubbo.identity.user.registered, kubbo.identity.user.verified, kubbo.identity.session.property_switched.

Frontend (repo kubbo-web): pantallas login, registro, verificación de código y selector de propiedades, con cliente generado desde OpenAPI y textos en messages/es.json.

Pruebas: dominio y casos de uso con puertos falsos; repositorios con testcontainers; tests de API para cada criterio de aceptación; E2E con Playwright del flujo registro → verificación → login → selección.
```

## Pasos 4 y 5
`/speckit-tasks` y luego `/speckit-analyze` sin hallazgos críticos.

## Implementación con ECC
- `/ecc:go-test` por tarea en Go; agente `typescript-reviewer` en frontend.
- **Obligatorio en esta spec:** `/ecc:security-scan` y revisión del agente `security-reviewer` antes del merge (es autenticación).
- Skill `e2e-testing` para el flujo completo.
