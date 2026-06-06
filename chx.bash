#!/bin/bash
# WaterWall Half-Duplex Script - Fixed by Grok

Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;96m'
NC='\033[0m'

clear
echo "
══════════════════════════════════════════════════════════════════════════════════════
               WaterWall Half-Duplex (Fixed Version)
══════════════════════════════════════════════════════════════════════════════════════"

ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
  ASSET_NAME="Waterwall-linux-arm64.zip"
elif [ "$ARCH" == "x86_64" ]; then
  ASSET_NAME="Waterwall-linux-clang-avx512f-x64.zip"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

download_and_unzip() {
  local url="$1"
  local dest="$2"
  echo "Downloading $dest ..."
  wget -q -O "$dest" "$url"
  if [ $? -ne 0 ]; then
    echo "Download failed."
    return 1
  fi
  echo "Unzipping..."
  unzip -o "$dest"
  chmod +x Waterwall
  rm -f "$dest"
  echo "Installation completed."
}

get_latest_release_url() {
  local response=$(curl -s https://api.github.com/repos/radkesvat/WaterWall/releases/latest)
  local asset_url=$(echo "$response" | jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .browser_download_url")
  if [ -z "$asset_url" ]; then
    echo "Trying fallback asset..."
    ASSET_NAME="Waterwall-linux-64.zip"
    asset_url=$(echo "$response" | jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .browser_download_url")
  fi
  echo "$asset_url"
}

setup_service() {
    cat > /etc/systemd/system/waterwall.service << EOF
[Unit]
Description=Waterwall Service
After=network.target

[Service]
ExecStart=/root/RRT/Waterwall
WorkingDirectory=/root/RRT
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now waterwall
}

# Main Menu
while true; do
    echo -e "${Purple}Select an option:${NC}"
    echo -e "1. IRAN"
    echo -e "2. KHAREJ"
    echo -e "3. Uninstall"
    echo -e "0. Exit"
    read -p "Enter your choice: " choice

    if [[ "$choice" -eq 1 || "$choice" -eq 2 ]]; then
        mkdir -p /root/RRT && cd /root/RRT
        apt install unzip jq curl wget -y

        read -p "Do you want to install the latest version? (y/n): " answer
        if [[ "$answer" == [Yy]* ]]; then
            url=$(get_latest_release_url)
            if [ -z "$url" ]; then
                echo "Failed to get download link."
                exit 1
            fi
            download_and_unzip "$url" "$ASSET_NAME"
        fi

        # core.json
        cat > core.json << EOF
{
    "log": {
        "path": "log/",
        "core": {"loglevel": "INFO", "file": "core.log", "console": true},
        "network": {"loglevel": "INFO", "file": "network.log", "console": true}
    },
    "configs": ["config.json"]
}
EOF
    fi

    if [ "$choice" -eq 1 ]; then
        # === IRAN Config ===
        read -p "Enter Kharej IPv4: " ip_remote
        read -p "Enter SNI (default