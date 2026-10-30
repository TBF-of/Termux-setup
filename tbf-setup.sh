#!/data/data/com.termux/files/usr/bin/bash

# Colors for UI
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# List of all available packages
packages=(
    "nmap"
    "git"
    "curl"
    "wget"
    "python"
    "python-pip"
    "proot"
    "openssh"
    "htop"
    "nano"
    "net-tools"
    "dnsutils"
)

# Status array (1 = install, 0 = skip)
declare -A status
for p in "${packages[@]}"; do
    status["$p"]=1
done

# Interactive package selector menu
while true; do
    clear
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${CYAN}       TBF-SETUP: Utility Selector      ${RESET}"
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${YELLOW}Enter the package number to toggle it [ON/OFF].${YELLOW}"
    echo -e "${YELLOW}Press '0' when you are ready to start.${RESET}\n"
    
    for i in "${!packages[@]}"; do
        pkg_name="${packages[$i]}"
        if [ "${status[$pkg_name]}" -eq 1 ]; then
            echo -e "  [$GREEN✓$RESET] $((i+1)). $pkg_name"
        else
            echo -e "  [$RED✗$RESET] $((i+1)). $pkg_name"
        fi
    done
    
    echo -e "\n  [${CYAN}0${RESET}] 👉 Start Installation"
    read -p "Your choice: " choice
    
    if [ "$choice" = "0" ]; then
        break
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#packages[@]}" ]; then
        idx=$((choice-1))
        pkg_name="${packages[$idx]}"
        if [ "${status[$pkg_name]}" -eq 1 ]; then
            status["$pkg_name"]=0
        else
            status["$pkg_name"]=1
        fi
    else
        echo -e "${RED}Invalid choice! Try again.${RESET}"
        sleep 1
    fi
done

# Start installation process
clear
echo -e "${CYAN}[*] Initializing TBF-Setup environment...${RESET}"

# System update
echo -e "${CYAN}[i] Updating Termux system packages...${RESET}"
pkg update -y && pkg upgrade -y

total_pkgs=${#packages[@]}
current=0
success_count=0
skipped_count=0

for pkg_name in "${packages[@]}"; do
    current=$((current + 1))
    
    if [ "${status[$pkg_name]}" -eq 1 ]; then
        echo -e "\n${YELLOW}[$current/$total_pkgs] Installing package: ${pkg_name}${RESET}"
        
        pkg install -y "$pkg_name"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[x] Error: Package '${pkg_name}' not found or failed to install!${RESET}"
            echo -e "${YELLOW}Choose an action:${RESET}"
            echo -e "  ${CYAN}y${RESET} - Retry installation"
            echo -e "  ${CYAN}n${RESET} - Skip package"
            echo -e "  ${CYAN}u${RESET} - Enter custom package name"
            
            read -p "Your choice [y/n/u]: " action_choice
            
            case "$action_choice" in
                y|Y)
                    pkg install -y "$pkg_name"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}[✓] Successfully installed: ${pkg_name}${RESET}"
                        success_count=$((success_count + 1))
                    else
                        echo -e "${RED}[x] Retry failed, skipping.${RESET}"
                        skipped_count=$((skipped_count + 1))
                    fi
                    ;;
                u|U)
                    read -p "Enter package name (pkg install will be added automatically): " custom_pkg
                    if [ -n "$custom_pkg" ]; then
                        echo -e "${CYAN}[i] Installing: $custom_pkg...${RESET}"
                        pkg install -y $custom_pkg
                        if [ $? -eq 0 ]; then
                            echo -e "${GREEN}[✓] Successfully installed: ${custom_pkg}${RESET}"
                            success_count=$((success_count + 1))
                        else
                            echo -e "${RED}[x] Failed to install custom package.${RESET}"
                            skipped_count=$((skipped_count + 1))
                        fi
                    else
                        skipped_count=$((skipped_count + 1))
                    fi
                    ;;
                *)
                    echo -e "${YELLOW}[i] Skipping package ${pkg_name}...${RESET}"
                    skipped_count=$((skipped_count + 1))
                    ;;
            esac
        else
            echo -e "${GREEN}[✓] Successfully installed: ${pkg_name}${RESET}"
            success_count=$((success_count + 1))
        fi
    else
        echo -e "\n${YELLOW}[$current/$total_pkgs] Skipping disabled package: ${pkg_name}${RESET}"
        skipped_count=$((skipped_count + 1))
    fi
done

# Storage setup
if [ ! -d ~/storage ]; then
    echo -e "\n${CYAN}[i] Requesting storage permissions...${RESET}"
    termux-setup-storage
fi

echo -e "\n${CYAN}========================================${RESET}"
echo -e "${GREEN}[✓] TBF-Setup completed successfully!${RESET}"
echo -e "${CYAN}    Installed: ${GREEN}$success_count${RESET} | Skipped/Failed: ${YELLOW}$skipped_count${RESET}"
echo -e "${CYAN}========================================${RESET}"
