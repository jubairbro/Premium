#!/bin/bash

#================================================================================
# Sensi Tunnel Telegram Bot Installer - Ubuntu/Debian
# Auto-fix broken packages, OS detection, Python setup, Systemd service
#================================================================================

# --- Color Codes ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'

# --- Logging functions ---
print_info() { echo -e "${C_CYAN}[INFO]${C_RESET} $1"; }
print_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }
print_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }
print_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }

# --- Logo ---
print_logo() {
echo -e "${C_GREEN}
⠀⣠⣶⣿⣿⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠹⢿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡏⢀⣀⡀⠀⠀⠀⠀⠀
⠀⠀⣠⣤⣦⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣟⣋⣼⣽⣾⣽⣦⡀⠀⠀⠀
⢀⣼⣿⣷⣾⡽⡄⠀⠀⠀⠀⠀⠀⠀⣴⣶⣶⣿⣿⣿⡿⢿⣟⣽⣾⣿⣿⣦⠀⠀
⣸⣿⣿⣾⣿⣿⣮⣤⣤⣤⣤⡀⠀⠀⠻⣿⡯⠽⠿⠛⠛⠉⠉⢿⣿⣿⣿⣿⣷⡀
⣿⣿⢻⣿⣿⣿⣛⡿⠿⠟⠛⠁⣀⣠⣤⣤⣶⣶⣶⣶⣷⣶⠀⠀⠻⣿⣿⣿⣿⣇
⢻⣿⡆⢿⣿⣿⣿⣿⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠀⣠⣶⣿⣿⣿⣿⡟
⠈⠛⠃⠈⢿⣿⣿⣿⣿⣿⣿⠿⠟⠛⠋⠉⠁⠀⠀⠀⠀⣠⣾⣿⣿⣿⠟⠋⠁
⠀⠀⠀⠀⠀⠙⢿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⠟⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣼⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠻⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${C_RESET}"
echo -e "${C_GREEN}====================================================${C_RESET}"
echo -e "${C_GREEN}   Welcome to the Sensi Tunnel Bot Installer!${C_RESET}"
echo -e "${C_GREEN}====================================================${C_RESET}"
echo
}

# --- Root check ---
if [ "$(id -u)" -ne 0 ]; then
    print_error "Please run this script as root."
    exit 1
fi

# --- Ask for bot credentials ---
print_logo
read -p "Enter your Telegram Bot Token: " BOT_TOKEN
[ -z "$BOT_TOKEN" ] && { print_error "Bot Token cannot be empty."; exit 1; }

read -p "Enter your Telegram Owner ID: " OWNER_ID
[[ ! "$OWNER_ID" =~ ^[0-9]+$ ]] && { print_error "Owner ID must be numeric."; exit 1; }

# --- OS check ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    print_error "Cannot detect OS."
    exit 1
fi

print_info "Detected OS: $OS $VER"

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    print_error "Unsupported OS. Only Ubuntu/Debian supported."
    exit 1
fi

# --- Fix broken packages ---
print_info "Fixing broken packages if any..."
apt-get update -y
apt-get --fix-broken install -y

# --- Install dependencies ---
print_info "Installing dependencies..."
apt-get install -y python3 python3-pip git curl speedtest-cli

# --- Python libraries ---
print_info "Installing Python libraries..."
python3 -m pip install --upgrade pip
pip3 install python-telegram-bot psutil || { print_error "Failed to install Python libraries"; exit 1; }

# --- Setup bot directory ---
BOT_DIR="/root/.ssbot"
BOT_SCRIPT="${BOT_DIR}/bot.py"
BOT_URL="https://raw.githubusercontent.com/jubairbro/TG-BOT/refs/heads/main/.ssbot/bot.py"

mkdir -p "$BOT_DIR"
curl -sL "$BOT_URL" -o "$BOT_SCRIPT" || { print_error "Failed to download bot.py"; exit 1; }

# --- Configure bot ---
sed -i "s/BOT_TOKEN = \"bot_token\"/BOT_TOKEN = \"${BOT_TOKEN}\"/" "$BOT_SCRIPT"
sed -i "s/OWNER_ID = 5487394544/OWNER_ID = ${OWNER_ID}/" "$BOT_SCRIPT"

# --- Create systemd service ---
SERVICE_FILE="/etc/systemd/system/bot.service"
echo "[Unit]
Description=Sensi Tunnel Telegram Bot
After=network.target

[Service]
User=root
WorkingDirectory=${BOT_DIR}
ExecStart=/usr/bin/python3 ${BOT_SCRIPT}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target" > "$SERVICE_FILE"

# --- Enable and start service ---
print_info "Starting bot service..."
systemctl daemon-reload
systemctl enable bot.service
systemctl restart bot.service
sleep 2

if systemctl is-active --quiet bot.service; then
    print_success "Bot is now running!"
    echo -e "${C_YELLOW}Use: systemctl status bot.service${C_RESET} to check status"
else
    print_error "Bot service failed to start. Check logs:"
    echo -e "${C_YELLOW}journalctl -u bot.service -f${C_RESET}"
fi
