#!/bin/bash

set -eu

SCRIPT_DIR="$(dirname "$0")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_DIR="${HOME}/.config/kvim"
SHARE_DIR="${HOME}/.local/share/kvim"
BIN_DIR="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
LOCAL_CONFIG_FILE="${CONFIG_DIR}/lua/kvim/local.lua"
LAUNCHER_FILE="${BIN_DIR}/kvim"
DESKTOP_FILE="${APPLICATIONS_DIR}/kvim.desktop"
MIN_NVIM_VERSION="0.10.0"
LAZYSVN_REPO_API="https://api.github.com/repos/sawirricardo/lazysvn/releases/latest"

ENABLE_WORKSPACES="true"
ENABLE_GIT="false"
ENABLE_SVN="false"
ENABLE_CONNECTIONS="false"
NON_INTERACTIVE="false"
INSTALL_OPTIONAL_DEPS="false"
WARNING_COUNT=0

usage() {
    cat <<EOF
KVIM Linux installer

Usage:
  $(basename "$0") [options]

Options:
  --yes                  Use default module selection without prompts
  --enable-workspaces    Enable workspaces module
  --disable-workspaces   Disable workspaces module
  --enable-git           Enable git module
  --disable-git          Disable git module
  --enable-svn           Enable svn module
  --disable-svn          Disable svn module
  --enable-connections   Enable connections module
  --disable-connections  Disable connections module
  --install-optional-deps Install supported optional dependencies on Arch Linux
  -h, --help             Show this help
EOF
}

log() {
    printf '[kvim-installer] %s\n' "$1"
}

warn() {
    WARNING_COUNT=$((WARNING_COUNT + 1))
    printf '[kvim-installer][warn] %s\n' "$1"
}

fail() {
    printf '[kvim-installer][error] %s\n' "$1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

version_gte() {
    current_version="$1"
    required_version="$2"
    lowest_version="$(printf '%s\n%s\n' "$required_version" "$current_version" | sort -V | head -n 1)"
    [ "$lowest_version" = "$required_version" ]
}

get_nvim_version() {
    nvim --version 2>/dev/null | awk 'NR == 1 { gsub(/^v/, "", $2); print $2 }'
}

get_os_id() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        printf '%s' "${ID:-unknown}"
        return 0
    fi

    printf 'unknown'
}

get_uname_arch() {
    uname -m
}

get_lazysvn_arch() {
    case "$(get_uname_arch)" in
        x86_64)
            printf 'amd64'
            ;;
        aarch64|arm64)
            printf 'arm64'
            ;;
        *)
            return 1
            ;;
    esac
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

get_path_export_line() {
    shell_name="$(basename "${SHELL:-}")"

    case "$shell_name" in
        fish)
            printf '%s' 'set -gx PATH "$HOME/.local/bin" $PATH'
            ;;
        *)
            printf '%s' 'export PATH="$HOME/.local/bin:$PATH"'
            ;;
    esac
}

path_contains_local_bin() {
    case ":${PATH}:" in
        *":${HOME}/.local/bin:"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

append_local_bin_to_path() {
    rc_file="$1"
    path_export_line="$(get_path_export_line)"

    mkdir -p "$(dirname "$rc_file")"

    if [ -f "$rc_file" ] && grep -Fq "$path_export_line" "$rc_file"; then
        log "PATH export already present in ${rc_file}"
        return 0
    fi

    printf '\n# Added by KVIM installer\n%s\n' "$path_export_line" >> "$rc_file"
    log "Added ~/.local/bin to PATH in ${rc_file}"
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --yes)
                NON_INTERACTIVE="true"
                ;;
            --enable-workspaces)
                ENABLE_WORKSPACES="true"
                ;;
            --disable-workspaces)
                ENABLE_WORKSPACES="false"
                ;;
            --enable-git)
                ENABLE_GIT="true"
                ;;
            --disable-git)
                ENABLE_GIT="false"
                ;;
            --enable-svn)
                ENABLE_SVN="true"
                ;;
            --disable-svn)
                ENABLE_SVN="false"
                ;;
            --enable-connections)
                ENABLE_CONNECTIONS="true"
                ;;
            --disable-connections)
                ENABLE_CONNECTIONS="false"
                ;;
            --install-optional-deps)
                INSTALL_OPTIONAL_DEPS="true"
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

ask_yes_no() {
    prompt="$1"
    default_value="$2"

    if [ "$NON_INTERACTIVE" = "true" ] || [ ! -t 0 ]; then
        printf '%s' "$default_value"
        return 0
    fi

    while true; do
        if [ "$default_value" = "true" ]; then
            suffix="[Y/n]"
        else
            suffix="[y/N]"
        fi

        printf '%s %s ' "$prompt" "$suffix" >&2
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

        printf 'Please answer yes or no.\n' >&2
    done
}

