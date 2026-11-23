#!/usr/bin/env bash
set -euo pipefail

CLI_VERSION="1.0.18"
KEYCHAIN_SERVICE="factorial-cli"
LOGIN_URL="https://id.factorialhr.com/api/auth/challenges/first_factor"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fichar-factorial"
CONFIG_FILE="$CONFIG_DIR/config"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
ZSH_BLOCK_START="# >>> fichar-factorial >>>"
ZSH_BLOCK_END="# <<< fichar-factorial <<<"
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Uso: $(basename "$0") <comando> [opciones]

Comandos:
  estado                                  Muestra credenciales y configuración (sin secretos)
  guardar-credenciales llavero|zsh        Guarda email y contraseña (interactivo, en tu terminal)
  comprobar                               Hace login en Factorial para validar las credenciales
  configurar [opciones de horario]        Guarda el horario por defecto
  fichar --anio AAAA --mes M [opciones]   Borra y vuelve a rellenar los fichajes del mes

Opciones de horario:
  --entrada H        Hora de entrada en punto (0-23)
  --salida H         Hora de salida en punto (1-24, mayor que la entrada)
  --aleatorio N      0 = horario fijo; N = minutos aleatorios (1-59) dentro de la franja
  --proyecto NOMBRE  Proyecto de Factorial (nombre exacto)
  --sin-proyecto     No asignar proyecto
EOF
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

is_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

config_get() {
  [ -f "$CONFIG_FILE" ] || return 0
  local line
  line="$(grep -E "^$1=" "$CONFIG_FILE" | tail -n 1 || true)"
  printf '%s' "${line#*=}"
}

config_has() {
  [ -f "$CONFIG_FILE" ] && grep -qE "^$1=" "$CONFIG_FILE"
}

config_set() {
  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  local tmp
  tmp="$(mktemp)"
  awk -v key="$1=" 'index($0, key) != 1' "$CONFIG_FILE" > "$tmp"
  printf '%s=%s\n' "$1" "$2" >> "$tmp"
  cat "$tmp" > "$CONFIG_FILE"
  rm -f "$tmp"
}

has_keychain() {
  command -v security >/dev/null 2>&1
}

keychain_has_entry() {
  has_keychain && security find-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1
}

keychain_account() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null | sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p'
}

load_zsh_env() {
  if [ -n "${FACTORIAL_USER_EMAIL:-}" ] && [ -n "${FACTORIAL_USER_PASSWORD:-}" ]; then
    return 0
  fi
  command -v zsh >/dev/null 2>&1 || return 1
  [ -f "$ZSHRC" ] || return 1
  local out email password
  out="$(zsh -c 'source "$1" >/dev/null 2>&1 </dev/null; print -r -- "${FACTORIAL_USER_EMAIL:-}"; print -r -- "${FACTORIAL_USER_PASSWORD:-}"' _ "$ZSHRC" 2>/dev/null || true)"
  { IFS= read -r email || true; IFS= read -r password || true; } <<< "$out"
  [ -n "$email" ] && [ -n "$password" ] || return 1
  export FACTORIAL_USER_EMAIL="$email"
  export FACTORIAL_USER_PASSWORD="$password"
}

credentials_source() {
  local configured
  configured="$(config_get FICHAR_CREDENCIALES)"
  case "$configured" in
    llavero) keychain_has_entry && echo llavero || echo ninguna ;;
    zsh) (load_zsh_env) && echo zsh || echo ninguna ;;
    *)
      if keychain_has_entry; then
        echo llavero
      elif (load_zsh_env); then
        echo zsh
      else
        echo ninguna
      fi
      ;;
  esac
}

load_credentials() {
  case "$(credentials_source)" in
    llavero)
      FACTORIAL_USER_EMAIL="$(keychain_account)"
      FACTORIAL_USER_PASSWORD="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w)"
      export FACTORIAL_USER_EMAIL FACTORIAL_USER_PASSWORD
      ;;
    zsh)
      load_zsh_env
      ;;
    *)
      die "no hay credenciales guardadas; ejecuta en tu terminal «$SCRIPT guardar-credenciales llavero» o «$SCRIPT guardar-credenciales zsh»"
      ;;
  esac
  [ -n "${FACTORIAL_USER_EMAIL:-}" ] && [ -n "${FACTORIAL_USER_PASSWORD:-}" ] || die "las credenciales guardadas están incompletas"
}

runner() {
  if command -v pnpm >/dev/null 2>&1; then
    echo pnpm
  elif command -v npx >/dev/null 2>&1; then
    echo npx
  else
    echo ninguno
  fi
}

schedule_complete() {
  config_has FICHAR_ENTRADA && config_has FICHAR_SALIDA && config_has FICHAR_ALEATORIO && config_has FICHAR_PROYECTO
}

