# fichar-factorial

Skill para rellenar tus fichajes de Factorial desde tu agente de IA (Claude Code u otro que lea skills), con un horario fijo o aleatorio dentro de una franja.

Por debajo usa [`factorial-cli`](https://github.com/DanielRamosAcosta/factorial-cli), de Daniel Ramos, fijado a la versión 1.0.18. Este repo añade:

- Una **skill** que pide confirmación antes de fichar y, si hace falta, te guía para guardar las credenciales y elegir el horario.
- Un **script** (`fichar.sh`) que guarda tu configuración, lee las credenciales sin exponerlas y lanza el CLI. También se puede usar a mano, sin agente.
- Un **instalador** (`install.sh`) que enlaza la skill y te configura credenciales y horario.

## Requisitos

- Node.js 18 o superior.
- pnpm (recomendado) o npm. El script usa `pnpm dlx` y, si no hay pnpm, `npx`.
- Una **contraseña de Factorial**. El CLI entra con email y contraseña, no con Google. Si solo entras con Google, créate una contraseña en Factorial primero.
- macOS para guardar las credenciales en el llavero. En Linux, usa la opción de zsh.

## Instalación

```bash
git clone https://github.com/carloscasteher/fichar-factorial.git
cd fichar-factorial
./install.sh
```

El instalador:

1. Enlaza la skill en `~/.claude/skills/fichar-factorial` (un enlace simbólico al repo, así que para actualizar basta con `git pull`). Si ya tenías una carpeta con ese nombre, te pregunta y la mueve a una copia de seguridad.
2. Te pregunta dónde guardar tu email y tu contraseña de Factorial, o si ya los tienes en zsh:
   - **Llavero de macOS** (recomendado): servicio `factorial-cli`.
   - **`~/.zshrc`**: un bloque entre `# >>> fichar-factorial >>>` y `# <<< fichar-factorial <<<`. La contraseña queda en texto plano.
   - **Ya las tengo en zsh**: usa `FACTORIAL_USER_EMAIL` y `FACTORIAL_USER_PASSWORD`.
3. Hace login en Factorial para comprobar las credenciales. No toca ningún fichaje.
4. Te pregunta el horario: entrada y salida (horas en punto), fijo o aleatorio, y el proyecto de Factorial (opcional). Se guarda en `~/.config/fichar-factorial/config`.

Puedes volver a ejecutar `./install.sh` cuando quieras para cambiar las credenciales o el horario.

Opciones:

- `--dir DIRECTORIO`: enlaza la skill en el directorio de skills de otro agente, en vez de `~/.claude/skills`.
- `--sin-configurar`: solo enlaza la skill; las credenciales y el horario te los pedirá el agente la primera vez.

## Uso

Dile a tu agente «ficha», «ficha este mes», «ficha noviembre» o «ficha el mes pasado». Antes de fichar te enseña el mes, los días y el horario, y espera tu confirmación.

## Cosas a tener en cuenta

- **Borra todos los fichajes del mes antes de rellenarlo**, también los que hayas metido a mano. Si un día saliste antes, cámbialo en Factorial después de fichar y no vuelvas a lanzar ese mes, o perderás el cambio.
- **Rellena del día 1 hasta hoy, incluido.** Los días que quedan del mes no se tocan; lo normal es fichar a final de mes o volver a lanzarlo.
- **Del día 1 al 5, el mes por defecto es el anterior.**
- **Solo se salta los días que Factorial marca como no laborables o con ausencia** (vacaciones, festivos, bajas). Registra tus ausencias en Factorial **antes** de fichar; si no, esos días se fichan.
- **No se puede excluir un día suelto.** O lo registras como ausencia en Factorial, o lo borras a mano después (y se volverá a crear si vuelves a fichar ese mes).
- **Horas en punto.** La entrada y la salida son horas enteras (7, 8, 9…).
- **Modo aleatorio.** Cada día, la entrada se retrasa y la salida se adelanta hasta N minutos al azar (1–59), sin salirse nunca de la franja. Por eso la jornada puede quedar hasta 2N minutos más corta que la franja. Si necesitas la jornada completa, amplía la franja o usa el modo fijo.
- **Proyecto con el nombre exacto.** Si no coincide con el de Factorial (tildes, mayúsculas…), falla con `Project <nombre> not found`.
- **Si falla a mitad, el mes puede quedar a medias** (ya borrado y en parte rellenado). Vuelve a lanzarlo.
- **Verificación en dos pasos o solo Google**: el login con email y contraseña no funcionará.
- **Contraseñas con `$` o comillas**: el cortafuegos de Factorial puede bloquear el login con un 403, porque las toma por un intento de inyección. Si `comprobar` dice que el cortafuegos lo ha bloqueado, cambia la contraseña de Factorial.

## Uso sin agente

```bash
S=skills/fichar-factorial/scripts/fichar.sh

$S estado
$S guardar-credenciales llavero
$S comprobar
$S configurar --entrada 8 --salida 16 --aleatorio 10 --proyecto "Nombre del proyecto"
$S fichar --anio 2026 --mes 11
```

Opciones de `fichar` solo para esa ejecución: `--entrada`, `--salida`, `--aleatorio`, `--proyecto "<nombre>"` y `--sin-proyecto`.

## Seguridad

- El agente nunca ve tu contraseña: las credenciales se guardan desde tu terminal y el script las lee dentro del propio comando.
- La contraseña no se pasa nunca por argumento: se le da al CLI como variable de entorno.
- El fichero de configuración (`~/.config/fichar-factorial/config`) no guarda secretos y tiene permisos `600`.
- El script no envía nada a ningún sitio salvo a Factorial (`id.factorialhr.com` y `api.factorialhr.com`, a través del CLI).

## Créditos y licencia

[`factorial-cli`](https://github.com/DanielRamosAcosta/factorial-cli) es de Daniel Ramos Acosta, con licencia MIT.

Este repo tiene licencia [MIT](LICENSE): cualquiera puede usarlo, copiarlo, modificarlo y redistribuirlo, también con fines comerciales, siempre que mantenga el aviso de copyright.
