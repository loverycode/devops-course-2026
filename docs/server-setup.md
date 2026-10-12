# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины

- Память: 2048 МБ
- Ядра: 2
- Диск: 15 ГБ (динамически расширяемый)
- Гипервизор: UTM (QEMU ARM64 на Apple Silicon M1)
- ОС: Ubuntu Server 24.04.5 LTS (aarch64)

## 2. Сетевые интерфейсы

- `enp0s1` — QEMU Virtual Network (User/Emulated VLAN)
- IPv4: `10.0.2.15/24`
- Шлюз: `10.0.2.2`, DNS: `10.0.2.3`

## 3. Правило проброса портов (UTM)

- Хост `127.0.0.1:2222` → Гость `:2222` (SSH)
- Хост `127.0.0.1:80` → Гость `:80` (HTTP)
- Хост `127.0.0.1:443` → Гость `:443` (HTTPS)

## 4. Учётные записи

- `student` — sudo-доступ, пароль задан при установке
- `devops` — группы: devops, sudo, users. Вход по ключу `~/.ssh/devops_vm`
- Root — прямой вход запрещён (`PermitRootLogin no`)

## 5. Служба SSH

- Порт: 2222
- Файл конфигурации: `/etc/ssh/sshd_config.d/99-hardening.conf`
- Изменённые директивы:
  - Port 2222
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - PermitEmptyPasswords no
  - MaxAuthTries 3
  - LoginGraceTime 30
  - AllowUsers devops
  - X11Forwarding no
  - ClientAliveInterval 300
  - ClientAliveCountMax 2
- Socket-активация отключена: `ssh.socket` disabled, `ssh.service` enabled
- Защита от cloud-init: `/etc/cloud/cloud.cfg.d/99-disable-ssh-pwauth.cfg` с `ssh_pwauth: false`

## 6. Правила межсетевого экрана (UFW)

- Политики по умолчанию: deny incoming, allow outgoing
- Правила:
  - `limit 2222/tcp` (SSH rate-limited)
  - `allow 80/tcp` (HTTP)
  - `allow 443/tcp` (HTTPS)
- Логирование: medium

## 7. Снимки состояния (qemu-img)

- `01-clean-install` — 2026-10-11 22:02 (после установки Ubuntu)
- `02-keys-configured` — 2026-10-11 23:00 (после настройки ключей)
- `03-ssh-hardened` — 2026-10-12 00:28 (после hardening SSH)
