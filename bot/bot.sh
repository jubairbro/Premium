#!/bin/bash

set -e

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_BLUE='\033[0;34m'

BOT_DIR="/root/.ssbot"
VENV_DIR="${BOT_DIR}/venv"
BOT_SCRIPT_PATH="${BOT_DIR}/bot.py"
BOT_URL="https://raw.githubusercontent.com/jubairbro/TG-BOT/refs/heads/main/.ssbot/bot.py"
SERVICE_NAME="sensi-bot"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

print_info() { echo -e "${C_CYAN}[INFO]${C_RESET} $1"; }
print_step() { echo -e "\n${C_BLUE}>>> $1${C_RESET}"; }
print_error() { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }
print_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
print_warn() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }

print_logo() {
    clear
    echo -e "${C_GREEN}
     telegram        Terminal
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
    echo -e "${C_GREEN}      Sensi Tunnel Bot Installer (Interactive)      ${C_RESET}"
    echo -e "${C_GREEN}====================================================${C_RESET}"
    echo
}

check_privileges() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root. Please use 'sudo' or log in as root."
        exit 1
    fi
}

detect_os() {
    print_step "Detecting Operating System..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        print_info "Detected OS: $OS"
        if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
            print_error "This script is designed for Ubuntu or Debian systems only."
            exit 1
        fi
    else
        print_error "Could not detect the operating system."
        exit 1
    fi
    print_success "OS check passed."
}

install_dependencies() {
    print_step "Updating package lists and installing required system dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install --fix-broken -y
    apt-get install -y python3 python3-pip python3-venv git curl speedtest-cli
    print_success "System dependencies installed successfully."
}

setup_python_environment() {
    print_step "Setting up Python Virtual Environment..."
    if [ -d "$VENV_DIR" ]; then
        print_warn "Existing virtual environment found. Recreating it."
        rm -rf "$VENV_DIR"
    fi
    mkdir -p "$BOT_DIR"
    python3 -m venv "$VENV_DIR"
    if [ ! -f "${VENV_DIR}/bin/python" ]; then
        print_error "Failed to create Python virtual environment."
        exit 1
    fi
    
    print_info "Installing required Python libraries inside the venv..."
    "${VENV_DIR}/bin/pip" install --upgrade pip
    "${VENV_DIR}/bin/pip" install python-telegram-bot psutil
    print_success "Python environment is ready."
}

configure_bot_script() {
    print_step "Downloading and configuring the bot script..."
    curl -sL "$BOT_URL" -o "$BOT_SCRIPT_PATH"
    if [ ! -s "$BOT_SCRIPT_PATH" ]; then
        print_error "Failed to download the bot script (bot.py). Please check the URL or your connection."
        exit 1
    fi

    sed -i "s/^BOT_TOKEN = .*/BOT_TOKEN = \"${BOT_TOKEN}\"/" "$BOT_SCRIPT_PATH"
    sed -i "s/^OWNER_ID = .*/OWNER_ID = ${OWNER_ID}/" "$BOT_SCRIPT_PATH"
    print_success "Bot script configured with your credentials."
}

setup_systemd_service() {
    print_step "Setting up systemd service to run the bot automatically..."
    echo "[Unit]
Description=Sensi Tunnel Telegram Bot
After=network.target

[Service]
User=root
WorkingDirectory=${BOT_DIR}
ExecStart=${VENV_DIR}/bin/python3 ${BOT_SCRIPT_PATH}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target" > "$SERVICE_FILE"

    print_info "Reloading systemd, enabling and starting the bot service..."
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service"
    systemctl start "${SERVICE_NAME}.service"
    
    sleep 3
    
    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
        print_success "Bot service is now active and running!"
    else
        print_error "The bot service failed to start. Check logs for details."
        print_info "You can check logs using option 3 from the main menu."
    fi
}

run_installation() {
    print_logo
    print_info "Starting the bot installation process..."
    
    read -p "Enter your Telegram Bot Token: " BOT_TOKEN
    if [ -z "$BOT_TOKEN" ]; then
        print_error "Bot Token cannot be empty. Installation aborted."
        exit 1
    fi
    
    read -p "Enter your numeric Telegram Owner ID: " OWNER_ID
    if ! [[ "$OWNER_ID" =~ ^[0-9]+$ ]]; then
        print_error "Owner ID must be a number. Installation aborted."
        exit 1
    fi
    
    check_privileges
    detect_os
    install_dependencies
    setup_python_environment
    configure_bot_script
    setup_systemd_service

    echo -e "\n${C_GREEN}================ Installation Complete ================${C_RESET}"
    print_info "Your bot is now set up and running in the background."
    print_info "You can manage it using the menu or with systemctl commands."
    echo -e "${C_YELLOW}Example: systemctl status ${SERVICE_NAME}${C_RESET}"
}

run_uninstallation() {
    print_logo
    print_warn "This will completely remove the bot and all its files."
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        print_info "Uninstallation cancelled."
        exit 0
    fi

    print_step "Stopping and disabling the systemd service..."
    if systemctl list-unit-files | grep -q "${SERVICE_NAME}.service"; then
        systemctl stop "${SERVICE_NAME}.service" || true
        systemctl disable "${SERVICE_NAME}.service" || true
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        print_success "Service has been stopped and removed."
    else
        print_warn "Service file not found. Skipping."
    fi

    print_step "Deleting bot directory (${BOT_DIR})..."
    if [ -d "$BOT_DIR" ]; then
        rm -rf "$BOT_DIR"
        print_success "Bot directory has been deleted."
    else
        print_warn "Bot directory not found."
    fi
    
    print_success "\nSensi Tunnel Bot has been successfully uninstalled."
}

view_logs() {
    print_logo
    print_info "Displaying live logs for the bot service..."
    print_info "Press ${C_YELLOW}Ctrl+C${C_RESET} to exit the log view."
    echo "--------------------------------------------------"
    if ! journalctl -u "${SERVICE_NAME}.service" -f; then
        print_error "Could not retrieve logs. Is the service installed?"
    fi
}

main_menu() {
    print_logo
    echo -e "Welcome! What would you like to do?"
    echo -e "  ${C_GREEN}1)${C_RESET} Install Sensi Tunnel Bot"
    echo -e "  ${C_RED}2)${C_RESET} Uninstall Sensi Tunnel Bot"
    echo -e "  ${C_YELLOW}3)${C_RESET} View Bot Logs"
    echo -e "  ${C_CYAN}4)${C_RESET} Exit"
    echo
    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1)
            run_installation
            ;;
        2)
            run_uninstallation
            ;;
        3)
            view_logs
            ;;
        4)
            print_info "Exiting."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            sleep 2
            main_menu
            ;;
    esac
}

main_menu
