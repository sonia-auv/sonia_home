sonia_sync() {

    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    RESET="\033[0m"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECTS_FILE="$SCRIPT_DIR/.projects"


    if [ ! -f "$PROJECTS_FILE" ]; then
    echo -e "${RED}Error: .projects file not found at $PROJECTS_FILE${RESET}" >&2
    exit 1
    fi

    if [ ! -d "$SONIA_WS/src" ]; then
    echo -e "${RED}Error: src folder not found in workspace: $WORKSPACE/src${RESET}" >&2
    exit 1
    fi


    sonia_pull_single() {
        local proj="$1"
        local path="$SONIA_WS/src/$proj"
        if [ ! -d "$path" ]; then
            echo -e "${YELLOW}SKIP [$proj]: not found${RESET}"
            return 0
        fi
        if [ ! -d "$path/.git" ]; then
            echo -e "${YELLOW}SKIP [$proj]: not a git repo${RESET}"
            return 0
        fi

        pushd "$path" >/dev/null || return 1

        branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'DETACHED')"
        remote="$(git remote 2>/dev/null | head -n1 || true)"
        [ -z "$remote" ] && remote="origin"

        git fetch "$remote" --prune 2>/dev/null

        if [ "$branch" = "HEAD" ] || [ "$branch" = "DETACHED" ]; then
            echo -e "${YELLOW}WARN   [$proj]: $remote/$branch - Detached HEAD; skipping pull.${RESET}"
            popd >/dev/null
            return 0
        fi

        if ! git rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1; then
            echo -e "${YELLOW}WARN   [$proj]: $remote/$branch - No upstream set; skipping pull.${RESET}"
            popd >/dev/null
            return 0
        fi

        if ! git pull --ff-only >/dev/null 2>/dev/null; then
            echo -e "${RED}ERR   [$proj]: $remote/$branch - fast-forward pull failed. Resolve manually.${RESET}" >&2
            popd >/dev/null
            return 1
        fi

        echo -e "${GREEN}OK   [$proj]: $remote/$branch${RESET}"
        popd >/dev/null
        return 0
    }

    fail_count=0
    while IFS= read -r line || [ -n "$line" ]; do
        proj="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -z "$proj" ] && continue
        [[ "$proj" =~ ^# ]] && continue
        # echo $proj
        if ! sonia_pull_single "$proj"; then
            ((fail_count++))
        fi
    done < "$PROJECTS_FILE"

    if [ "$fail_count" -gt 0 ]; then
        echo "Completed with $fail_count failures."
        # exit 1
        else
        echo "All projects updated successfully."
    fi
}