cmd_estado() {
  local source
  source="$(credentials_source)"
  echo "credenciales: $source"
  case "$source" in
    llavero) echo "cuenta: $(keychain_account)" ;;
    zsh) load_zsh_env && echo "cuenta: $FACTORIAL_USER_EMAIL" ;;
  esac
  if schedule_complete; then
    echo "configuracion: ok"
    echo "entrada: $(config_get FICHAR_ENTRADA)"
    echo "salida: $(config_get FICHAR_SALIDA)"
    echo "aleatorio: $(config_get FICHAR_ALEATORIO)"
    echo "proyecto: $(config_get FICHAR_PROYECTO)"
  else
    echo "configuracion: falta"
  fi
  echo "fichero: $CONFIG_FILE"
  echo "ejecutor: $(runner)"
  if command -v node >/dev/null 2>&1; then
    echo "node: $(node --version)"
  else
    echo "node: falta"
  fi
}

require_tty() {
  [ -t 0 ] || die "este comando pide la contraseña: ejecútalo tú en una terminal, no desde el agente"
}

cmd_guardar_credenciales() {
  local target="${1:-}"
  local email password
  case "$target" in
    llavero)
      has_keychain || die "el llavero solo está disponible en macOS; usa «zsh»"
      require_tty
      read -r -p "Email de Factorial: " email
      [ -n "$email" ] || die "el email no puede estar vacío"
      while security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1; do :; done
      echo "Ahora escribe tu contraseña de Factorial (dos veces, no se verá):"
      security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$email" -w
      config_set FICHAR_CREDENCIALES llavero
      echo "Guardadas en el llavero (servicio «$KEYCHAIN_SERVICE»)."
      ;;
    zsh)
      require_tty
      read -r -p "Email de Factorial: " email
      read -r -s -p "Contraseña de Factorial (no se verá): " password
      echo
      [ -n "$email" ] && [ -n "$password" ] || die "el email y la contraseña no pueden estar vacíos"
      touch "$ZSHRC"
      local tmp
      tmp="$(mktemp)"
      awk -v s="$ZSH_BLOCK_START" -v e="$ZSH_BLOCK_END" '$0==s{skip=1;next} $0==e{skip=0;next} !skip' "$ZSHRC" > "$tmp"
      {
        printf '%s\n' "$ZSH_BLOCK_START"
        printf 'export FACTORIAL_USER_EMAIL=%s\n' "$(shell_quote "$email")"
        printf 'export FACTORIAL_USER_PASSWORD=%s\n' "$(shell_quote "$password")"
        printf '%s\n' "$ZSH_BLOCK_END"
      } >> "$tmp"
      cat "$tmp" > "$ZSHRC"
      rm -f "$tmp"
      config_set FICHAR_CREDENCIALES zsh
      echo "Guardadas en $ZSHRC. Abre una terminal nueva para que las coja tu shell."
      ;;
    *)
      die "indica dónde guardarlas: llavero o zsh"
      ;;
  esac
}

cmd_comprobar() {
  command -v node >/dev/null 2>&1 || die "hace falta Node.js 18 o superior"
  load_credentials
  node --input-type=module -e '
const res = await fetch(process.argv[1], {
  method: "POST",
  headers: { "content-type": "application/json", accept: "application/json" },
  body: JSON.stringify({ email: process.env.FACTORIAL_USER_EMAIL, password: process.env.FACTORIAL_USER_PASSWORD }),
});
let body;
try { body = await res.json(); } catch { body = undefined; }
const session = res.headers.getSetCookie().some((c) => c.startsWith("_factorial_id="));
if (res.ok && body?.success && session) {
  console.log("ok: credenciales válidas");
  process.exit(0);
}
if (body?.error?.code === "invalid_credentials" || (res.ok && body && !body.success)) {
  console.error("error: email o contraseña incorrectos");
  process.exit(2);
}
if (res.status === 403 && !body) {
  console.error("error: el cortafuegos de Factorial ha bloqueado el login (HTTP 403); pasa con contraseñas que parecen código, como las que llevan $ o comillas, o tras muchos intentos seguidos. Prueba más tarde o cambia la contraseña");
  process.exit(3);
}
console.error(`error: Factorial ha respondido de forma inesperada (HTTP ${res.status}); puede que la cuenta use solo Google o verificación en dos pasos`);
process.exit(1);
' "$LOGIN_URL"
}

ENTRADA=""
SALIDA=""
ALEATORIO=""
PROYECTO=""
PROYECTO_SET=""
ANIO=""
MES=""

parse_options() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --entrada) ENTRADA="${2:-}"; shift 2 ;;
      --salida) SALIDA="${2:-}"; shift 2 ;;
      --aleatorio) ALEATORIO="${2:-}"; shift 2 ;;
      --proyecto) PROYECTO="${2:-}"; PROYECTO_SET=1; shift 2 ;;
      --sin-proyecto) PROYECTO=""; PROYECTO_SET=1; shift ;;
      --anio) ANIO="${2:-}"; shift 2 ;;
      --mes) MES="${2:-}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "opción desconocida: $1" ;;
    esac
  done
}

