## Spec
<!-- Enlace a la carpeta de la spec en kubbo-specs, ej. specs/002-dynamic-roles-permissions -->
Spec: 

## Qué se hizo
<!-- Resumen en 3-5 líneas de lo implementado en ESTE repo -->

## Por qué
<!-- Problema u objetivo de negocio que resuelve; decisiones importantes y dónde quedaron registradas (research.md) -->

## Cambios por capa
<!-- Borra las que no apliquen -->
- **Contrato (OpenAPI):** 
- **Base de datos / migraciones:** 
- **Dominio y casos de uso:** 
- **Adaptadores (HTTP, repositorios, proveedores):** 
- **Frontend (pantallas y componentes):** 
- **Eventos publicados / consumidos:** 

## Permisos
<!-- Permisos nuevos o modificados (resource.action), su alcance y qué roles de la plantilla los reciben -->
| Permiso | Alcance | Roles |
|---|---|---|
|  |  |  |

## i18n
- [ ] Textos nuevos en `es` y `en`
- [ ] Códigos de error nuevos documentados en el contrato

## Seguridad
<!-- Riesgos considerados y cómo se mitigaron; resultado de /ecc:security-scan si aplica -->

## Contrato
- Versión del contrato usada: `contract-v`
- [ ] Spectral en verde y `/docs` actualizado (si cambió el contrato)

## Cómo probarlo
1. 
2. 

## Evidencias
<!-- Resultado de tests, cobertura, capturas de pantalla o video -->

## PRs relacionados
- kubbo-specs: 
- kubbo-api: 
- kubbo-web: 

## Checklist (definición de terminado)
- [ ] Tests escritos primero y en verde; cobertura ≥ 80% en domain y application
- [ ] Tests de permisos: 403 sin permiso, 404 otra propiedad, alcance respetado
- [ ] Límites de complejidad y lint en verde
- [ ] `/ecc:code-review` sin hallazgos bloqueantes
- [ ] Migraciones reversibles y RLS probado (si aplica)
- [ ] Sin `[NEEDS CLARIFICATION]` abiertos en la spec
- [ ] Documentación actualizada (Notion o specs)
