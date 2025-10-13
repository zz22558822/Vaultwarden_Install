# Vaultwarden_Install
使用 Ubuntu 24.04 一鍵安裝 Vaultwarden + Nginx 反向代理


## Ubuntu 執行
```
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/zz22558822/Vaultwarden_Install/main/Vaultwarden_Install.sh)"
```


## 改版說明
2025/10/13:
-生成包含 SAN 的憑證作為 Root CA 可以讓官方App正常連線


## Bitwarden CLI 連線方法
設定連線 Domain
```
bw config server https://vaultwarden.local
```
使用 Node.JS 變數忽略 SSL/TLS 錯誤
```
set NODE_TLS_REJECT_UNAUTHORIZED=0
```
登入
```
bw login
```

Bitwarden CLI config 設定檔位置
```
%APPDATA%\Bitwarden CLI
```

