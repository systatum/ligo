#!/usr/bin/env bash
set -euo pipefail

FILE=".vfox.toml"

############################################
# Extract version using Python (preferred)
############################################
get_version_python() {
  python3 - <<'PY'
import sys

file = ".vfox.toml"
in_tools = False

try:
    with open(file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("["):
                in_tools = (line == "[tools]")
                continue
            if in_tools and line.startswith("crystal"):
                v = line.split("=", 1)[1].strip().strip('"').strip("'")
                if v:
                    print(v)
                    sys.exit(0)
except FileNotFoundError:
    pass

sys.exit(1)
PY
}

############################################
# Fallback parser (regex-based)
############################################
get_version_grep() {
  grep -E '^\s*crystal\s*=' "$FILE" \
    | head -n1 \
    | sed -E 's/.*=\s*["'\'']([^"'\'']+)["'\''].*/\1/'
}

############################################
# Update .vfox.toml (source of truth)
############################################
update_toml_version() {
  local new_version="$1"

  awk -v ver="$new_version" '
  BEGIN { in_tools=0 }
  /^\[.*\]/ {
    in_tools = ($0 == "[tools]")
  }
  {
    if (in_tools && $0 ~ /^\s*crystal\s*=/) {
      sub(/=.*/, "= \"" ver "\"")
    }
    print
  }' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
}

############################################
# Resolve version
############################################
version=""

if command -v python3 >/dev/null 2>&1; then
  version="$(get_version_python || true)"
fi

if [[ -z "$version" ]]; then
  version="$(get_version_grep || true)"
fi

if [[ -z "$version" ]]; then
  echo "Failed to extract crystal version from $FILE"
  exit 1
fi

############################################
# asdf version detection
# Determines which CLI syntax to use:
#   ASDF_LEGACY=1 -> pre-0.16 (hyphenated, asdf global/local)
#   ASDF_LEGACY=0 -> 0.16+    (spaced subcommands, asdf set)
############################################
ASDF_LEGACY=0

detect_asdf_version() {
  local raw
  raw="$(asdf version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" || true

  if [[ -z "$raw" ]]; then
    # can't determine version so assume modern to be safe
    ASDF_LEGACY=0
    return
  fi

  local major minor
  major="$(echo "$raw" | cut -d. -f1)"
  minor="$(echo "$raw" | cut -d. -f2)"

  if [[ "$major" -eq 0 && "$minor" -lt 16 ]]; then
    ASDF_LEGACY=1
  else
    ASDF_LEGACY=0
  fi
}

############################################
# asdf compat wrappers
############################################

asdf_plugin_list() {
  if [[ "$ASDF_LEGACY" -eq 1 ]]; then
    asdf plugin-list 2>/dev/null
  else
    asdf plugin list 2>/dev/null
  fi
}

asdf_plugin_add() {
  if [[ "$ASDF_LEGACY" -eq 1 ]]; then
    asdf plugin-add "$@"
  else
    asdf plugin add "$@"
  fi
}

asdf_set_global() {
  local name="$1"
  local ver="$2"

  if [[ "$ASDF_LEGACY" -eq 1 ]]; then
    asdf global "$name" "$ver"
  else
    asdf set -u "$name" "$ver"
  fi
}

asdf_set_local() {
  local name="$1"
  local ver="$2"

  if [[ "$ASDF_LEGACY" -eq 1 ]]; then
    asdf local "$name" "$ver"
  else
    asdf set "$name" "$ver"
  fi
}

############################################
# vfox: check if version already installed
# Uses `vfox list` output; avoids reinstall
############################################
vfox_has_version() {
  # extract version column, strip leading "v", match exactly
  vfox list crystal 2>/dev/null \
    | awk '{print $2}' \
    | sed 's/^v//' \
    | grep -Fx "$version" >/dev/null 2>&1
}

############################################
# asdf: check if version already installed
# Uses `asdf list crystal`
############################################
asdf_has_version() {
  asdf list crystal 2>/dev/null | grep -E "${version}" >/dev/null 2>&1
}

############################################
# Extract Marten version from shard.lock
# Uses Python if available, fallback to grep
############################################
############################################
# Resolve shard files location
# Supports:
#   ./shard.yml
#   ./backend/shard.yml
############################################
resolve_shard_paths() {
  if [[ -f "shard.yml" ]]; then
    SHARD_DIR="."
  elif [[ -f "backend/shard.yml" ]]; then
    SHARD_DIR="backend"
  else
    echo "shard.yml not found (expected ./ or ./backend/)"
    return 1
  fi

  SHARD_FILE="$SHARD_DIR/shard.yml"
  SHARD_LOCK="$SHARD_DIR/shard.lock"
}

get_marten_version_python() {
  resolve_shard_paths || return 1

  python3 - <<PY
import sys

file = "$SHARD_LOCK"
in_marten = False

try:
    with open(file) as f:
        for line in f:
            line = line.rstrip()

            if line.strip() == "marten:":
                in_marten = True
                continue

            # exit block when next dependency starts
            if in_marten and line.startswith("  ") and not line.startswith("    "):
                in_marten = False

            if in_marten and "version:" in line:
                v = line.split(":", 1)[1].strip().strip('"').strip("'")
                if v:
                    print(v)
                    sys.exit(0)
except FileNotFoundError:
    pass

sys.exit(1)
PY
}

get_marten_version_grep() {
  resolve_shard_paths || return 1

  awk '
    $1 == "marten:" { in_marten=1; next }
    in_marten && $1 == "version:" {
      gsub(/"/, "", $2)
      print $2
      exit
    }
  ' "$SHARD_LOCK"
}

############################################
# Install Marten CLI matching shard.lock
############################################
install_marten() {
  local version=""

  if command -v python3 >/dev/null 2>&1; then
    version="$(get_marten_version_python || true)"
  fi

  if [[ -z "$version" ]]; then
    version="$(get_marten_version_grep || true)"
  fi

  if [[ -z "$version" ]]; then
    echo "Failed to extract Marten version from shard.lock"
    return 1
  fi

  local tag="v${version}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  echo "Installing Marten $version"

  # clone exact tag to avoid drift from main branch
  git clone --depth 1 --branch "$tag" https://github.com/martenframework/marten "$tmp_dir/marten"

  cd "$tmp_dir/marten"

  # install dependencies defined by Marten itself
  shards install

  mkdir -p bin

  # build CLI binary
  crystal build src/marten_cli.cr -o bin/marten

  # move to global path (requires permission)
  # mv bin/marten /usr/local/bin/marten
  sudo install -m 0755 bin/marten /usr/local/bin/marten

  cd - >/dev/null
  rm -rf "$tmp_dir"
}

########################################################################################
# Crystal and Marten installation
########################################################################################


############################################
# Ensure Crystal is installed + selected
# Returns 0 only if required version is usable
############################################
ensure_crystal() {
  if command -v vfox >/dev/null 2>&1; then
    echo "Using vfox"

    if ! vfox_has_version; then
      vfox install crystal "$version"
    fi

    vfox use -g "crystal@$version"

    # verify installation actually succeeded
    vfox_has_version || return 1
    return 0

  elif command -v asdf >/dev/null 2>&1; then
    echo "Using asdf"

    detect_asdf_version
    echo "asdf legacy mode: $ASDF_LEGACY ($(asdf version 2>/dev/null || echo 'unknown'))"

    # ensure plugin exists (idempotent)
    if ! asdf_plugin_list | grep -q '^crystal$'; then
      asdf_plugin_add crystal https://github.com/asdf-community/asdf-crystal.git
    fi

    if ! asdf_has_version; then
      asdf install crystal "$version"
    fi

    asdf_set_local crystal "$version"

    # keep .vfox.toml authoritative
    update_toml_version "$version"

    # verify installation actually succeeded
    asdf_has_version || return 1
    return 0

  else
    echo "No supported SDK manager found (vfox or asdf)"
    return 1
  fi
}

############################################
# Activate SDK environment
############################################
activate_sdk() {
  if command -v vfox >/dev/null 2>&1; then
    eval "$(vfox activate bash)" || return 1
    return 0

  elif command -v asdf >/dev/null 2>&1; then
    if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
      . "$HOME/.asdf/asdf.sh" || return 1
      return 0
    elif [[ "$ASDF_LEGACY" -eq 1 ]]; then
      return 1
    else
      # modern asdf is just a plain binary
      return 0
    fi
  fi

  return 1
}

############################################
# Ensure required system dependencies (APT only)
# Dependency list scoped locally for encapsulation
############################################

# Sanitize APT sources: disable broken PPAs, remove duplicate ubuntu.sources
sanitize_apt() {
  # disable known broken PPA (no Release file)
  if ls /etc/apt/sources.list.d/*qwinff* >/dev/null 2>&1; then
    echo "Disabling broken qwinff PPA"
    sudo rm -f /etc/apt/sources.list.d/*qwinff*
  fi

  # remove duplicate ubuntu.sources if present
  if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    echo "Removing duplicate ubuntu.sources"
    sudo rm -f /etc/apt/sources.list.d/ubuntu.sources
  fi
}

ensure_system_deps() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Cannot ensure system dependencies: apt-get not available"
    return 1
  fi

  # verify Ubuntu/Debian family
  if ! grep -qiE 'ubuntu|debian' /etc/os-release 2>/dev/null; then
    echo "Unsupported OS for automatic dependency install"
    return 1
  fi

  local packages=(
    build-essential
    pkg-config
    libssl-dev
    libpcre2-dev
    zlib1g-dev
    libgc-dev
    libvips-dev
    libgmp-dev
    libsqlite3-dev
    libxml2-dev
    libyaml-dev
  )

  # critical: sanitize broken sources first
  sanitize_apt

  # full cleanup → fixes stale/broken index
  sudo apt-get clean
  sudo rm -rf /var/lib/apt/lists/*

  # rebuild index from configured mirrors
  if ! sudo apt-get update -y; then
    echo "apt-get update failed"
    return 1
  fi

  # install with retry + fix-missing
  if ! sudo apt-get install -y "${packages[@]}"; then
    echo "Initial install failed, retrying with --fix-missing"

    sudo apt-get update --fix-missing -y

    sudo apt-get install -y "${packages[@]}" || return 1
  fi
}

############################################
# Execute flow:
# 1. Ensure Crystal
# 2. Activate SDK
# 3. Re-verify environment
# 4. Ensure system deps (APT only)
# 5. Install Marten
############################################
if ensure_crystal; then

  if ! activate_sdk; then
    echo "Failed to activate SDK environment; skipping Marten installation"
    exit 1
  fi

  # re-verify SDK state after activation
  if command -v vfox >/dev/null 2>&1; then
    vfox_has_version || {
      echo "Crystal version not active after SDK activation"
      exit 1
    }
  elif command -v asdf >/dev/null 2>&1; then
    asdf_has_version || {
      echo "Crystal version not active after SDK activation"
      exit 1
    }
  fi

  # enforce tool availability
  command -v crystal >/dev/null 2>&1 || {
    echo "crystal not available after activation"
    exit 1
  }

  command -v shards >/dev/null 2>&1 || {
    echo "shards not available after activation"
    exit 1
  }

  # install system dependencies before building Marten
  if ! ensure_system_deps; then
    echo "System dependencies not satisfied; skipping Marten installation"
    exit 1
  fi

  install_marten

else
  echo "Crystal setup failed; skipping Marten installation"
  exit 1
fi
