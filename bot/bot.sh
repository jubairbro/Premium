#!/bin/bash

#================================================================================
# Sensi Tunnel Telegram Bot - Advanced Auto-Setup Script
# Description: This script automates the deployment of the Sensi Tunnel Python
#              Telegram bot with OS detection and robust error handling.
# Author: Gemini
#================================================================================

# --- Color Codes ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'

# --- Helper Functions for Logging ---
print_info() {
    echo -e "${C_CYAN}[INFO]${C_RESET} $1"
}

print_warning() {
    echo -e "${C_YELLOW}[WARN]${C_RESET} $1"
}

print_error() {
    echo -e "${C_RED}[ERROR]${C_RESET} $1"
}

print_success() {
    echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"
}
# --- Logo ---
print_logo() {
cat << "EOF"
                                                           
 SSSSSS                   ii                              
SS    SS nn nnn   sssss  tt    uu u   uu nn nnn  nn nnn  eeee  ll
 SSSSSS  nnn  nn SS      tt    uu u   uu nnn  nn nnn  nn ee   e ll
     SS  nn   nn  SSSSS  tt    uu u   uu nn   nn nn   nn eeeee  ll
SS    SS nn   nn      SS  tt    uuuu   uu nn   nn nn   nn ee     ll
 SSSSSS  nn   nn SSSSSS    tttt  uuuu u   nn   nn nn   nn  eeee  llll 
                                                               
EOF
    echo -e "${C_MAGENTA}====================================================${C_RESET}"
    echo -e "${C_YELLOW}    Welcome to the Sensi Tunnel Bot Installer!${C_RESET}"
    echo -e "${C_MAGENTA}====================================================${C_RESET}"
    echo
}

# --- Pre-flight Checks ---

# 1. Root Check
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. if you have root run"
    exit 1
fi

# 2. Dependency Check (apicreate, apidelete, apirenew)
REQUIRED_SCRIPTS=("/usr/bin/apicreate" "/usr/bin/apidelete" "/usr/bin/apirenew")
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        print_error "Dependency missing: '$script' not found or not executable."
        print_warning "Please install the Sensi Tunnel panel script first before running this bot installer."
        exit 1
    fi
done
print_success "All required Sensi Tunnel dependencies are present."

# --- Main Execution ---
print_logo

# --- User Input ---
read -p "Please enter your Telegram Bot Token: " BOT_TOKEN
if [ -z "$BOT_TOKEN" ]; then
    print_error "Bot Token cannot be empty. Aborting setup."
    exit 1
fi

read -p "Please enter your Telegram User ID (Owner ID): " OWNER_ID
if ! [[ "$OWNER_ID" =~ ^[0-9]+$ ]]; then
    print_error "Invalid User ID. Please enter numbers only. Aborting setup."
    exit 1
fi

# --- OS Detection and Dependency Installation ---
print_info "Detecting Operating System..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    print_error "Cannot detect the Operating System. Aborting."
    exit 1
fi

print_info "Detected OS: $OS version $VER"

print_info "Updating system packages and installing dependencies..."
apt-get update -y
apt-get install -y python3 python3-pip git curl speedtest-cli || { print_error "Failed to install system packages."; exit 1; }

# --- Conditional PIP Flag ---
PIP_FLAGS=""
if [[ "$OS" == "ubuntu" && $(echo "$VER" "22.04" | awk '{print ($1 >= $2)}') -eq 1 ]] || \
   [[ "$OS" == "debian" && $(echo "$VER" "12" | awk '{print ($1 >= $2)}') -eq 1 ]]; then
    print_info "Modern OS detected. Using '--break-system-packages' flag for pip."
    PIP_FLAGS="--break-system-packages"
fi

# --- Install Python Libraries ---
print_info "Installing required Python libraries..."
pip3 install python-telegram-bot --pre psutil ${PIP_FLAGS} || { print_error "Failed to install Python libraries via pip."; exit 1; }

# --- Download and Configure Bot Script ---
BOT_DIR="/root/.ssbot"
BOT_SCRIPT_PATH="${BOT_DIR}/bot.py"
BOT_SCRIPT_URL="https://raw.githubusercontent.com/jubairbro/TG-BOT/refs/heads/main/.ssbot/bot.py"

print_info "Creating bot directory at ${BOT_DIR}..."
mkdir -p "$BOT_DIR"

print_info "Downloading bot script from GitHub..."
if ! curl -sL "$BOT_SCRIPT_URL" -o "$BOT_SCRIPT_PATH"; then
    print_error "Failed to download the bot script. Please check the URL or your internet connection."
    exit 1
fi

print_info "Configuring the bot with your Token and Owner ID..."
sed -i "s/BOT_TOKEN = \"bot_token\"/BOT_TOKEN = \"${BOT_TOKEN}\"/" "$BOT_SCRIPT_PATH"
sed -i "s/OWNER_ID = 5487394544/OWNER_ID = ${OWNER_ID}/" "$BOT_SCRIPT_PATH"
print_success "Bot script configured successfully."

# --- Create and Start systemd Service ---
SERVICE_FILE="/etc/systemd/system/bot.service"
print_info "Creating systemd service file at ${SERVICE_FILE}..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Sensi Tunnel Telegram Bot Service
After=network.target

[Service]
User=root
WorkingDirectory=${BOT_DIR}
ExecStart=/usr/bin/python3 ${BOT_SCRIPT_PATH}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

print_info "Reloading systemd, enabling and starting the bot service..."
systemctl daemon-reload
systemctl enable bot.service
systemctl start bot.service

# --- Final Verification ---
sleep 3 # Give the service a moment to start
if systemctl is-active --quiet bot.service; then
    echo
    print_success "Setup Complete! Your bot is now active and running."
    echo
    print_info "To check the bot's status, use this command:"
    echo -e "  ${C_YELLOW}systemctl status bot.service${C_RESET}"
    echo
    print_info "To view the bot's real-time logs, use this command:"
    echo -e "  ${C_YELLOW}journalctl -u bot.service -f${C_RESET}"
    echo
else
    echo
    print_error "The bot service failed to start. Please check the logs for errors."
    print_warning "Use this command to see the details: journalctl -u bot.service"
    echo
fi
