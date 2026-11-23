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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

source "$SCRIPT_DIR/ui.sh"

usage() {
  cat <<EOF
$(paint 1 "fichar-factorial")

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

credentials_account() {
  case "$1" in
    llavero) keychain_account ;;
    zsh) load_zsh_env && printf '%s' "$FACTORIAL_USER_EMAIL" ;;
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
      die "No hay credenciales guardadas" \
        "Guárdalas desde tu terminal con uno de estos comandos:" \
        "$SCRIPT guardar-credenciales llavero" \
        "$SCRIPT guardar-credenciales zsh"
      ;;
  esac
  [ -n "${FACTORIAL_USER_EMAIL:-}" ] && [ -n "${FACTORIAL_USER_PASSWORD:-}" ] || die "Las credenciales guardadas están incompletas"
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
  local source account
  source="$(credentials_source)"
  account="$(credentials_account "$source" || true)"

  if [ ! -t 1 ]; then
    echo "credenciales: $source"
    [ -n "$account" ] && echo "cuenta: $account"
    if schedule_complete; then
      echo "configuracion: ok"
      echo "entrada: $(config_get FICHAR_ENTRADA)"
      echo "salida: $(config_get FICHAR_SALIDA)"
      echo "aleatorio: $(config_get FICHAR_ALEATORIO)"
      echo "proyecto: $(config_get FICHAR_PROYECTO)"
      echo "horario: $(schedule_text "$(config_get FICHAR_ENTRADA)" "$(config_get FICHAR_SALIDA)" "$(config_get FICHAR_ALEATORIO)")"
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
    return 0
  fi

  title "estado"
  echo
  if [ "$source" = "ninguna" ]; then
    row "Credenciales" fail "sin guardar"
  else
    row "Credenciales" ok "$source · $account"
  fi
  if schedule_complete; then
    local project
    project="$(config_get FICHAR_PROYECTO)"
    row "Horario" ok "$(schedule_text "$(config_get FICHAR_ENTRADA)" "$(config_get FICHAR_SALIDA)" "$(config_get FICHAR_ALEATORIO)")"
    row "Proyecto" "" "${project:-ninguno}"
  else
    row "Horario" fail "sin configurar"
  fi
  if command -v node >/dev/null 2>&1; then
    row "Node" ok "$(node --version)"
  else
    row "Node" fail "no instalado (hace falta la 18 o superior)"
  fi
  if [ "$(runner)" = "ninguno" ]; then
    row "Ejecutor" fail "no hay pnpm ni npx"
  else
    row "Ejecutor" ok "$(runner)"
  fi
  row "Config" "" "$(tilde "$CONFIG_FILE")"
  echo
}

require_tty() {
  [ -t 0 ] || die "Este comando pide la contraseña" "Ejecútalo tú en una terminal, no desde el agente."
}

cmd_guardar_credenciales() {
  local target="${1:-}"
  local email password
  case "$target" in
    llavero)
      has_keychain || die "El llavero solo está disponible en macOS" "Usa: $SCRIPT guardar-credenciales zsh"
      require_tty
      email="$(ask "Email de Factorial")"
      [ -n "$email" ] || die "El email no puede estar vacío"
      while security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1; do :; done
      step "Escribe tu contraseña de Factorial dos veces (no se verá)"
      security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$email" -w
      config_set FICHAR_CREDENCIALES llavero
      ok "Guardadas en el llavero · $email"
      ;;
    zsh)
      require_tty
      email="$(ask "Email de Factorial")"
      read -r -s -p "$(prompt_label "Contraseña de Factorial (no se verá)"): " password
      echo
      [ -n "$email" ] && [ -n "$password" ] || die "El email y la contraseña no pueden estar vacíos"
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
      ok "Guardadas en $(tilde "$ZSHRC") · $email"
      hint "Abre una terminal nueva para que las coja tu shell."
      ;;
    *)
      die "Indica dónde guardarlas: llavero o zsh"
      ;;
  esac
}

