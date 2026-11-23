# A tener en cuenta

::: danger Borra todos los fichajes del mes
Antes de rellenar un mes, el CLI **borra todos sus fichajes**, también los que hayas metido a mano. Si un día saliste antes, cámbialo en Factorial después de fichar y no vuelvas a lanzar ese mes, o perderás el cambio.
:::

## Qué días ficha

- **Del día 1 hasta hoy, incluido.** Los días que quedan del mes no se tocan; lo normal es fichar a final de mes o volver a lanzarlo.
- **Del día 1 al 5, el mes por defecto es el anterior.**
- **Solo se salta los días que Factorial marca como no laborables o con ausencia** (vacaciones, festivos, bajas). Registra tus ausencias en Factorial **antes** de fichar; si no, esos días se fichan.
- **No se puede excluir un día suelto.** O lo registras como ausencia en Factorial, o lo borras a mano después (y se volverá a crear si vuelves a fichar ese mes).

## Horario

- **Horas en punto.** La entrada y la salida son horas enteras (7, 8, 9…).
- **Modo aleatorio.** Cada día, la entrada se retrasa y la salida se adelanta hasta N minutos al azar (1–59), sin salirse nunca de la franja. Por eso la jornada puede quedar hasta 2N minutos más corta que la franja.
- **Proyecto con el nombre exacto.** Si no coincide con el de Factorial (tildes, mayúsculas…), falla con `✖ El proyecto «<nombre>» no existe en Factorial`.

## Errores

- **Si falla a mitad, el mes puede quedar a medias** (ya borrado y en parte rellenado). Lo verás como `! El mes puede haber quedado a medias`. Vuelve a lanzarlo.
- **Verificación en dos pasos o solo Google.** El login con email y contraseña no funcionará.
- **Contraseñas con `$` o comillas.** El cortafuegos de Factorial puede bloquear el login con un 403, porque las toma por un intento de inyección. Si `check` dice que el cortafuegos lo ha bloqueado, cambia la contraseña de Factorial.
