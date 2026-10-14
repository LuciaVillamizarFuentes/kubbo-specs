# Spec 002 — Dynamic roles and permissions (roles y permisos dinámicos)

Empieza cuando la spec 001 esté terminada. El diseño completo está en Notion → Kubbo → **Roles y permisos**; esta spec lo convierte en código.

---

## Paso 1 · `/speckit-specify`

```
/speckit-specify Roles y permisos dinámicos (002-dynamic-roles-permissions).

Cada propiedad controla quién puede hacer qué. Todo está denegado por defecto: un usuario solo puede hacer lo que alguno de sus roles le permite, en la propiedad activa y dentro del alcance del permiso.

Conceptos:
- Permiso: acción concreta con formato resource.action (ej. tickets.approve), definida por el sistema en un catálogo. Algunos son sensibles (roles.manage, payments.refund, invoices.void, payment_gateway.configure, broadcasts.send, audit_logs.view, property.configure).
- Alcance: own (lo que creé o tengo asignado), space (lo de los espacios que ocupo), property (toda la propiedad).
- Rol: conjunto de permisos con alcance, propio de cada propiedad.
- Plantilla de rol: roles predefinidos por vertical que se copian a la propiedad al crearla.
- Un miembro puede tener varios roles en la misma propiedad; recibe la unión de sus permisos y, si se repite un permiso, el alcance más amplio.
- Roles de plataforma (equipo Kubbo): platform_admin y support_agent, fuera de las propiedades.

Historias:
1. Como administrador, veo la lista de roles de mi propiedad con cuántos miembros tiene cada uno.
2. Como administrador, creo un rol nuevo (ej. "Miembro del consejo") eligiendo permisos agrupados por módulo y su alcance.
3. Como administrador, edito o elimino un rol; no puedo eliminar un rol que tiene miembros ni un rol de sistema, pero puedo restaurarlo a la plantilla.
4. Como administrador, asigno uno o varios roles a un miembro y se los quito.
5. Como administrador, invito a una persona por correo a mi propiedad con uno o varios roles; si ya tiene cuenta queda vinculada, si no, se registra con la invitación.
6. Como usuario, la aplicación solo me muestra los módulos y acciones que mis permisos permiten.
7. Como plataforma, cuando se crea una propiedad se copian automáticamente los roles de la plantilla de su vertical.
8. Como miembro del equipo de Kubbo, solicito un acceso de soporte temporal a una propiedad indicando el motivo; el administrador de la propiedad lo aprueba (o queda marcado como emergencia), vence solo y la propiedad ve el historial de esos accesos.
9. Como administrador, veo el historial de cambios de roles, asignaciones y accesos de soporte.

Reglas obligatorias:
- Nadie puede crear o asignar un rol con permisos que él mismo no tiene (sin escalamiento de privilegios).
- No se puede quitar el último rol con roles.manage de una propiedad.
- Los permisos sensibles solo se asignan a roles marcados como administrativos.
- Los cambios de roles aplican en la siguiente petición del usuario afectado.
- Recurso de otra propiedad → 404; recurso de la propiedad sin permiso → 403 con código permission.denied.
- Todo cambio de roles, asignaciones y accesos de soporte, y cada uso de un permiso sensible, queda en auditoría con antes y después.
- Nombres y descripciones de permisos y roles de plantilla se muestran traducidos (es, en).

Matriz de permisos de esta spec:
- members.view / members.invite / members.update / members.remove: Admin principal (property), Asistente admin (property, sin remove), Consejo (solo view).
- roles.view: Admin principal, Asistente admin, Consejo. roles.manage: solo Admin principal.
- audit_logs.view: Admin principal, Contador (solo finanzas), Consejo.
- Acceso de soporte: solicitar = support_agent; aprobar = rol con roles.manage de la propiedad.

Plantilla residencial inicial: usar la matriz de la página "Roles y permisos" en Notion (Admin principal, Asistente admin, Contador, Consejo, Portero, Mantenimiento/aseo, Propietario, Residente/arrendatario). Las plantillas comercial, hotelera y de establecimientos se crean con sus roles pero pueden completarse en specs posteriores.

Fuera de alcance: 2FA para permisos sensibles (spec posterior), roles a nivel de organización para administradoras multi-propiedad (spec 023), permisos de los módulos que aún no existen (cada spec futura agrega los suyos al catálogo).
```

## Paso 2 · `/speckit-clarify` — respuestas recomendadas
- **¿Permisos de módulos futuros?** El catálogo y las plantillas se crean con todos los permisos de la página de Notion para que la plantilla quede completa; cada spec futura puede agregar más.
- **¿Qué pasa con un miembro sin roles?** Su membresía sigue activa pero no puede hacer nada; ve un mensaje para pedir acceso a la administración.
- **¿Invitación expira?** Sí, a los 7 días; se puede reenviar.
- **¿El acceso de soporte de emergencia?** Solo `platform_admin`, máximo 2 horas, solo lectura y notificación inmediata al administrador de la propiedad.
- **¿Duración máxima del acceso de soporte normal?** 24 horas.
- **¿La propiedad puede editar permisos de un rol de sistema?** Sí; puede restaurarlo a la plantilla. No puede borrarlo.

