#!/bin/bash

# ==========================================
# DVWA 自動化安裝腳本
# Tested OS:
# (1)Lubuntu 24.04.4
# ==========================================

# 1. 檢查是否為 Root 使用者
if [ "$(id -u)" != "0" ]; then
   echo "錯誤: 此腳本必須以 root 權限執行。"
   echo "請使用: sudo ./DVWA_Lubuntu_2404.sh"
   exit 1
fi

echo ">> 正在更新套件列表..."
apt-get update

# 2. 安裝必要相依套件 (確保 git, curl 和 docker 存在)
echo ">> 安裝必要工具..."
apt-get install -y git curl docker.io

# 3. 下載 DVWA
if [ -d "DVWA" ]; then
    echo ">> DVWA 目錄已存在，跳過 Clone..."
else
    echo ">> Clone DVWA repository..."
    git clone https://github.com/digininja/DVWA.git
fi

cd DVWA || exit

# 4. 安裝 Docker Compose (指定版本 v2.29.2)
echo ">> 安裝 Docker Compose..."
curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 5. 安裝 yq 用於修改 YAML
echo ">> 安裝 yq..."
# 注意：某些發行版的 apt yq 版本較舊，若語法報錯可能需要手動安裝 binary
apt-get install -y yq

# 定義設定檔名稱 (優先使用 compose.yml，若無則使用 docker-compose.yml)
if [ -f "compose.yml" ]; then
    CONFIG_FILE="compose.yml"
elif [ -f "docker-compose.yml" ]; then
    CONFIG_FILE="docker-compose.yml"
else
    echo "錯誤: 找不到 compose.yml 或 docker-compose.yml"
    exit 1
fi

echo ">> 正在修改設定檔: $CONFIG_FILE"

# 6. 修改連接埠 (127.0.0.1:4280 -> 0.0.0.0:80)
# 修正 sed 語法順序: sed -i 'expression' file
sed -i 's/127.0.0.1:4280/0.0.0.0:80/g' "$CONFIG_FILE"

# 7. 修改環境變數 (設置 Security Level)
# 注意：確保 yq 語法正確應用
yq -y -i '.services.dvwa.environment += ["DEFAULT_SECURITY_LEVEL=low"]' "$CONFIG_FILE"

# 8. 啟動容器
echo ">> 啟動 DVWA 容器..."
/usr/local/bin/docker-compose up -d

# 9. 使用者加到docker Group
usermod -aG docker $(logname)
newgrp

echo "=========================================="
echo "安裝完成！"
echo "請瀏覽 http://<您的IP地址> 進行訪問"
echo "預設帳號: admin / password"
echo "=========================================="
