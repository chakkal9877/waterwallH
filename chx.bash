#!/bin/bash
# WaterWall Half-Duplex v1.30 - Fixed & Optimized

Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;96m'
NC='\033[0m'

clear
echo "
══════════════════════════════════════════════════════════════════════════════════════
                WaterWall Half-Duplex (v1.30)
══════════════════════════════════════════════════════════════════════════════════════"

download_and_unzip() {
  echo "Downloading Waterwall v1.30 ..."
  wget -q -O Waterwall-linux-64.zip https://github.com/radkesvat/WaterWall/releases/download/v1.30/Waterwall-linux-64.zip
  unzip -o Waterwall-linux-64.zip
  chmod +x Waterwall
  rm -f Waterwall-linux-64.zip
  echo "Download and unzip completed."
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
RestartSec=3
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
        apt update && apt install unzip curl wget -y
        download_and_unzip

        cat > core.json << EOF
{
    "log": {
        "path": "log/",
        "core": {"loglevel": "INFO", "file": "core.log", "console": true},
        "network": {"loglevel": "INFO", "file": "network.log", "console": true}
    },
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": ["config.json"]
}
EOF
    fi

    if [ "$choice" -eq 1 ]; then
        read -p "Enter Kharej IPv4: " ip_remote
        read -p "Enter SNI (default: dns.google): " input_sni
        HOSTNAME=${input_sni:-dns.google}

        cat > config.json << EOF
{
    "name": "iran_hd_v130",
    "nodes": [
        {"name": "multi", "type": "TcpListener", "settings": {"address": "0.0.0.0", "port": [23000,65535], "nodelay": true}, "next": "header"},
        {"name": "header", "type": "HeaderClient", "settings": {"data": "src_context->port"}, "next": "b2"},
        {"name": "b2", "type": "Bridge", "settings": {"pair": "b1"}},
        {"name": "b1", "type": "Bridge", "settings": {"pair": "b2"}},
        {"name": "rev", "type": "ReverseServer", "next": "b1"},
        {"name": "pb", "type": "ProtoBufServer", "next": "rev"},
        {"name": "h2", "type": "Http2Server", "next": "pb"},
        {"name": "half", "type": "HalfDuplexServer", "next": "h2"},
        {"name": "reality", "type": "RealityServer", "settings": {"destination": "dest", "password": "2249AHS2200"}, "next": "half"},
        {"name": "in443", "type": "TcpListener", "settings": {"address": "0.0.0.0", "port": 443, "whitelist": ["$ip_remote/32"]}, "next": "reality"},
        {"name": "dest", "type": "TcpConnector", "settings": {"address": "$HOSTNAME", "port": 443}}
    ]
}
EOF
        setup_service
        echo -e "${Cyan}Iran (v1.30) setup completed!${NC}"

    elif [ "$choice" -eq 2 ]; then
        read -p "Enter Iran IP: " ip_remote
        read -p "Enter SNI (default: dns.google): " input_sni
        HOSTNAME=${input_sni:-dns.google}

        cat > config.json << EOF
{
    "name": "kharej_hd_v130",
    "nodes": [
        {"name": "out", "type": "TcpConnector", "settings": {"address": "127.0.0.1", "port": "dest_context->port"}},
        {"name": "header", "type": "HeaderServer", "settings": {"override": "dest_context->port"}, "next": "out"},
        {"name": "b1", "type": "Bridge", "settings": {"pair": "b2"}, "next": "header"},
        {"name": "b2", "type": "Bridge", "settings": {"pair": "b1"}, "next": "rev"},
        {"name": "rev", "type": "ReverseClient", "settings": {"minimum-unused": 16}, "next": "pb"},
        {"name": "pb", "type": "ProtoBufClient", "next": "h2"},
        {"name": "h2", "type": "Http2Client", "settings": {"host": "$HOSTNAME", "port": 443, "path": "/", "contenttype": "application/grpc", "concurrency": 64}, "next": "half"},
        {"name": "half", "type": "HalfDuplexClient", "next": "reality"},
        {"name": "reality", "type": "RealityClient", "settings": {"sni": "$HOSTNAME", "password": "2249AHS2200"}, "next": "toiran"},
        {"name": "toiran", "type": "TcpConnector", "settings": {"address": "$ip_remote", "port": 443}}
    ]
}
EOF
        setup_service
        echo -e "${Cyan}Kharej (v1.30) setup completed!${NC}"

    elif [ "$choice" -eq 3 ]; then
        systemctl stop waterwall 2>/dev/null
        systemctl disable waterwall 2>/dev/null
        rm -f /etc/systemd/system/waterwall.service
        pkill -f Waterwall
        rm -rf /root/RRT
        echo "Uninstalled."
    elif [ "$choice" -eq 0 ]; then
        break
    fi
done