## Paso 3 · `/speckit-plan`

```
/speckit-plan Marca cada tarea con su repo destino ([specs], [api] o [web]). Implementar en el módulo identity (kubbo-api (internal/modules/identity)) con la estructura hexagonal. Seguir la página "Roles y permisos" de Notion como diseño de referencia.

Base de datos (esquema identity, migraciones goose):
- permissions (key PK, module, allowed_scopes text[], is_sensitive, description_key) — catálogo global sin RLS; la app solo lo lee.
- role_templates (id, vertical, key, name_key, is_admin, permissions jsonb [{key, scope}]) — global sin RLS.
- roles (id uuidv7, property_id, key, name, description, template_id null, is_system, is_admin, created_at, updated_at) — RLS.
- role_permissions (role_id, permission_key, scope enum own|space|property, property_id; PK role_id+permission_key; CHECK de que el scope esté en allowed_scopes vía trigger) — RLS.
- membership_roles (membership_id, role_id, property_id, assigned_by, assigned_at; PK membership_id+role_id) — RLS.
- invitations (id, property_id, email citext, role_ids uuid[], token_hash, invited_by, expires_at, accepted_at, revoked_at) — RLS.
- platform_role_assignments (user_id, platform_role enum platform_admin|support_agent, granted_by, granted_at, revoked_at) — sin RLS.
- support_access_grants (id, user_id, property_id, reason, access_level enum read|write, is_emergency, approved_by, expires_at, revoked_at, created_at) — sin RLS; la propiedad lo consulta por API.
- Quitar role_id de memberships si existe.
- Seed por migración: catálogo de permisos y plantillas por vertical.

Dominio:
- Agregado Role (reglas: permisos válidos del catálogo, scope permitido, sensibles solo si is_admin).
- Servicio de dominio PermissionEvaluator: permisos efectivos = unión de roles, alcance más amplio gana.
- Reglas: sin escalamiento de privilegios (los permisos del rol a asignar ⊆ permisos del actor), último administrador.

Aplicación (casos de uso): ListRoles, CreateRole, UpdateRole, DeleteRole, RestoreRoleFromTemplate, AssignRoles, RevokeRole, InviteMember, AcceptInvitation, GetMyPermissions, RequestSupportAccess, ApproveSupportAccess, RevokeSupportAccess, ListAuditForRoles.
Cuando se crea una propiedad (evento kubbo.property.property.created), un suscriptor copia las plantillas de su vertical.

Plataforma:
- platform/authz: middleware RequirePermission("resource.action") que obtiene los permisos efectivos (cache Redis por membership_id, invalidado por los eventos kubbo.identity.role.updated y kubbo.identity.membership.roles_changed), responde 403 permission.denied y pone el scope concedido en el context.
- Helper de alcance para los repositorios: ScopeFilter(own|space|property) que los casos de uso usan para filtrar.
- Acceso de soporte: sesión especial con property_id y expiración propia; middleware que fuerza solo lectura cuando access_level=read.
- OpenAPI: extensión x-permission en cada operación; un test recorre el contrato y falla si alguna operación privada no declara permiso.

API: GET/POST /roles, GET/PATCH/DELETE /roles/{id}, POST /roles/{id}/restore, GET /permissions (catálogo con textos i18n), GET/PUT /members/{id}/roles, POST /invitations, POST /invitations/accept, GET /me/permissions, POST /support-access, POST /support-access/{id}/approve, POST /support-access/{id}/revoke, GET /support-access.

Auditoría: cada caso de uso de escritura escribe en platform.audit_logs en la misma transacción; el middleware registra el uso de permisos sensibles.

Frontend (repo kubbo-web): pantalla de roles (lista, editor con permisos por módulo y selector de alcance, candado en sensibles), ficha de miembro con asignación de varios roles, invitaciones, "ver como" del rol, historial; menú armado con módulos habilitados ∩ permisos; todo con next-intl (es, en).

Riesgos de seguridad a cubrir en el plan: escalamiento de privilegios, IDOR por alcance mal aplicado, cache de permisos desactualizado, abuso del acceso de soporte, enumeración de usuarios por invitaciones.

Pruebas:
- Dominio: unión de roles, alcance más amplio, sin escalamiento, último admin, sensibles solo en roles admin.
- Integración: por cada endpoint, rol con permiso pasa, sin permiso 403, otra propiedad 404, alcance own/space no ve ajenos.
- Cache: tras quitar un rol, la siguiente petición ya es rechazada.
- Contrato: toda operación privada tiene x-permission.
- E2E: admin crea rol "Consejo", lo asigna, el usuario solo ve lo permitido.
```

## Pasos 4 y 5
`/speckit-tasks` y `/speckit-analyze` sin hallazgos críticos.

## Implementación con ECC
- `/ecc:go-test` en cada tarea de Go; `typescript-reviewer` en el frontend.
- **Obligatorio:** `/ecc:security-scan` y revisión del agente `security-reviewer` antes de cerrar (es el corazón de la seguridad).
- El agente `database-reviewer` revisa las migraciones y el trigger de alcance.
