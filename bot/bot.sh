#!/bin/bash    

#================================================================================    
# Sensi Tunnel Telegram Bot - Cross-OS Auto-Setup Script    
# Supports: Ubuntu, Debian, CentOS, Alpine    
#================================================================================    

# --- Color Codes ---    
C_RESET='\033[0m'    
C_RED='\033[0;31m'    
C_GREEN='\033[0;32m'    
C_YELLOW='\033[1;33m'    
C_CYAN='\033[0;36m'    
C_MAGENTA='\033[0;35m'    

# --- Helper Functions for Logging ---    
print_info() { echo -e "${C_CYAN}[INFO]${C_RESET} $1"; }    
print_warning() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }    
print_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }    
print_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }    

# --- Logo ---    
print_logo() {    
cat << "EOF"    

⠀⣠⣶⣿⣿⣶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀    
⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀    
⠀⠹⢿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡏⢀⣀⡀⠀⠀⠀⠀⠀    
⠀⠀⣠⣤⣦⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣟⣋⣼⣽⣾⣽⣦⡀⠀⠀⠀    
⢀⣼⣿⣷⣾⡽⡄⠀⠀⠀⠀⠀⠀⠀⣴⣶⣶⣿⣿⣿⡿⢿⣟⣽⣾⣿⣿⣦⠀⠀    
⣸⣿⣿⣾⣿⣿⣮⣤⣤⣤⣤⡀⠀⠀⠻⣿⡯⠽⠿⠛⠛⠉⠉⢿⣿⣿⣿⣿⣷⡀    
⣿⣿⢻⣿⣿⣿⣛⡿⠿⠟⠛⠁⣀⣠⣤⣤⣶⣶⣶⣶⣷⣶⠀⠀⠻⣿⣿⣿⣿⣇    
⢻⣿⡆⢿⣿⣿⣿⣿⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠀⣠⣶⣿⣿⣿⣿⡟    
⠈⠛⠃⠈⢿⣿⣿⣿⣿⣿⣿⠿⠟⠛⠋⠉⠁⠀⠀⠀⠀⣠⣾⣿⣿⣿⠟⠋⠁⠀    
⠀⠀⠀⠀⠀⠙⢿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⠟⠁⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⣼⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⠻⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   

EOF    
    echo -e "${C_GREEN}====================================================${C_RESET}"    
    echo -e "${C_GREEN}   Welcome to the Sensi Tunnel Bot Installer!${C_RESET}"    
    echo -e "${C_GREEN}====================================================${C_RESET}"    
    echo    
}    

# --- Root Check ---    
if [ "$(id -u)" -ne 0 ]; then    
    print_error "This script must be run as root."    
    exit 1    
fi    

# --- Ask for Bot Credentials ---    
print_logo    
read -p "Please enter your Telegram Bot Token: " BOT_TOKEN    
[ -z "$BOT_TOKEN" ] && { print_error "Bot Token cannot be empty."; exit 1; }    

read -p "Please enter your Telegram User ID (Owner ID): " OWNER_ID    
[[ ! "$OWNER_ID" =~ ^[0-9]+$ ]] && { print_error "Invalid User ID."; exit 1; }    

# --- OS Detection ---    
if [ -f /etc/os-release ]; then    
    . /etc/os-release    
    OS=$ID    
    VER=$VERSION_ID    
else    
    print_error "Cannot detect OS."    
    exit 1    
fi    
print_info "Detected OS: $OS version $VER"    

# --- Install Dependencies Based on OS ---    
case "$OS" in    
    ubuntu|debian)    
        apt-get update -y    
        apt-get install -y python3 python3-pip git curl speedtest-cli    
        ;;    
    centos|rhel)    
        yum install -y epel-release    
        yum install -y python3 python3-pip git curl    
        ;;    
    alpine)    
        apk update    
        apk add --no-cache python3 py3-pip git curl    
        ;;    
    *)    
        print_error "Unsupported OS: $OS"    
        exit 1    
        ;;    
esac    

# --- Python Libs (no risky pip flags) ---    
print_info "Installing Python libraries..."    
pip3 install --upgrade pip    
pip3 install python-telegram-bot psutil || { print_error "pip install failed"; exit 1; }    

# --- Setup Bot ---    
BOT_DIR="/root/.ssbot"    
BOT_SCRIPT_PATH="${BOT_DIR}/bot.py"    
BOT_SCRIPT_URL="https://raw.githubusercontent.com/jubairbro/TG-BOT/refs/heads/main/.ssbot/bot.py"    

mkdir -p "$BOT_DIR"    
curl -sL "$BOT_SCRIPT_URL" -o "$BOT_SCRIPT_PATH" || { print_error "Bot script download failed"; exit 1; }    

sed -i "s/BOT_TOKEN = \"bot_token\"/BOT_TOKEN = \"${BOT_TOKEN}\"/" "$BOT_SCRIPT_PATH"    
sed -i "s/OWNER_ID = 5487394544/OWNER_ID = ${OWNER_ID}/" "$BOT_SCRIPT_PATH"    

# --- Systemd Service ---    
SERVICE_FILE="/etc/systemd/system/bot.service"    
cat > "$SERVICE_FILE" <<EOF    
[Unit]    
Description=Sensi Tunnel Telegram Bot    
After=network.target    

[Service]    
User=root    
WorkingDirectory=${BOT_DIR}    
ExecStart=/usr/bin/python3 ${BOT_SCRIPT_PATH}    
Restart=always    
RestartSec=10    

[Install]    
WantedBy=multi-user.target    
EOF    

systemctl daemon-reload    
systemctl enable bot.service    
systemctl restart bot.service    

sleep 2    
if systemctl is-active --quiet bot.service; then    
    print_success "Bot is now active and running."    
    echo -e "${C_YELLOW}systemctl status bot.service${C_RESET} to check status"    
else    
    print_error "Bot service failed to start. Check logs:"    
    echo -e "${C_YELLOW}journalctl -u bot.service -f${C_RESET}"    
fi
