# shellcheck shell=bash
# Sourced by the hooks. The denylist lives outside this repo so the terms
# themselves stay private; bootstrap.sh creates it.
denylist="${XDG_CONFIG_HOME:-$HOME/.config}/public-repo-denylist"

# Fails when stdin contains a denylisted term. $1 names what was checked.
denylist_check() {
  local terms hits
  terms=$(grep -vE '^[[:space:]]*(#|$)' "$denylist" 2>/dev/null || true)
  if [[ -z $terms ]]; then
    echo "warning: $denylist is missing or empty; internal names are not checked" >&2
    cat >/dev/null
    return 0
  fi
  hits=$(grep -iFo -f <(printf '%s\n' "$terms") | sort -fu | tr '\n' ' ' || true)
  if [[ -n $hits ]]; then
    echo "blocked: $1 contains denylisted term(s): $hits" >&2
    return 1
  fi
}
