#!/bin/bash

set -eu

CONFIG_DIR="${HOME}/.config/kvim"
SHARE_DIR="${HOME}/.local/share/kvim"
BIN_DIR="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
ICON_FILE="${ICON_DIR}/kvim.png"
STATE_FILE="${SHARE_DIR}/install-state"
LAUNCHER_FILE="${BIN_DIR}/kvim"
DESKTOP_FILE="${APPLICATIONS_DIR}/kvim.desktop"
LAZYSVN_FILE="${BIN_DIR}/lazysvn"

NON_INTERACTIVE="false"
PURGE="false"
REMOVE_PATH="false"
REMOVE_LAZYSVN="false"
HAS_STATE="false"
PATH_UPDATED="false"
PATH_RC_FILE=""
INSTALLED_LAZYGIT="false"
INSTALLED_LAZYSVN="false"

usage() {
    cat <<EOF
KVIM Linux uninstaller

Usage:
  $(basename "$0") [options]

Options:
  --yes             Run without confirmation prompts
  --purge           Remove ~/.config/kvim as well
  --remove-path     Remove PATH block added by KVIM installer
  --remove-lazysvn  Remove ~/.local/bin/lazysvn if managed by KVIM or present
  -h, --help        Show this help
EOF
}

log() {
    printf '[kvim-uninstall] %s\n' "$1"
}

warn() {
    printf '[kvim-uninstall][warn] %s\n' "$1"
}

fail() {
    printf '[kvim-uninstall][error] %s\n' "$1" >&2
    exit 1
}

ask_yes_no() {
    prompt="$1"
    default_value="${2:-false}"

    if [ "$NON_INTERACTIVE" = "true" ] || [ ! -t 0 ]; then
        printf '%s' "$default_value"
        return 0
    fi

    while true; do
        printf '%s [y/N] ' "$prompt" >&2
        IFS= read -r answer

        case "$answer" in
            "")
                printf '%s' "$default_value"
                return 0
                ;;
            y|Y|yes|YES)
                printf 'true'
                return 0
                ;;
            n|N|no|NO)
                printf 'false'
                return 0
                ;;
        esac

        printf 'Please answer yes(y) or no(N).\n' >&2
    done
}

get_shell_rc_file() {
    shell_name="$(basename "${SHELL:-}")"

    case "$shell_name" in
        zsh)
            printf '%s' "${HOME}/.zshrc"
            ;;
        bash)
            printf '%s' "${HOME}/.bashrc"
            ;;
        fish)
            printf '%s' "${HOME}/.config/fish/config.fish"
            ;;
        *)
            printf '%s' "${HOME}/.profile"
            ;;
    esac
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --yes)
                NON_INTERACTIVE="true"
                ;;
            --purge)
                PURGE="true"
                ;;
            --remove-path)
                REMOVE_PATH="true"
                ;;
            --remove-lazysvn)
                REMOVE_LAZYSVN="true"
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf 'Unknown option: %s\n\n' "$1" >&2
                usage >&2
                exit 1
                ;;
        esac
        shift
    done
}

load_install_state() {
    if [ ! -f "$STATE_FILE" ]; then
        warn "Install state not found; running in best-effort mode"
        PATH_RC_FILE="$(get_shell_rc_file)"
        return 0
    fi

    # shellcheck disable=SC1090
    . "$STATE_FILE"
    HAS_STATE="true"

    if [ -z "$PATH_RC_FILE" ]; then
        PATH_RC_FILE="$(get_shell_rc_file)"
    fi
}

print_uninstall_plan() {
    cat <<EOF

KVIM uninstall plan:
  Will remove:
    - ${LAUNCHER_FILE}
    - ${DESKTOP_FILE}
    - ${SHARE_DIR}
    - ${CONFIG_DIR}
    - ${ICON_FILE}

  Conditional removal:
    - ${LAZYSVN_FILE} (if installed by KVIM or with --remove-lazysvn)
    - PATH block in ${PATH_RC_FILE:-<auto-detected>} (if managed by KVIM or with --remove-path)
    - lazygit via pacman (if installed by KVIM)
EOF
}

