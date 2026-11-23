if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  UI_COLOR=1
else
  UI_COLOR=0
fi
UI_INDENT="${FICHAR_INDENT:-}"

paint() {
  if [ "$UI_COLOR" -eq 1 ]; then
    printf '\033[%sm%s\033[0m' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}

tilde() {
  printf '%s' "${1/#$HOME/~}"
}

title() {
  printf '\n%s\n' "$(paint 1 "fichar-factorial · $1")"
}

section() {
  printf '\n%s\n' "$(paint 1 "$1")"
}

ok() {
  printf '%s%s %s\n' "$UI_INDENT" "$(paint 32 "✔")" "$*"
}

warn() {
  printf '%s%s %s\n' "$UI_INDENT" "$(paint 33 "!")" "$*"
}

step() {
  printf '%s%s %s\n' "$UI_INDENT" "$(paint 36 "›")" "$*"
}

hint() {
  printf '%s  %s\n' "$UI_INDENT" "$(paint 2 "$*")"
}

fail() {
  printf '%s%s %s\n' "$UI_INDENT" "$(paint 31 "✖")" "$*" >&2
}

die() {
  fail "$1"
  shift
  local line
  for line in "$@"; do
    hint "$line" >&2
  done
  exit 1
}

row() {
  local symbol=" "
  case "$2" in
    ok) symbol="$(paint 32 "✔")" ;;
    fail) symbol="$(paint 31 "✖")" ;;
    warn) symbol="$(paint 33 "!")" ;;
  esac
  printf '%s  %-13s %s %s\n' "$UI_INDENT" "$1" "$symbol" "$3"
}

prompt_label() {
  printf '%s%s %s' "$UI_INDENT" "$(paint 36 "?")" "$1"
}

ask() {
  local question="$1" default="${2:-}" answer suffix=""
  [ -n "$default" ] && suffix=" [$default]"
  read -r -p "$(prompt_label "$question$suffix"): " answer
  printf '%s' "${answer:-$default}"
}

confirm() {
  local question="$1" default="$2" options reply
  if [ "$default" = "s" ]; then options="S/n"; else options="s/N"; fi
  read -r -p "$(prompt_label "$question") ($options) " reply
  reply="${reply:-$default}"
  case "$reply" in
    s|S|si|sí|Si|Sí|SI|SÍ) return 0 ;;
    *) return 1 ;;
  esac
}

schedule_text() {
  local text
  text="$(printf '%02d:00 – %02d:00 · ' "$1" "$2")"
  if [ "$3" -gt 0 ]; then
    printf '%saleatorio, hasta %s min dentro de la franja' "$text" "$3"
  else
    printf '%sfijo' "$text"
  fi
}