cmd_comprobar() {
  command -v node >/dev/null 2>&1 || die "Hace falta Node.js 18 o superior"
  load_credentials
  local result
  result="$(node --input-type=module -e '
try {
  const res = await fetch(process.argv[1], {
    method: "POST",
    headers: { "content-type": "application/json", accept: "application/json" },
    body: JSON.stringify({ email: process.env.FACTORIAL_USER_EMAIL, password: process.env.FACTORIAL_USER_PASSWORD }),
  });
  let body;
  try { body = await res.json(); } catch { body = undefined; }
  const session = res.headers.getSetCookie().some((c) => c.startsWith("_factorial_id="));
  if (res.ok && body?.success && session) console.log("ok");
  else if (body?.error?.code === "invalid_credentials" || (res.ok && body && !body.success)) console.log("invalid");
  else if (res.status === 403 && !body) console.log("waf");
  else console.log(`unexpected:${res.status}`);
} catch {
  console.log("network");
}
' "$LOGIN_URL" 2>/dev/null || true)"
  case "$result" in
    ok)
      ok "Credenciales válidas"
      ;;
    invalid)
      die "Email o contraseña incorrectos" \
        "Vuelve a guardarlas con: $SCRIPT guardar-credenciales llavero (o zsh)"
      ;;
    waf)
      die "El cortafuegos de Factorial ha bloqueado el login (HTTP 403)" \
        "Suele pasar con contraseñas con \$ o comillas, o tras muchos intentos. Prueba más tarde o cambia la contraseña."
      ;;
    network)
      die "No se ha podido conectar con Factorial" "Revisa tu conexión a internet."
      ;;
    *)
      die "Factorial ha respondido de forma inesperada (HTTP ${result#unexpected:})" \
        "Puede que tu cuenta use solo Google o la verificación en dos pasos."
      ;;
  esac
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
      *) die "Opción desconocida: $1" "Consulta las opciones con: $SCRIPT --help" ;;
    esac
  done
}

validate_schedule() {
  is_int "$1" && [ "$1" -ge 0 ] && [ "$1" -le 23 ] || die "La entrada tiene que ser una hora en punto entre 0 y 23"
  is_int "$2" && [ "$2" -ge 1 ] && [ "$2" -le 24 ] || die "La salida tiene que ser una hora en punto entre 1 y 24"
  [ "$2" -gt "$1" ] || die "La salida tiene que ser posterior a la entrada"
  is_int "$3" && [ "$3" -le 59 ] || die "El aleatorio tiene que ser 0 (fijo) o un número de minutos entre 1 y 59"
  [ $(( ($2 - $1) * 60 )) -gt $(( $3 * 2 )) ] || die "El aleatorio es demasiado grande para esa franja"
}

cmd_configurar() {
  parse_options "$@"
  local entrada="${ENTRADA:-$(config_get FICHAR_ENTRADA)}"
  local salida="${SALIDA:-$(config_get FICHAR_SALIDA)}"
  local aleatorio="${ALEATORIO:-$(config_get FICHAR_ALEATORIO)}"
  [ -n "$entrada" ] && [ -n "$salida" ] || die "Indica --entrada y --salida"
  aleatorio="${aleatorio:-0}"
  validate_schedule "$entrada" "$salida" "$aleatorio"
  config_set FICHAR_ENTRADA "$entrada"
  config_set FICHAR_SALIDA "$salida"
  config_set FICHAR_ALEATORIO "$aleatorio"
  if [ -n "$PROYECTO_SET" ] || ! config_has FICHAR_PROYECTO; then
    config_set FICHAR_PROYECTO "$PROYECTO"
  fi
  local project
  project="$(config_get FICHAR_PROYECTO)"
  ok "Horario guardado · $(schedule_text "$entrada" "$salida" "$aleatorio") · ${project:-sin proyecto}"
}

run_cli() {
  case "$(runner)" in
    pnpm) pnpm --reporter=silent dlx "factorial-cli@$CLI_VERSION" "$@" ;;
    npx) npx --yes "factorial-cli@$CLI_VERSION" "$@" ;;
  esac
}

cmd_fichar() {
  parse_options "$@"
  schedule_complete || die "Falta la configuración del horario" "Guárdala con: $SCRIPT configurar --entrada H --salida H --aleatorio N"
  is_int "$ANIO" && [ "$ANIO" -ge 2000 ] || die "Indica el año con --anio AAAA"
  is_int "$MES" && [ "$((10#$MES))" -ge 1 ] && [ "$((10#$MES))" -le 12 ] || die "Indica el mes con --mes, entre 1 y 12"
  local mes=$((10#$MES))
  [ $(( ANIO * 100 + mes )) -le "$(date +%Y%m)" ] || die "No se puede fichar un mes futuro"

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

  command -v node >/dev/null 2>&1 || die "Hace falta Node.js 18 o superior"
  [ "$(runner)" != "ninguno" ] || die "Hace falta pnpm o npm (npx)"
  load_credentials

  local randomness="--randomness=0"
  [ "$aleatorio" -gt 0 ] && randomness="--randomness=-$aleatorio"
  local args=(fill-shifts --year "$ANIO" --month "$mes" --entryHour "$entrada" --exitHour "$salida" "$randomness")
  [ -n "$proyecto" ] && args+=(--project "$proyecto")

  { run_cli "${args[@]}" 2>&1 && echo "__EXIT__:0" || echo "__EXIT__:$?"; } \
    | node "$SCRIPT_DIR/salida.mjs" "$ANIO" "$mes" "$entrada" "$salida" "$aleatorio" "$proyecto" "$UI_COLOR"
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
