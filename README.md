# CloudFlareIPlus
自动获取 AS209242 CIDR 并验证最新 CloudFlareCDN IP

## 用法

### 一键执行脚本
``` bash
curl -k -O https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/CFIPlus.sh && chmod +x CFIPlus.sh && ./CFIPlus.sh
```

### 代理加速执行
``` bash
curl -k -O https://mirror.ghproxy.com/https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/CFIPlus.sh && chmod +x CFIPlus.sh && ./CFIPlus.sh
```

执行完成后会将CloudFlareCDN IP 保存至 IPlus.txt

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
 └─ temp            # 脚本执行临时文件暂存文件夹
     ├─ ip.txt      # 临时文件
    ...
     └─ ip0.txt
```

## 感谢
[Moxin1044](https://github.com/Moxin1044)
