#!/bin/bash
# WaterWall Half-Duplex Script - Fixed & Complete

Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;96m'
NC='\033[0m'

clear
echo "
══════════════════════════════════════════════════════════════════════════════════════
                WaterWall Half-Duplex (Fixed & Complete)
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
        read -p "Enter Kharej IPv4: " ip_remote
        read -p "Enter SNI (default: ipmart.shop): " input_sni
        HOSTNAME=${input_sni:-ipmart.shop}

        cat > config.json << EOF
{
    "name": "iran_reverse_hd",
    "nodes": [
        {"name": "users_inbound", "type": "TcpListener", "settings": {"address": "0.0.0.0", "port": [23000,65535], "nodelay": true}, "next": "header"},
        {"name": "header", "type": "HeaderClient", "settings": {"data": "src_context->port"}, "next": "bridge2"},
        {"name": "bridge2", "type": "Bridge", "settings": {"pair": "bridge1"}},
        {"name": "bridge1", "type": "Bridge", "settings": {"pair": "bridge2"}},
        {"name": "reverse_server", "type": "ReverseServer", "next": "bridge1"},
        {"name": "pbserver", "type": "ProtoBufServer", "next": "reverse_server"},
        {"name": "h2server", "type": "Http2Server", "next": "pbserver"},
        {"name": "halfs", "type": "HalfDuplexServer", "next": "h2server"},
        {"name": "reality_server", "type": "RealityServer", "settings": {"destination": "reality_dest", "password": "2249AHS2200"}, "next": "halfs"},
        {"name": "kharej_inbound", "type": "TcpListener", "settings": {"address": "0.0.0.0", "port": 443, "whitelist": ["$ip_remote/32"]}, "next": "reality_server"},
        {"name": "reality_dest", "type": "TcpConnector", "settings": {"address": "$HOSTNAME", "port": 443}}
    ]
}
EOF
        setup_service
        echo -e "${Cyan}Iran setup completed!${NC}"

    elif [ "$choice" -eq 2 ]; then
        read -p "Enter Iran IP: " ip_remote
        read -p "Enter SNI (default: ipmart.shop): " input_sni
        HOSTNAME=${input_sni:-ipmart.shop}

        cat > config.json << EOF
{
    "name": "kharej_reverse_hd",
    "nodes": [
        {"name": "outbound_to_core", "type": "TcpConnector", "settings": {"address": "127.0.0.1", "port": "dest_context->port"}},
        {"name": "header", "type": "HeaderServer", "settings": {"override": "dest_context->port"}, "next": "outbound_to_core"},
        {"name": "bridge1", "type": "Bridge", "settings": {"pair": "bridge2"}, "next": "header"},
        {"name": "bridge2", "type": "Bridge", "settings": {"pair": "bridge1"}, "next": "reverse_client"},
        {"name": "reverse_client", "type": "ReverseClient", "settings": {"minimum-unused": 16}, "next": "pbclient"},
        {"name": "pbclient", "type": "ProtoBufClient", "next": "h2client"},
        {"name": "h2client", "type": "Http2Client", "settings": {"host": "$HOSTNAME", "port": 443, "path": "/", "contenttype": "application/grpc", "concurrency": 64}, "next": "halfc"},
        {"name": "halfc", "type": "HalfDuplexClient", "next": "reality_client"},
        {"name": "reality_client", "type": "RealityClient", "settings": {"sni": "$HOSTNAME", "password": "2249AHS2200"}, "next": "outbound_to_iran"},
        {"name": "outbound_to_iran", "type": "TcpConnector", "settings": {"address": "$ip_remote", "port": 443}}
    ]
}
EOF
        setup_service
        echo -e "${Cyan}Kharej setup completed!${NC}"

    elif [ "$choice" -eq 3 ]; then
        systemctl stop waterwall 2>/dev/null
        systemctl disable waterwall 2>/dev/null
        rm -f /etc/systemd/system/waterwall.service
        pkill -f Waterwall
        rm -rf /root/RRT
        echo "Uninstalled successfully."
    elif [ "$choice" -eq 0 ]; then
        break
    else
        echo "Invalid option!"
    fi
done
