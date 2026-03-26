#!/bin/bash
# ==============================================================================
# KOMODO DEPLOYMENT SCRIPT
# ==============================================================================
# This script automates the deployment of Komodo Core, Periphery, and Common Tools.
# Designed for read-only systems (like TrueNAS SCALE) using a bundled GH CLI.
#
# WORKFLOW OPTIONS:
#
# 1. INTERACTIVE (No token needed):
#    $ ./deploy.sh setup           --> Starts Device Code login.
#    $ ./deploy.sh all [mode]      --> Clones/Updates repos and WIPES credentials.
#
# 2. AUTOMATED (Using GH_TOKEN):
#    $ export GH_TOKEN=ghp_your_secret_token
#    $ ./deploy.sh all [mode]      --> GH CLI will use the token automatically.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e 

# --- Configuration ---
ORGNAME="bonzosoft"
COMMONDIR="common-tools"
COREDIR="komodo-core"
PERIPHERYDIR="komodo-periphery"
GITBRANCH="main" # The actual GitHub branch to clone/sync

# Capture arguments
COMMAND="$1"
MODE="${2:-prod}" # Environment mode (prod, dev, etc). Defaults to 'prod'

# Dynamically find where this script is located
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Dynamically find the 'gh' binary inside the gh_..._linux_amd64 folder structure
GH=$(find "${SCRIPTDIR}" -type f -path "*/gh_*_linux_amd64*/gh" | head -n 1)

# Temporary directory for session credentials (destroyed after use)
export GH_CONFIG_DIR="/tmp/komodo-gh-config"
export GIT_CONFIG_GLOBAL="${GH_CONFIG_DIR}/gitconfig"

# --- Functions ---

show_help() {
    echo "Usage: ./deploy.sh [command] [mode]"
    echo ""
    echo "Arguments:"
    echo "  [command]   The action to perform (required)."
    echo "  [mode]      The environment mode for .env files (optional, defaults to 'prod')."
    echo "              Note: [mode] is only used for syncing repos (all, common, core, periphery)."
    echo ""
    echo "Commands:"
    echo "  setup       [Step 1] Login interactively via Device Code"
    echo "  all         [Step 2] Sync ALL repos (Common -> Core -> Periphery) and WIPE credentials"
    echo "  common      Sync Common Tools repository only"
    echo "  core        Sync Komodo Core repository only"
    echo "  periphery   Sync Komodo Periphery repository only"
    echo "  status      Check local directory status"
    echo "  clean-auth  Manually remove GH session credentials from /tmp"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh setup"
    echo "  ./deploy.sh all prod"
    echo "  ./deploy.sh core dev"
}

check_gh_binary() {
    if [ -z "${GH}" ] || [ ! -f "${GH}" ]; then 
        echo "Error: 'gh' binary not found. Make sure the gh_*_linux_amd64 folder is in ${SCRIPTDIR}."
        exit 1
    fi
    # Ensure the binary is executable
    chmod +x "${GH}"
}

login() {
    check_gh_binary

    if [ -z "$GH_TOKEN" ]; then
        echo ">>> Starting interactive login (Device Code)..."
        "${GH}" auth login --hostname github.com --git-protocol https --web
    else
        echo ">>> GH_TOKEN detected, skipping interactive login."
    fi
    
    # Setup git credential helper using the isolated configuration
    "${GH}" auth setup-git
}

sync_repo() {
    local REPO_NAME=$1
    check_gh_binary
    
    if [ ! -d "${REPO_NAME}/.git" ]; then
        echo "Cloning private repository ${REPO_NAME}..."
        "${GH}" repo clone "${ORGNAME}/${REPO_NAME}" "${REPO_NAME}" # -- --recurse-submodules
        cd "${REPO_NAME}"
        git submodule update --init --recursive
        cd ..
    else
        echo "Local repository ${REPO_NAME} found. Forcing update..."
        cd "${REPO_NAME}"
        git fetch origin "${GITBRANCH}"
        git reset --hard "origin/${GITBRANCH}"
        git submodule update --init --recursive
        cd ..
    fi

    # Environment file setup using MODE
    if [ -f "${REPO_NAME}/.env.${MODE}" ]; then
        echo "Applying configuration: .env.${MODE} -> .env"
        #cp "${REPO_NAME}/.env.${MODE}" "${REPO_NAME}/.env"
        ln -sf "${REPO_NAME}/.env.${MODE}" "${REPO_NAME}/.env"
    else
        echo "Warning: .env.${MODE} not found in ${REPO_NAME}. Skipping env setup."
    fi
    
    echo ">>> Finished: ${REPO_NAME}"
    echo ""
}

status_check() {
    echo "--- Local Status ---"
    [ -d "${COMMONDIR}" ] && echo "[OK] Common folder exists" || echo "[..] Common folder missing"
    [ -d "${COREDIR}" ] && echo "[OK] Core folder exists" || echo "[..] Core folder missing"
    [ -d "${PERIPHERYDIR}" ] && echo "[OK] Periphery folder exists" || echo "[..] Periphery folder missing"
}

# --- Main Logic Route ---
case "$COMMAND" in
    login)
        login
        ;;
    install-all)
        echo "Deployment Mode: ${MODE^^}" # Prints mode in uppercase (e.g., PROD)
        sync_repo "${COMMONDIR}"
        sync_repo "${COREDIR}"
        sync_repo "${PERIPHERYDIR}"
        clean_auth
        ;;
    install-common-tools)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${COMMONDIR}"
        ;;
    install-core)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${COREDIR}"
        ;;
    install-periphery)
        echo "Deployment Mode: ${MODE^^}"
        sync_repo "${PERIPHERYDIR}"
        ;;
    run-core)
        pushd "${COREDIR}"
        bash ./predeploy.sh -b prod
        docker compose up -d
        bash ./postdeploy.sh -b prod
        popd
        ;;
    run-periphery)
        pushd "${PERIPHERYDIR}"
        bash ./predeploy.sh -b prod
        docker compose up -d
        bash ./postdeploy.sh -b prod
        popd
        ;;
    stop-core)
        pushd "${COREDIR}"
        docker compose down
        popd
        ;;
    stop-periphery)
        pushd "${PERIPHERYDIR}"
        docker compose down
        popd
        ;;
    status)
        status_check
        ;;
    *)
        show_help
        ;;
esac