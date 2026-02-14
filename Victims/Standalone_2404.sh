#!/bin/bash

# 確保 Script 以 root 權限執行
if [ "$EUID" -ne 0 ]; then
  echo "請使用 sudo 執行此 script"
  exit
fi

echo "=== 開始安裝 DVWA on Ubuntu 24.04 ==="

# 1. 更新系統並安裝必要的依賴套件
echo "[+] 更新系統與安裝 LAMP Stack..."
apt update && apt upgrade -y
# 安裝 Apache, MariaDB, PHP 8.3 及相關模組
apt install -y apache2 mariadb-server git unzip
apt install -y php php-mysqli php-gd php-curl php-mbstring php-xml php-bcmath

# 2. 啟動服務
echo "[+] 啟動 Apache 與 MariaDB..."
systemctl start apache2
systemctl enable apache2
systemctl start mariadb
systemctl enable mariadb

# 3. 設定資料庫
echo "[+] 設定資料庫..."
# 建立 dvwa 資料庫與使用者 (預設密碼設為 password，請依需求修改)
DB_USER="dvwa"
DB_PASS="password"
DB_NAME="dvwa"

mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 4. 下載 DVWA
echo "[+] 下載 DVWA..."
cd /var/www/html
if [ -d "dvwa" ]; then
    echo "DVWA 目錄已存在，先移除..."
    rm -rf dvwa
fi
git clone https://github.com/digininja/DVWA.git dvwa

# 5. 設定 DVWA Config
echo "[+] 設定 DVWA Config..."
cd dvwa/config
cp config.inc.php.dist config.inc.php

# 修改 config.inc.php 內的資料庫連線資訊
sed -i "s/db_user     = 'db_user';/db_user     = '${DB_USER}';/g" config.inc.php
sed -i "s/db_password = 'db_password';/db_password = '${DB_PASS}';/g" config.inc.php

# 6. 修改目錄權限
echo "[+] 設定目錄權限..."
chown -R www-data:www-data /var/www/html/dvwa
chmod -R 755 /var/www/html/dvwa
# 某些上傳漏洞練習需要寫入權限
chmod -R 777 /var/www/html/dvwa/hackable/uploads/
chmod -R 777 /var/www/html/dvwa/external/php/ids/

# 7. 修改 PHP 設定 (啟用不安全選項以支援漏洞練習)
echo "[+] 修改 php.ini 設定..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_INI="/etc/php/${PHP_VERSION}/apache2/php.ini"

if [ -f "$PHP_INI" ]; then
    # 允許遠端文件包含 (RFI 漏洞需要)
    sed -i 's/allow_url_include = Off/allow_url_include = On/g' $PHP_INI
    sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' $PHP_INI
    # 顯示錯誤 (方便除錯與練習)
    sed -i 's/display_errors = Off/display_errors = On/g' $PHP_INI
else
    echo "⚠️ 找不到 php.ini，請手動檢查 PHP 版本路徑。"
fi

# 8. 重啟 Apache
echo "[+] 重啟 Apache..."
systemctl restart apache2

echo "========================================"
echo "✅ DVWA 安裝完成！"
echo "請打開瀏覽器訪問: http://localhost/dvwa"
echo "預設登入帳號: admin"
echo "預設登入密碼: password"
echo "首次登入後，請點擊頁面下方的 'Create / Reset Database' 按鈕進行初始化。"
echo "========================================"
