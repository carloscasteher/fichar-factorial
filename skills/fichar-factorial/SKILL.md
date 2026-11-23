---
name: fichar-factorial
description: Rellena los fichajes del usuario en Factorial con factorial-cli, con un horario fijo o aleatorio dentro de una franja. La primera vez le guía para guardar sus credenciales (llavero de macOS o variables de zsh) y elegir el horario. Pide confirmación antes de fichar, porque el CLI borra y vuelve a crear todos los fichajes del mes. Úsala cuando el usuario diga "ficha", "fichar", "ficha el mes", "ficha noviembre", "rellena Factorial", "rellena los fichajes", "configura el fichaje" o mencione fichajes o Factorial.
---

# Fichar en Factorial

Todo pasa por `scripts/factorial.sh`, dentro del directorio base de esta skill (te lo indica el sistema al cargarla; suele ser un enlace al repo clonado). Llámalo siempre con su **ruta absoluta**; en esta guía aparece como `factorial.sh`. Si el usuario ya ejecutó `install.sh` con la configuración, los pasos 2 a 4 estarán hechos. Ese script envuelve [`factorial-cli`](https://github.com/DanielRamosAcosta/factorial-cli) 1.0.18 y lo lanza con `pnpm dlx`, o con `npx` si no hay pnpm.

## Reglas

- **Nunca pidas la contraseña en el chat, ni la leas, ni la muestres.** Las credenciales las guarda el usuario en su propia terminal; el script las lee dentro del propio comando.
- No pases nunca `--email` ni `--password` al CLI ni hagas `echo` de las variables `FACTORIAL_USER_*`.
- No lances `fill` sin una confirmación explícita del usuario en esta conversación y para ese mes.

## Cómo funciona el CLI (explícaselo al usuario cuando toque)

- **Borra todos los fichajes del mes** y los vuelve a crear, también los que el usuario haya metido a mano.
- Rellena desde el día 1 **hasta hoy, incluido**. Los días que quedan del mes no se tocan.
- Solo ficha los días laborables sin ausencias del calendario de Factorial. Si falta una ausencia, ese día se ficha. No se puede excluir un día suelto.
- Las horas de entrada y salida van **en punto** (7, 8, 9…), sin minutos.
- El proyecto tiene que coincidir **exactamente** con el nombre que tiene en Factorial.

## Flujo

### 1. Estado
Ejecuta `factorial.sh status`. Desde el agente (sin terminal) devuelve líneas `clave: valor` sin secretos: `credenciales` (`llavero`, `zsh` o `ninguna`), `cuenta`, `configuracion` (`ok` o `falta`), `entrada`, `salida`, `aleatorio`, `proyecto`, `horario` (texto ya formateado), `ejecutor` y `node`. En una terminal sale como tabla con colores.

- Si `node` es `falta` o el `ejecutor` es `ninguno`, dile que instale Node.js 18 o superior (y pnpm, si quiere) y para.
- Si `credenciales` es `ninguna`, ve al paso 2.
- Si `configuracion` es `falta`, ve al paso 4.
- Si todo está bien, ve directo al paso 5.

### 2. Credenciales (primera vez)
Pregunta con `AskUserQuestion` dónde las tiene o dónde quiere guardarlas:

- **Ya las tengo en zsh**: tiene `FACTORIAL_USER_EMAIL` y `FACTORIAL_USER_PASSWORD` exportadas en `~/.zshrc`. Vuelve a ejecutar `status`; si sigue saliendo `ninguna`, revisa con él los nombres de las variables (sin enseñar su valor).
- **Guardarlas en el llavero de macOS** (recomendado en Mac): no quedan en texto plano.
- **Guardarlas en `~/.zshrc`**: más sencillo, pero la contraseña queda en texto plano en ese fichero.

Para las dos últimas, dale este comando para que lo ejecute **en su propia terminal**, fuera del agente, porque pide la contraseña de forma interactiva (sustituye la ruta por la absoluta):

```bash
"/ruta/absoluta/a/scripts/factorial.sh" save-credentials keychain
"/ruta/absoluta/a/scripts/factorial.sh" save-credentials zsh
```

También puede ejecutar `./install.sh` desde el repo clonado, que hace las credenciales y el horario de una vez. Recuérdale que el login es con email y contraseña de Factorial, no con Google. Si solo entra con Google, tiene que crearse primero una contraseña en Factorial. Espera a que diga que ya está y vuelve a ejecutar `status`.

### 3. Comprobar las credenciales
Ejecuta `factorial.sh check`. Solo hace login en Factorial; no toca ningún fichaje.

- `✔ Credenciales válidas`: sigue.
- `✖ Email o contraseña incorrectos`: que repita el paso 2 en su terminal (sobrescribe lo anterior).
- `✖ El cortafuegos de Factorial ha bloqueado el login`: pasa con contraseñas que llevan `$` o comillas, o tras muchos intentos. Que pruebe más tarde o cambie la contraseña. No reintentes en bucle.
- `✖ No se ha podido conectar con Factorial`: problema de red; que revise la conexión.
- `✖ Factorial ha respondido de forma inesperada`: puede que su cuenta use solo Google o la verificación en dos pasos. Díselo y para.

En macOS, la primera lectura del llavero puede abrir un diálogo de permiso. Si el comando se queda esperando, dile que pulse «Permitir siempre».

### 4. Horario (primera vez)
Pregunta con `AskUserQuestion`, en una sola tanda:

1. **Franja**: hora de entrada y de salida, en punto (por ejemplo, de 8 a 16).
2. **Fijo o aleatorio**:
   - **Fijo**: todos los días exactamente a esas horas.
   - **Aleatorio dentro de la franja**: cada día la entrada se retrasa y la salida se adelanta hasta N minutos al azar (por defecto 10), sin salirse nunca de la franja. Avísale de que la jornada puede quedar hasta 2N minutos más corta que la franja.
3. **Proyecto**: el nombre exacto del proyecto en Factorial, o ninguno.

Guárdalo con:

```bash
factorial.sh configure --entry <H> --exit <H> --random <0|N> --project "<nombre>"
factorial.sh configure --entry <H> --exit <H> --random <0|N> --no-project
```

Si quiere cambiar el horario más adelante («cambia mi horario», «ponlo aleatorio»), vuelve a este paso.

### 5. Mes
- Si dice el mes («ficha noviembre», «el mes pasado»), úsalo. Si no dice año, toma el mes más reciente con ese nombre que no sea futuro.
- Si no dice nada: el mes actual, o el anterior si hoy es día 1–5. Calcúlalo con `date`, no de memoria.
- Un mes futuro no se puede fichar: avísale y no lances nada.

### 6. Confirmación
Antes de ejecutar, enséñale un resumen y espera un sí explícito (`AskUserQuestion`):

- Mes y año, y qué días se rellenan: del 1 a hoy, o hasta fin de mes si es un mes pasado.
- Franja, modo (fijo o aleatorio de N minutos) y proyecto.
- **Aviso: se borrarán todos los fichajes de ese mes, también los manuales, y se volverán a crear.**
- Que revise que sus vacaciones, festivos y ausencias estén en Factorial, porque si no se ficharán.

Si pide otro horario o quitar el proyecto **solo para esta vez**, pásalo como opción a `fill` sin tocar la configuración. Si pide saltarse un día concreto, explica que el CLI no puede: o registra ese día como ausencia en Factorial antes, o lo borra él a mano después.

### 7. Fichar
Lanza el comando desde un directorio temporal (no desde un repo):

```bash
factorial.sh fill --year <AAAA> --month <M>
```

Opciones solo para esta ejecución: `--entry`, `--exit`, `--random`, `--project "<nombre>"` o `--no-project`.

### 8. Resultado
El script traduce la salida del CLI: una cuadrícula con los días fichados (`✔ lun 03`…), el total (`✔ 15 días fichados`) y, si los hay, los días entre semana que se han saltado (`Saltados entre semana: lun 02`). Resume en una o dos líneas qué días se han fichado y cuáles se han saltado, para que el usuario vea si falta alguna ausencia en Factorial.

Errores habituales:
- `✖ Email o contraseña incorrectos`: vuelve al paso 2.
- `✖ El proyecto «<nombre>» no existe en Factorial`: el nombre no coincide (tildes, mayúsculas…). Pregúntale el nombre exacto, guárdalo con `configure --project` y vuelve a lanzarlo; no hace falta repetir la confirmación si el mes no cambia.
- `✖ Factorial devuelve más de un empleado activo para tu cuenta`: es un problema de la cuenta en Factorial; no se arregla desde aquí.
- `✖ El CLI de Factorial ha fallado`: debajo van las últimas líneas del error original; resúmeselas.
- `! El mes puede haber quedado a medias`: ya se borró y solo se rellenó en parte. Díselo y propón lanzarlo otra vez.