select_modules() {
    log "Configuring module selection"

    ENABLE_WORKSPACES="$(ask_yes_no "Enable workspaces module?" "$ENABLE_WORKSPACES")"
    ENABLE_GIT="$(ask_yes_no "Enable git module?" "$ENABLE_GIT")"
    ENABLE_SVN="$(ask_yes_no "Enable svn module?" "$ENABLE_SVN")"
    ENABLE_CONNECTIONS="$(ask_yes_no "Enable connections module?" "$ENABLE_CONNECTIONS")"
}

check_required_dependency() {
    dependency_name="$1"

    if ! command_exists "$dependency_name"; then
        fail "Required dependency not found: ${dependency_name}"
    fi

    log "Found required dependency: ${dependency_name}"
}

check_optional_dependency() {
    dependency_name="$1"
    reason="$2"

    if command_exists "$dependency_name"; then
        log "Found optional dependency: ${dependency_name}"
        return 0
    fi

    warn "Optional dependency missing: ${dependency_name} (${reason})"
}

check_nvim_version() {
    current_version="$(get_nvim_version)"

    if [ -z "$current_version" ]; then
        fail "Could not determine Neovim version"
    fi

    if ! version_gte "$current_version" "$MIN_NVIM_VERSION"; then
        fail "Neovim ${MIN_NVIM_VERSION}+ is required, found ${current_version}"
    fi

    log "Neovim version OK: ${current_version}"
}

check_lazy_bootstrap() {
    log "lazy.nvim will be bootstrapped automatically on first start"
}

check_dependencies() {
    log "Checking required and optional dependencies"

    check_required_dependency "nvim"
    check_nvim_version
    check_required_dependency "git"

    check_optional_dependency "neovide" "recommended GUI launcher for KVIM"
    check_lazy_bootstrap

    if [ "$ENABLE_GIT" = "true" ]; then
        check_optional_dependency "lazygit" "required for KVIM git module commands"
    fi

    if [ "$ENABLE_SVN" = "true" ]; then
        check_optional_dependency "svn" "required for KVIM svn module commands"
        check_optional_dependency "lazysvn" "required for KVIM LazySVN command"
    fi

    if [ "$ENABLE_CONNECTIONS" = "true" ]; then
        check_optional_dependency "ssh" "required for KVIM connections SSH actions"
        check_optional_dependency "scp" "required for KVIM connections transfers"
        check_optional_dependency "ssh-keygen" "required for KVIM SSH key generation"
        check_optional_dependency "ssh-copy-id" "required for KVIM SSH key installation"
        check_optional_dependency "picocom" "default serial command for KVIM connections"
    fi
}

check_required_runtime_for_optional_install() {
    dependency_name="$1"

    if ! command_exists "$dependency_name"; then
        fail "Cannot install optional dependencies: missing required tool '${dependency_name}'"
    fi
}

install_lazygit_arch() {
    if command_exists "lazygit"; then
        log "lazygit already installed"
        return 0
    fi

    log "Installing lazygit with pacman"
    sudo pacman -S --needed lazygit
}

get_lazysvn_latest_tag() {
    curl -fsSL "$LAZYSVN_REPO_API" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1
}

install_lazysvn_release() {
    if command_exists "lazysvn"; then
        log "lazysvn already installed"
        return 0
    fi

    lazysvn_arch="$(get_lazysvn_arch)" || fail "Unsupported architecture for LazySVN binary release: $(get_uname_arch)"
    lazysvn_tag="$(get_lazysvn_latest_tag)"

    if [ -z "$lazysvn_tag" ]; then
        fail "Could not resolve latest LazySVN release tag"
    fi

    lazysvn_version="${lazysvn_tag#v}"
    lazysvn_asset="lazysvn_${lazysvn_version}_linux_${lazysvn_arch}.tar.gz"
    lazysvn_url="https://github.com/sawirricardo/lazysvn/releases/download/${lazysvn_tag}/${lazysvn_asset}"
    temp_dir="$(mktemp -d)"
    archive_path="${temp_dir}/${lazysvn_asset}"
    bin_path=""

    trap 'rm -rf "$temp_dir"' RETURN

    log "Downloading LazySVN release ${lazysvn_tag}"
    curl -fsSL "$lazysvn_url" -o "$archive_path"
    tar -xzf "$archive_path" -C "$temp_dir"
    bin_path="$(find "$temp_dir" -type f -name lazysvn | head -n 1 || true)"

    if [ -z "$bin_path" ] || [ ! -f "$bin_path" ]; then
        fail "LazySVN archive did not contain lazysvn binary"
    fi

    cp "$bin_path" "${BIN_DIR}/lazysvn"
    chmod +x "${BIN_DIR}/lazysvn"
    rm -rf "$temp_dir"
    trap - RETURN

    log "Installed lazysvn to ${BIN_DIR}/lazysvn"
}

