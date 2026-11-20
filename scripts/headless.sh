#!/usr/bin/env sh
# Wrapper headless: dung bien GODOT (mac dinh `godot` trong PATH).
# Godot doi cwd ve thu muc project (--path), nen doi duong dan tuong doi
# cua --scenario/--inputs/--out thanh tuyet doi (theo cwd cua nguoi goi) truoc.
GODOT="${GODOT:-godot}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CWD="$(pwd)"
abs() {
  case "$1" in
    /*|[A-Za-z]:[\/]*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$CWD" "$1" ;;
  esac
}
n=$#
i=0
while [ "$i" -lt "$n" ]; do
  a="$1"; shift; i=$((i+1))
  case "$a" in
    --scenario|--inputs|--out)
      if [ "$i" -lt "$n" ]; then
        v="$1"; shift; i=$((i+1))
        set -- "$@" "$a" "$(abs "$v")"
      else
        set -- "$@" "$a"
      fi ;;
    --scenario=*|--inputs=*|--out=*)
      set -- "$@" "${a%%=*}=$(abs "${a#*=}")" ;;
    *) set -- "$@" "$a" ;;
  esac
done
exec "$GODOT" --headless --path "$HERE/../godot" --script res://src/adapters/headless/headless_runner.gd -- "$@"
