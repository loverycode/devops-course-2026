#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops.local"                              # псевдоним из ~/.ssh/config
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local:9443"               # порт 9443: UTM на macOS
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/" # работает из любого каталога

# --- 1. Разбор аргумента --dry-run ---
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
    echo "Ошибка: неизвестный аргумент '$1'" >&2
    echo "Использование: $0 [--dry-run]" >&2
    exit 1
fi

# --- 2. Проверка наличия site/index.html (требование 4) ---
if [[ ! -f "${LOCAL_DIR}/index.html" ]]; then
    echo "Ошибка: ${LOCAL_DIR}/index.html не найден" >&2
    exit 1
fi

# --- 3. Проверка незакоммиченных изменений (требование 5) ---
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: есть незакоммиченные изменения:" >&2
    git status --short >&2
    exit 1
fi

# --- 4. Синхронизация (требования 3, 8, 9) ---
RSYNC_OPTS=(-avz --delete --chmod=D755,F644
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5")

if [[ ${DRY_RUN} -eq 1 ]]; then
    rsync "${RSYNC_OPTS[@]}" --dry-run "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"
    echo "(dry-run: изменения не внесены)"
    exit 0
fi

rsync "${RSYNC_OPTS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# --- 5. Проверка доступности ресурса (требование 6) ---
if ! curl -f --cacert "${CA_CERT}" -s -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен" >&2
    exit 1
fi

# --- 6. Успех (требование 7) ---
echo "OK: $(git rev-parse --short HEAD)"
exit 0