install_optional_dependencies() {
    if [ "$INSTALL_OPTIONAL_DEPS" != "true" ]; then
        return 0
    fi

    if [ "$(get_os_id)" != "arch" ]; then
        fail "--install-optional-deps is currently supported only on Arch Linux"
    fi

    log "Installing supported optional dependencies for Arch Linux"

    if [ "$ENABLE_GIT" = "true" ]; then
        check_required_runtime_for_optional_install "sudo"
        check_required_runtime_for_optional_install "pacman"
        install_lazygit_arch
    fi

    if [ "$ENABLE_SVN" = "true" ]; then
        check_required_runtime_for_optional_install "curl"
        check_required_runtime_for_optional_install "tar"
        check_required_runtime_for_optional_install "find"
        install_lazysvn_release
    fi
}

ensure_local_bin_on_path() {
    rc_file="$(get_shell_rc_file)"
    path_export_line="$(get_path_export_line)"

    if path_contains_local_bin; then
        log "~/.local/bin is already present in PATH"
        return 0
    fi

    warn "~/.local/bin is not present in PATH; commands like 'kvim' or 'lazysvn' may not be found in new shells"

    add_to_path="$(ask_yes_no "Add ~/.local/bin to PATH in ${rc_file}?" "true")"

    if [ "$add_to_path" = "true" ]; then
        append_local_bin_to_path "$rc_file"
    else
        warn "Skipped PATH update. Add this manually if needed: ${path_export_line}"
    fi
}

prepare_directories() {
    log "Preparing user directories"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SHARE_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$APPLICATIONS_DIR"
}

install_kvim_config() {
    log "Copying KVIM configuration into ${CONFIG_DIR}"
    cp -R "$REPO_ROOT/nvim/." "$CONFIG_DIR/"
}

write_local_override() {
    log "Writing local module override to ${LOCAL_CONFIG_FILE}"

    mkdir -p "$(dirname "$LOCAL_CONFIG_FILE")"

    cat > "$LOCAL_CONFIG_FILE" <<EOF
return {
    modules = {
        workspaces = { enabled = ${ENABLE_WORKSPACES} },
        git = { enabled = ${ENABLE_GIT} },
        svn = { enabled = ${ENABLE_SVN} },
        connections = { enabled = ${ENABLE_CONNECTIONS} },
    },
}
EOF
}

write_launcher() {
    log "Writing KVIM launcher to ${LAUNCHER_FILE}"

    cat > "$LAUNCHER_FILE" <<'EOF'
#!/bin/bash

set -eu

export NVIM_APPNAME="kvim"

usage() {
    cat <<USAGE
Usage: kvim [--gui|--help] [files...]

Modes:
  kvim        Run KVIM in terminal with nvim
  kvim --gui  Run KVIM with neovide
USAGE
}

if [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

if [ "${1:-}" = "--gui" ]; then
    shift

    if ! command -v neovide >/dev/null 2>&1; then
        printf 'KVIM launcher: neovide not found\n' >&2
        exit 1
    fi

    exec neovide "$@"
fi

exec nvim "$@"
EOF

    chmod +x "$LAUNCHER_FILE"
}

write_desktop_entry() {
    log "Writing desktop entry to ${DESKTOP_FILE}"

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=KVIM
Comment=KVIM IDE for Neovim
Exec=${LAUNCHER_FILE} --gui %F
Terminal=false
Categories=Development;IDE;TextEditor;
StartupNotify=true
EOF
}

print_summary() {
    cat <<EOF

KVIM profile prepared successfully.

Installed paths:
  Config:       ${CONFIG_DIR}
  Share:        ${SHARE_DIR}
  Local config: ${LOCAL_CONFIG_FILE}
  Launcher:     ${LAUNCHER_FILE}
  Desktop:      ${DESKTOP_FILE}

Selected modules:
  workspaces:  ${ENABLE_WORKSPACES}
  git:         ${ENABLE_GIT}
  svn:         ${ENABLE_SVN}
  connections: ${ENABLE_CONNECTIONS}

Dependency checks:
  Required dependencies: OK
  Warnings:              ${WARNING_COUNT}
  lazy.nvim:             bootstrap on first start
  Optional installs:     ${INSTALL_OPTIONAL_DEPS}

Next planned installer phases will add:
  - health checks inside KVIM
EOF
}

main() {
    parse_args "$@"
    select_modules
    check_dependencies
    prepare_directories
    install_optional_dependencies
    install_kvim_config
    write_local_override
    write_launcher
    write_desktop_entry
    ensure_local_bin_on_path
    print_summary
}

main "$@"
