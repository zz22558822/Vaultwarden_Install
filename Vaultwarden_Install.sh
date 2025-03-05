#!/bin/bash

set -e  # 遇到錯誤立即停止腳本

# 讓用戶輸入 Domain 與 ADMIN_TOKEN
read -p "請輸入您的 Vaultwarden 網域 (如 vaultwarden.local): " DOMAIN
read -s -p "請輸入您的 Vaultwarden 管理員密碼 (ADMIN_TOKEN): " ADMIN_TOKEN
echo ""
echo "正在安裝與配置..."

# 更新系統並安裝 Docker & Docker Compose
sudo apt update
sudo apt install -y docker.io nginx openssl curl

# 更新 docker-compose V2
#sudo curl -L $(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .assets[0].browser_download_url) -o /usr/local/bin/docker-compose
sudo apt remove docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# 啟動 Docker 並設置開機啟動
sudo systemctl start docker
sudo systemctl enable docker

# 建立 Vaultwarden 目錄
sudo mkdir -p /opt/vaultwarden
cd /opt/vaultwarden

# 創建 docker-compose.yml
cat <<EOF | sudo tee docker-compose.yml
version: '3'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    volumes:
      - ./data:/data
    environment:
      - SIGNUPS_ALLOWED=true
      - ADMIN_TOKEN=$ADMIN_TOKEN
      - WEBSOCKET_ENABLED=true
    ports:
      - "8080:80"
EOF

# 啟動 Vaultwarden
sudo docker-compose up -d

# 建立 SSL 憑證目錄並生成自簽證書
sudo mkdir -p /opt/SSL
cd /opt/SSL
sudo openssl req -x509 -newkey rsa:4096 -keyout private.key -out certificate.crt -days 36500 -nodes -subj "/CN=$DOMAIN"

# 設置適當的權限
sudo chmod 600 private.key
sudo chmod 644 certificate.crt

# 配置 Nginx
sudo tee /etc/nginx/sites-available/vaultwarden <<EOF
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /opt/SSL/certificate.crt;
    ssl_certificate_key /opt/SSL/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}
EOF

# 檢查並刪除已存在的符號連結
if [ -L "/etc/nginx/sites-enabled/vaultwarden" ]; then
    echo "正在刪除舊的符號連結..."
    sudo rm -f /etc/nginx/sites-enabled/vaultwarden
fi

# 啟用 Nginx 設置
sudo ln -s /etc/nginx/sites-available/vaultwarden /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 檢查 Nginx 設定並重新啟動
sudo nginx -t
sudo systemctl restart nginx

# 重啟 Vaultwarden 確保一切運行正常
sudo docker restart vaultwarden

echo ""
echo "※※※ 若為自簽名則無法使用應用程式版本僅能使用 Web ※※※"
echo "※※※ 新辦帳號後請進入後台模式關閉【Allow new signups】※※※"
echo ""
echo "Vaultwarden 安裝完成！請訪問: https://$DOMAIN"
echo "Vaultwarden 後台模式: https://$DOMAIN/admin"
