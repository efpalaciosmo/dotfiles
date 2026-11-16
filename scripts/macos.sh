#!/usr/bin/env bash
# Sourced by setup.sh; no application dotfiles or shell startup files are written.
preference_matches() {
  local domain=$1 key=$2 type=$3 expected=$4 current
  current=$(defaults read "$domain" "$key" 2>/dev/null) || return 1
  if [[ $type == bool ]]; then
    case $expected in
      true) expected=1 ;;
      false) expected=0 ;;
      *) die "Invalid boolean preference: $domain $key" ;;
    esac
  fi
  [[ $current == "$expected" ]]
}
apply_macos_preferences() {
  local entry domain key type value changed=0
  run mkdir -p "$SCREENSHOT_DIR" || die "Cannot create screenshot directory: $SCREENSHOT_DIR"
  for entry in "${MACOS_DEFAULTS[@]}"; do
    IFS='|' read -r domain key type value <<< "$entry"
    [[ $type == bool || $type == string ]] || die "Unsupported preference type: $type"
    if preference_matches "$domain" "$key" "$type" "$value"; then continue; fi
    run defaults write "$domain" "$key" "-$type" "$value" ||
      die "Failed to set macOS preference: $domain $key"
    changed=1
  done
  if ((changed)); then
    log 'Preferences selected. Log out/in to activate all changes; Finder and Dock were not restarted.'
  else
    log 'macOS preferences already match.'
  fi
}
check_macos_preferences() {
  local entry domain key type value failed=0
  for entry in "${MACOS_DEFAULTS[@]}"; do
    IFS='|' read -r domain key type value <<< "$entry"
    if ! preference_matches "$domain" "$key" "$type" "$value"; then
      log "MISS macOS preference: $domain $key (expected $value)"
      failed=1
    fi
  done
  if [[ ! -d $SCREENSHOT_DIR ]]; then
    log "MISS screenshot directory: $SCREENSHOT_DIR"; failed=1
  fi
  ((failed == 0))
}
