#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="fichar-factorial"
SKILL_SRC="$REPO_DIR/skills/$SKILL_NAME"
FICHAR="$SKILL_SRC/scripts/fichar.sh"
SKILLS_DIR="$HOME/.claude/skills"
CONFIGURE=1

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Uso: ./install.sh [--dir DIRECTORIO] [--sin-configurar]

  --dir DIRECTORIO   Directorio de skills de tu agente (por defecto, ~/.claude/skills)
  --sin-configurar   Solo enlaza la skill; las credenciales y el horario se piden al usarla
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) SKILLS_DIR="${2:-}"; [ -n "$SKILLS_DIR" ] || die "falta el directorio"; shift 2 ;;
    --sin-configurar) CONFIGURE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

ask() {
  local prompt="$1" default="${2:-}" answer
  if [ -n "$default" ]; then
    read -r -p "$prompt [$default]: " answer
    printf '%s' "${answer:-$default}"
  else
    read -r -p "$prompt: " answer
    printf '%s' "$answer"
  fi
}

check_requirements() {
  if command -v node >/dev/null 2>&1; then
    local major
    major="$(node -p 'process.versions.node.split(".")[0]')"
    [ "$major" -ge 18 ] || echo "aviso: tienes Node.js $(node --version); hace falta la 18 o superior"
  else
    echo "aviso: no encuentro Node.js; instala la versión 18 o superior antes de fichar"
  fi
  if ! command -v pnpm >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
    echo "aviso: no encuentro pnpm ni npx; instala pnpm o npm antes de fichar"
  fi
}

link_skill() {
  local dest="$SKILLS_DIR/$SKILL_NAME"
  mkdir -p "$SKILLS_DIR"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup="$dest.bak-$(date +%Y%m%d%H%M%S)"
    [ -t 0 ] || die "ya existe $dest; bórralo o muévelo y vuelve a ejecutar el instalador"
    local reply
    reply="$(ask "Ya existe $dest. ¿Lo muevo a $backup y lo reemplazo? (s/n)" "s")"
    case "$reply" in
      s|S|si|sí|Si|Sí) mv "$dest" "$backup"; echo "Movido a $backup" ;;
      *) die "instalación cancelada" ;;
    esac
  fi
  ln -s "$SKILL_SRC" "$dest"
  echo "Skill enlazada en $dest"
}

state() {
  "$FICHAR" estado | sed -n "s/^$1: //p"
}

configure_credentials() {
  local source
  source="$(state credenciales)"
  if [ "$source" != "ninguna" ]; then
    echo "Credenciales encontradas ($source, cuenta $(state cuenta))."
    local reply
    reply="$(ask "¿Quieres cambiarlas? (s/n)" "n")"
    case "$reply" in s|S|si|sí) ;; *) return 0 ;; esac
  fi
  echo
  echo "¿Dónde guardo tu email y tu contraseña de Factorial?"
  echo "  1) Llavero de macOS (recomendado en Mac; no quedan en texto plano)"
  echo "  2) Variables en ~/.zshrc (la contraseña queda en texto plano)"
  echo "  3) Ya las tengo en zsh (FACTORIAL_USER_EMAIL y FACTORIAL_USER_PASSWORD)"
  local option
  option="$(ask "Opción" "$(command -v security >/dev/null 2>&1 && echo 1 || echo 2)")"
  case "$option" in
    1) "$FICHAR" guardar-credenciales llavero ;;
    2) "$FICHAR" guardar-credenciales zsh ;;
    3)
      [ "$(state credenciales)" != "ninguna" ] || die "no encuentro FACTORIAL_USER_EMAIL y FACTORIAL_USER_PASSWORD en tu entorno ni en ~/.zshrc"
      ;;
    *) die "opción no válida" ;;
  esac
}

configure_schedule() {
  if [ "$(state configuracion)" = "ok" ]; then
    echo "Horario actual: de $(state entrada) a $(state salida), aleatorio $(state aleatorio), proyecto «$(state proyecto)»."
    local reply
    reply="$(ask "¿Quieres cambiarlo? (s/n)" "n")"
    case "$reply" in s|S|si|sí) ;; *) return 0 ;; esac
  fi
  echo
  echo "Horario (horas en punto):"
  local entrada salida modo aleatorio=0 proyecto
  entrada="$(ask "Hora de entrada" "8")"
  salida="$(ask "Hora de salida" "$(( ${entrada:-8} + 8 ))")"
  echo "  1) Fijo: todos los días exactamente a esas horas"
  echo "  2) Aleatorio: cada día la entrada se retrasa y la salida se adelanta unos minutos al azar, sin salirse de la franja"
  modo="$(ask "Modo" "1")"
  if [ "$modo" = "2" ]; then
    aleatorio="$(ask "Minutos máximos de variación (1-59)" "10")"
  fi
  proyecto="$(ask "Proyecto de Factorial, con el nombre exacto (vacío si no usas proyectos)" "")"
  if [ -n "$proyecto" ]; then
    "$FICHAR" configurar --entrada "$entrada" --salida "$salida" --aleatorio "$aleatorio" --proyecto "$proyecto" >/dev/null
  else
    "$FICHAR" configurar --entrada "$entrada" --salida "$salida" --aleatorio "$aleatorio" --sin-proyecto >/dev/null
  fi
  echo "Horario guardado."
}

main() {
  [ -x "$FICHAR" ] || chmod +x "$FICHAR"
  check_requirements
  link_skill
  if [ "$CONFIGURE" -eq 0 ]; then
    echo "Listo. La skill te pedirá las credenciales y el horario la primera vez."
    return 0
  fi
  if [ ! -t 0 ]; then
    echo "Sin terminal interactiva: la skill te pedirá las credenciales y el horario la primera vez."
    return 0
  fi
  configure_credentials
  echo
  echo "Comprobando las credenciales en Factorial (no toca ningún fichaje)..."
  "$FICHAR" comprobar || die "revisa las credenciales y vuelve a ejecutar ./install.sh"
  configure_schedule
  echo
  "$FICHAR" estado | grep -vE '^(fichero|ejecutor|node):'
  echo
  echo "Listo. Pídele a tu agente «ficha este mes»."
}

main
