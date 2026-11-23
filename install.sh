#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="fichar-factorial"
SKILL_SRC="$REPO_DIR/skills/$SKILL_NAME"
SCRIPTS_DIR="$SKILL_SRC/scripts"
FICHAR="$SCRIPTS_DIR/fichar.sh"
SKILLS_DIR="$HOME/.claude/skills"
CONFIGURE=1

source "$SCRIPTS_DIR/ui.sh"

usage() {
  cat <<EOF
$(paint 1 "fichar-factorial · instalación")

Uso: ./install.sh [--dir DIRECTORIO] [--sin-configurar]

  --dir DIRECTORIO   Directorio de skills de tu agente (por defecto, ~/.claude/skills)
  --sin-configurar   Solo enlaza la skill; las credenciales y el horario se piden al usarla
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) SKILLS_DIR="${2:-}"; [ -n "$SKILLS_DIR" ] || die "Falta el directorio después de --dir"; shift 2 ;;
    --sin-configurar) CONFIGURE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Opción desconocida: $1" "Consulta las opciones con: ./install.sh --help" ;;
  esac
done

INTERACTIVE=0
[ "$CONFIGURE" -eq 1 ] && [ -t 0 ] && INTERACTIVE=1
TOTAL_STEPS=1
[ "$INTERACTIVE" -eq 1 ] && TOTAL_STEPS=4

state() {
  "$FICHAR" estado | sed -n "s/^$1: //p"
}

check_requirements() {
  if command -v node >/dev/null 2>&1; then
    local major
    major="$(node -p 'process.versions.node.split(".")[0]')"
    [ "$major" -ge 18 ] || warn "Tienes Node.js $(node --version); hace falta la 18 o superior para fichar"
  else
    warn "No encuentro Node.js; instala la versión 18 o superior antes de fichar"
  fi
  if ! command -v pnpm >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
    warn "No encuentro pnpm ni npx; instala pnpm o npm antes de fichar"
  fi
}

link_skill() {
  section "[1/$TOTAL_STEPS] Skill"
  local UI_INDENT="  "
  local dest="$SKILLS_DIR/$SKILL_NAME"
  local backup_dir
  backup_dir="$(dirname "$SKILLS_DIR")/backups"
  mkdir -p "$SKILLS_DIR"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    [ -t 0 ] || die "Ya existe $(tilde "$dest")" "Muévelo o bórralo y vuelve a ejecutar el instalador."
    local backup="$backup_dir/$SKILL_NAME-$(date +%Y%m%d-%H%M%S)"
    warn "Ya existe $(tilde "$dest")"
    confirm "¿Lo muevo a $(tilde "$backup") y lo reemplazo?" s || die "Instalación cancelada"
    mkdir -p "$backup_dir"
    mv "$dest" "$backup"
  fi
  ln -s "$SKILL_SRC" "$dest"
  ok "Enlazada en $(tilde "$dest")"
  [ -n "${backup:-}" ] && step "Copia anterior movida a $(tilde "$backup")"
  return 0
}

configure_credentials() {
  section "[2/4] Credenciales"
  local UI_INDENT="  "
  local source
  source="$(state credenciales)"
  if [ "$source" != "ninguna" ]; then
    local where="el llavero"
    [ "$source" = "zsh" ] && where="zsh"
    ok "Encontradas en $where · $(state cuenta)"
    confirm "¿Quieres cambiarlas?" n || return 0
  fi
  local default_option=2
  command -v security >/dev/null 2>&1 && default_option=1
  printf '%s%s\n' "$UI_INDENT" "¿Dónde guardo tu email y tu contraseña de Factorial?"
  printf '%s  1) Llavero de macOS   %s\n' "$UI_INDENT" "$(paint 2 "recomendado en Mac; no quedan en texto plano")"
  printf '%s  2) ~/.zshrc           %s\n' "$UI_INDENT" "$(paint 2 "la contraseña queda en texto plano")"
  printf '%s  3) Ya las tengo en zsh %s\n' "$UI_INDENT" "$(paint 2 "FACTORIAL_USER_EMAIL y FACTORIAL_USER_PASSWORD")"
  local option
  option="$(ask "Opción" "$default_option")"
  case "$option" in
    1) FICHAR_INDENT="$UI_INDENT" "$FICHAR" guardar-credenciales llavero ;;
    2) FICHAR_INDENT="$UI_INDENT" "$FICHAR" guardar-credenciales zsh ;;
    3)
      [ "$(state credenciales)" != "ninguna" ] \
        || die "No encuentro FACTORIAL_USER_EMAIL y FACTORIAL_USER_PASSWORD" "Ni en tu entorno ni en ~/.zshrc."
      ok "Encontradas en zsh · $(state cuenta)"
      ;;
    *) die "Opción no válida: $option" ;;
  esac
}

check_credentials() {
  section "[3/4] Comprobación"
  local UI_INDENT="  "
  FICHAR_INDENT="$UI_INDENT" "$FICHAR" comprobar || die "Revisa las credenciales y vuelve a ejecutar ./install.sh"
  hint "Solo se ha hecho login; no se ha tocado ningún fichaje."
}

configure_schedule() {
  section "[4/4] Horario"
  local UI_INDENT="  "
  if [ "$(state configuracion)" = "ok" ]; then
    local project
    project="$(state proyecto)"
    ok "Configurado · $(state horario) · ${project:-sin proyecto}"
    confirm "¿Quieres cambiarlo?" n || return 0
  fi
  hint "Horas en punto (7, 8, 9…)."
  local entrada salida modo aleatorio=0 proyecto
  entrada="$(ask "Hora de entrada" "8")"
  salida="$(ask "Hora de salida" "$(( ${entrada:-8} + 8 ))")"
  printf '%s  1) Fijo        %s\n' "$UI_INDENT" "$(paint 2 "todos los días exactamente a esas horas")"
  printf '%s  2) Aleatorio   %s\n' "$UI_INDENT" "$(paint 2 "la entrada se retrasa y la salida se adelanta unos minutos, sin salirse de la franja")"
  modo="$(ask "Modo" "1")"
  if [ "$modo" = "2" ]; then
    aleatorio="$(ask "Minutos máximos de variación (1-59)" "10")"
  fi
  proyecto="$(ask "Proyecto de Factorial, con el nombre exacto (vacío si no usas proyectos)" "")"
  if [ -n "$proyecto" ]; then
    FICHAR_INDENT="$UI_INDENT" "$FICHAR" configurar --entrada "$entrada" --salida "$salida" --aleatorio "$aleatorio" --proyecto "$proyecto"
  else
    FICHAR_INDENT="$UI_INDENT" "$FICHAR" configurar --entrada "$entrada" --salida "$salida" --aleatorio "$aleatorio" --sin-proyecto
  fi
}

summary() {
  section "Resumen"
  local project source
  project="$(state proyecto)"
  source="$(state credenciales)"
  printf '  %-11s %s %s\n' "Cuenta" "$(state cuenta)" "$(paint 2 "($source)")"
  printf '  %-11s %s\n' "Horario" "$(state horario)"
  printf '  %-11s %s\n' "Proyecto" "${project:-ninguno}"
  echo
  ok "Listo. Pídele a tu agente «ficha este mes»."
  echo
}

main() {
  [ -x "$FICHAR" ] || chmod +x "$FICHAR"
  title "instalación"
  check_requirements
  link_skill
  if [ "$INTERACTIVE" -eq 0 ]; then
    echo
    ok "Listo. La skill te pedirá las credenciales y el horario la primera vez que la uses."
    echo
    return 0
  fi
  configure_credentials
  check_credentials
  configure_schedule
  summary
}

main