validate_schedule() {
  is_int "$1" && [ "$1" -ge 0 ] && [ "$1" -le 23 ] || die "la entrada tiene que ser una hora en punto entre 0 y 23"
  is_int "$2" && [ "$2" -ge 1 ] && [ "$2" -le 24 ] || die "la salida tiene que ser una hora en punto entre 1 y 24"
  [ "$2" -gt "$1" ] || die "la salida tiene que ser posterior a la entrada"
  is_int "$3" && [ "$3" -le 59 ] || die "el aleatorio tiene que ser 0 (fijo) o un número de minutos entre 1 y 59"
  [ $(( ($2 - $1) * 60 )) -gt $(( $3 * 2 )) ] || die "el aleatorio es demasiado grande para esa franja"
}

cmd_configurar() {
  parse_options "$@"
  local entrada="${ENTRADA:-$(config_get FICHAR_ENTRADA)}"
  local salida="${SALIDA:-$(config_get FICHAR_SALIDA)}"
  local aleatorio="${ALEATORIO:-$(config_get FICHAR_ALEATORIO)}"
  [ -n "$entrada" ] && [ -n "$salida" ] || die "indica --entrada y --salida"
  aleatorio="${aleatorio:-0}"
  validate_schedule "$entrada" "$salida" "$aleatorio"
  config_set FICHAR_ENTRADA "$entrada"
  config_set FICHAR_SALIDA "$salida"
  config_set FICHAR_ALEATORIO "$aleatorio"
  if [ -n "$PROYECTO_SET" ] || ! config_has FICHAR_PROYECTO; then
    config_set FICHAR_PROYECTO "$PROYECTO"
  fi
  cmd_estado | grep -E '^(configuracion|entrada|salida|aleatorio|proyecto|fichero):'
}

cmd_fichar() {
  parse_options "$@"
  schedule_complete || die "falta la configuración del horario; ejecuta «$SCRIPT configurar --entrada H --salida H --aleatorio N»"
  is_int "$ANIO" && [ "$ANIO" -ge 2000 ] || die "indica --anio AAAA"
  is_int "$MES" && [ "$((10#$MES))" -ge 1 ] && [ "$((10#$MES))" -le 12 ] || die "indica --mes entre 1 y 12"
  local mes=$((10#$MES))
  [ $(( ANIO * 100 + mes )) -le "$(date +%Y%m)" ] || die "no se puede fichar un mes futuro"

  local entrada="${ENTRADA:-$(config_get FICHAR_ENTRADA)}"
  local salida="${SALIDA:-$(config_get FICHAR_SALIDA)}"
  local aleatorio="${ALEATORIO:-$(config_get FICHAR_ALEATORIO)}"
  local proyecto
  if [ -n "$PROYECTO_SET" ]; then
    proyecto="$PROYECTO"
  else
    proyecto="$(config_get FICHAR_PROYECTO)"
  fi
  validate_schedule "$entrada" "$salida" "$aleatorio"

  command -v node >/dev/null 2>&1 || die "hace falta Node.js 18 o superior"
  load_credentials

  local randomness="--randomness=0"
  [ "$aleatorio" -gt 0 ] && randomness="--randomness=-$aleatorio"
  local args=(fill-shifts --year "$ANIO" --month "$mes" --entryHour "$entrada" --exitHour "$salida" "$randomness")
  [ -n "$proyecto" ] && args+=(--project "$proyecto")

  printf 'Fichando %04d-%02d de %02d:00 a %02d:00' "$ANIO" "$mes" "$entrada" "$salida"
  [ "$aleatorio" -gt 0 ] && printf ', hasta %s min aleatorios dentro de la franja' "$aleatorio"
  [ -n "$proyecto" ] && printf ', proyecto «%s»' "$proyecto"
  printf '\n'

  case "$(runner)" in
    pnpm) pnpm --reporter=silent dlx "factorial-cli@$CLI_VERSION" "${args[@]}" ;;
    npx) npx --yes "factorial-cli@$CLI_VERSION" "${args[@]}" ;;
    *) die "hace falta pnpm o npm (npx)" ;;
  esac
}

main() {
  local cmd="${1:-}"
  [ $# -gt 0 ] && shift
  case "$cmd" in
    estado) cmd_estado ;;
    guardar-credenciales) cmd_guardar_credenciales "$@" ;;
    comprobar) cmd_comprobar ;;
    configurar) cmd_configurar "$@" ;;
    fichar) cmd_fichar "$@" ;;
    ""|-h|--help|ayuda) usage ;;
    *) usage >&2; exit 1 ;;
  esac
}

main "$@"
