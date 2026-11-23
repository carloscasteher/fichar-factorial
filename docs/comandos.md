# Comandos

Todo lo que hace la skill pasa por `factorial.sh`, que también puedes usar a mano, sin agente:

```bash
S=skills/fichar-factorial/scripts/factorial.sh
```

| Comando | Qué hace |
|---|---|
| [`status`](#status) | Muestra credenciales y configuración, sin secretos |
| [`save-credentials`](#save-credentials) | Guarda email y contraseña (interactivo) |
| [`check`](#check) | Hace login en Factorial para validar las credenciales |
| [`configure`](#configure) | Guarda el horario por defecto |
| [`fill`](#fill) | Borra y vuelve a rellenar los fichajes del mes |

## status

```bash
$S status
```

```text
fichar-factorial · estado

  Credenciales  ✔ llavero · tu@email.com
  Horario       ✔ 07:00 – 15:00 · fijo
  Proyecto        Mi proyecto
  Node          ✔ v24.11.0
  Ejecutor      ✔ pnpm
  Config          ~/.config/fichar-factorial/config
```

Cuando la salida no es una terminal (por ejemplo, desde el agente), devuelve líneas `clave: valor`: `credenciales`, `cuenta`, `configuracion`, `entrada`, `salida`, `aleatorio`, `proyecto`, `horario`, `fichero`, `ejecutor` y `node`.

## save-credentials

```bash
$S save-credentials keychain
$S save-credentials zsh
```

Te pide el email y la contraseña de Factorial. Ejecútalo **en tu terminal**, no desde el agente: si no hay una terminal interactiva, falla a propósito.

- `keychain`: llavero de macOS, servicio `factorial-cli`.
- `zsh`: bloque en `~/.zshrc` con `FACTORIAL_USER_EMAIL` y `FACTORIAL_USER_PASSWORD`.

## check

```bash
$S check
```

Hace login en Factorial y no toca ningún fichaje.

| Resultado | Qué significa |
|---|---|
| `✔ Credenciales válidas` | Todo bien |
| `✖ Email o contraseña incorrectos` | Vuelve a guardarlas con `save-credentials` |
| `✖ El cortafuegos de Factorial ha bloqueado el login` | Contraseña con `$` o comillas, o demasiados intentos |
| `✖ No se ha podido conectar con Factorial` | Problema de red |
| `✖ Factorial ha respondido de forma inesperada` | Cuenta solo con Google o con verificación en dos pasos |

## configure

```bash
$S configure --entry 8 --exit 16 --random 10 --project "Mi proyecto"
$S configure --entry 8 --exit 16 --random 0 --no-project
```

Guarda el horario por defecto en `~/.config/fichar-factorial/config`.

## fill

```bash
$S fill --year 2026 --month 11
```

Borra y vuelve a rellenar los fichajes del mes, del día 1 hasta hoy (o hasta fin de mes si es un mes pasado). No acepta meses futuros.

## Opciones de horario

Valen para `configure` y, solo para esa ejecución, para `fill`:

| Opción | Qué hace |
|---|---|
| `--entry H` | Hora de entrada en punto (0–23) |
| `--exit H` | Hora de salida en punto (1–24, mayor que la entrada) |
| `--random N` | `0` = horario fijo; `N` = hasta N minutos aleatorios (1–59) dentro de la franja |
| `--project NOMBRE` | Proyecto de Factorial, con el nombre exacto |
| `--no-project` | No asignar proyecto |

## Colores

En una terminal la salida va con colores. Para quitarlos, define `NO_COLOR=1`:

```bash
NO_COLOR=1 $S status
```
