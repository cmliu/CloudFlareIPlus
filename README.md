# CloudFlareIPlus
自动获取 AS209242 CIDR 并验证最新 CloudFlareCDN IP

## 用法
推荐在 CloudflareSpeedTest 目录下执行脚本，方便后续 CloudflareSpeedTest 直接读取 IPlus.txt 测速。
### 一键执行脚本
``` bash
curl -k -O https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/CFIPlus.sh && chmod +x CFIPlus.sh && ./CFIPlus.sh
```

### 代理加速执行
``` bash
curl -k -O https://mirror.ghproxy.com/https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/CFIPlus.sh && chmod +x CFIPlus.sh && ./CFIPlus.sh
```

执行完成后会将CloudFlareCDN IP 保存至 [IPlus.txt](https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/IPlus.txt)（该文件是我第一次执行脚本产生的文件，如需最新IP文件请自行运行脚本），后还会将IP按[国家地区代码保存至ip文件夹](https://github.com/cmliu/cloudflare-better-ip)。

### 自定义端口验证执行
HTTP：80，8080，8880，2052，2082，2086，2095；

HTTPS：443，2053，2083，2087，2096，8443。
``` bash
./CFIPlus.sh 2096
```

## 文件结构
```
 ├─ CFIPlus.sh      # 脚本本体
 ├─ AS209242.txt    # AS209242的CIDR文件
 ├─ AS209242ip.txt  # AS209242的IP文件
 ├─ IPlus.txt       # CloudFlareCDN IP 脚本执行结果文件
 ├─ Piplist         # CIDR展开至IP 执行程序
 ├─ Pscan           # 端口扫描程序
 ├─ ip              # 将IP按国家地区分类保存目录
 │   ├─ HK-443.txt  # 香港地区IP
 │   ├─ SG-443.txt  # 新加坡地区IP
 │  ...
 │   └─ US-443.txt  # 美国地区IP
 └─ temp            # 脚本执行临时文件暂存文件夹
     ├─ ip.txt      # 临时文件
    ...
     └─ ip0.txt
```

## 感谢
[Moxin1044](https://github.com/Moxin1044)、[P3TERX](https://github.com/P3TERX/GeoLite.mmdb)、[MaxMind](https://www.maxmind.com/)