remove_file_if_exists() {
    target="$1"

    if [ -f "$target" ]; then
        rm -f "$target"
        log "Removed ${target}"
    else
        log "Already absent: ${target}"
    fi
}

remove_dir_if_exists() {
    target="$1"

    if [ -d "$target" ]; then
        rm -rf "$target"
        log "Removed ${target}"
    else
        log "Already absent: ${target}"
    fi
}

remove_launcher() {
    remove_file_if_exists "$LAUNCHER_FILE"
}

remove_desktop_entry() {
    remove_file_if_exists "$DESKTOP_FILE"
}

remove_icon_file() {
    remove_file_if_exists "$ICON_FILE"
}

remove_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        log "Already absent: ${CONFIG_DIR}"
        return 0
    fi

    remove_dir_if_exists "$CONFIG_DIR"
}

remove_lazygit_if_managed() {
    if [ "$HAS_STATE" != "true" ] || [ "$INSTALLED_LAZYGIT" != "true" ]; then
        log "Keeping lazygit (not marked as installed by KVIM)"
        return 0
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        warn "Cannot remove lazygit automatically: pacman not found"
        return 0
    fi

    if [ "$NON_INTERACTIVE" = "true" ]; then
        sudo pacman -R --noconfirm lazygit
    else
        sudo pacman -R lazygit
    fi

    log "Removed lazygit via pacman"
}

remove_lazysvn_if_managed() {
    if [ "$REMOVE_LAZYSVN" != "true" ] && [ "$INSTALLED_LAZYSVN" != "true" ] && [ "$PURGE" != "true" ]; then
        return 0
    fi

    if [ ! -f "$LAZYSVN_FILE" ]; then
        log "Already absent: ${LAZYSVN_FILE}"
        return 0
    fi

    rm -f "$LAZYSVN_FILE"
    log "Removed ${LAZYSVN_FILE}"
}

path_block_present() {
    rc_file="$1"

    if [ ! -f "$rc_file" ]; then
        return 1
    fi

    grep -Fq '# Added by KVIM installer' "$rc_file"
}

remove_path_block() {
    rc_file="$1"
    temp_file=""

    if [ -z "$rc_file" ] || [ ! -f "$rc_file" ]; then
        log "No shell rc file to update"
        return 0
    fi

    if ! path_block_present "$rc_file"; then
        log "No KVIM PATH block found in ${rc_file}"
        return 0
    fi

    temp_file="$(mktemp)"

    awk '
        skip_next == 1 { skip_next = 0; next }
        $0 == "# Added by KVIM installer" { skip_next = 1; next }
        { print }
    ' "$rc_file" > "$temp_file"

    mv "$temp_file" "$rc_file"
    log "Removed KVIM PATH block from ${rc_file}"
}

handle_path_cleanup() {
    if [ "$REMOVE_PATH" != "true" ] && [ "$PATH_UPDATED" != "true" ]; then
        return 0
    fi

    if [ "$REMOVE_PATH" = "true" ] || [ "$PATH_UPDATED" = "true" ]; then
        remove_path_block "$PATH_RC_FILE"
        return 0
    fi
}

remove_share_dir() {
    remove_dir_if_exists "$SHARE_DIR"
}

print_uninstall_summary() {
    cat <<EOF

KVIM uninstall completed.

Notes:
  - managed KVIM artifacts were removed using install-state when available
  - open a new shell or reload your rc file if PATH was changed
EOF
}

main() {
    parse_args "$@"
    load_install_state
    print_uninstall_plan

    if [ "$NON_INTERACTIVE" != "true" ]; then
        proceed="$(ask_yes_no "Continue with KVIM uninstall?" "true")"
        if [ "$proceed" != "true" ]; then
            log "Uninstall cancelled"
            exit 0
        fi
    fi

    remove_launcher
    remove_desktop_entry
    remove_icon_file
    remove_config_dir
    remove_lazygit_if_managed
    remove_lazysvn_if_managed
    handle_path_cleanup
    remove_share_dir
    print_uninstall_summary
}

main "$@"
