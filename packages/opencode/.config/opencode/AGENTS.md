# Reglas globales de OpenCode

## Principios de trabajo

- Inspecciona el repositorio antes de proponer cambios. No inventes archivos, APIs,
  dependencias, comandos ni convenciones.
- Para tareas no triviales, presenta primero un plan breve y verificable.
- Realiza el cambio mínimo y coherente que resuelva la solicitud.
- No reescribas módulos completos cuando una modificación localizada sea suficiente.
- Conserva compatibilidad y comportamiento público salvo que la tarea solicite lo contrario.
- No declares éxito sin ejecutar una verificación apropiada.
- Cuando una verificación no pueda ejecutarse, explica exactamente por qué.
- Nunca ocultes fallos mediante desactivación de pruebas, mocks irreales, supresión
  indiscriminada de tipos o eliminación de validaciones.
- Antes de agregar una dependencia, verifica si el proyecto ya dispone de una solución.
- No incluyas secretos, credenciales, tokens ni datos personales en código, logs o commits.
- No ejecutes operaciones destructivas ni publiques cambios remotos sin autorización.

## Calidad de respuesta

- Sé preciso, técnico y directo.
- Distingue hechos observados, inferencias y recomendaciones.
- Cita rutas de archivo y símbolos concretos al explicar problemas.
- En revisiones, prioriza errores y riesgos sobre preferencias estilísticas.
- Resume al final los archivos cambiados, verificaciones y riesgos pendientes.

## Git

- Revisa `git status` y el diff antes de editar.
- No sobrescribas cambios del usuario que no pertenezcan a la tarea.
- No hagas commits, pushes, rebases, resets, force-pushes ni limpieza destructiva
  salvo petición explícita.
- Mantén los commits conceptualmente atómicos cuando el usuario solicite crearlos.

## Python, ciencia de datos y visión

- Favorece funciones pequeñas, type hints, docstrings útiles y comportamiento reproducible.
- Usa NumPy/Pandas vectorizado cuando mejore claridad y rendimiento.
- Explicita forma, dtype, unidades, sistema de coordenadas y convenciones de imagen.
- Evita fuga de datos y valida separación temporal o por grupos cuando aplique.
- En métodos numéricos, documenta tolerancias, criterios de parada y estabilidad.
- Usa `ruff`, `mypy` y `pytest` cuando estén configurados en el proyecto.

## SQL y analítica

- Determina primero el grano de cada tabla.
- Verifica cardinalidad de joins, duplicados, nulos y filtros temporales.
- Evita `SELECT *` en código de producción.
- Usa parámetros; nunca concatentes entradas del usuario en SQL.
- Para métricas, define denominador, ventana temporal y manejo de nulos/división por cero.

## Astro, TypeScript y frontend

- Prefiere renderizado estático y JavaScript cliente mínimo.
- Usa TypeScript estricto y componentes con responsabilidades claras.
- Preserva HTML semántico, navegación por teclado, foco visible y contraste adecuado.
- Optimiza imágenes, fuentes y Core Web Vitals.
- No agregues dependencias de UI si CSS y componentes existentes bastan.
- Usa `pnpm` cuando exista `pnpm-lock.yaml`.

## Matemáticas y LaTeX

- Mantén rigor en hipótesis, dominios, regularidad y condiciones de frontera.
- No intercambies límites, derivadas e integrales sin justificar las condiciones.
- Conserva la notación y plantilla existentes.
- No agregues paquetes LaTeX innecesarios o incompatibles.
- Comprueba referencias, etiquetas, numeración y compilación.

## Instrucciones específicas del proyecto

Las reglas globales no sustituyen la documentación local. En cada repositorio:

1. Busca `AGENTS.md`, `README`, `CONTRIBUTING`, archivos de build y configuración.
2. Si no existe un `AGENTS.md` útil, sugiere al usuario ejecutar `/init`.
3. Sigue primero las reglas específicas del proyecto cuando sean más restrictivas.
