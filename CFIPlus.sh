#!/bin/bash
export LANG=zh_CN.UTF-8
proxygithub="https://mirror.ghproxy.com/"
port=443
asn=209242
###############################################################以下脚本内容，勿动#######################################################################
if [ -n "$1" ]; then 
    port="$1"
fi

if [ -n "$2" ]; then 
    asn="$2"
fi

# 选择客户端 CPU 架构
archAffix(){
    case "$(uname -m)" in
        i386 | i686 ) echo 'i386' ;;
        x86_64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
		arm ) echo 'arm' ;;
        * ) red "不支持的CPU架构!" && exit 1 ;;
    esac
}

update_gengxinzhi=0
apt_update() {
    if [ "$update_gengxinzhi" -eq 0 ]; then

		if grep -qi "alpine" /etc/os-release; then
			apk update
		elif grep -qi "openwrt" /etc/os-release; then
			opkg update
			#openwrt没有安装timeout
			opkg install coreutils-timeout
		elif grep -qi "ubuntu\|debian" /etc/os-release; then
			sudo apt-get update
		else
			echo "$(uname) update"
		fi
 
        update_gengxinzhi=$((update_gengxinzhi + 1))
    fi
}

apt_install() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 未安装，开始安装..."
        apt_update
        
	if grep -qi "alpine" /etc/os-release; then
		apk add $1
	elif grep -qi "openwrt" /etc/os-release; then
		opkg install $1
	elif grep -qi "ubuntu\|debian" /etc/os-release; then
		sudo apt-get install $1 -y
	elif grep -qi "centos\|red hat\|fedora" /etc/os-release; then
		sudo yum install $1 -y
	else
		echo "未能检测出你的系统：$(uname)，请自行安装$1。"
		exit 1
	fi
 
        echo "$1 安装完成!"
    fi
}

apt_install curl  # 安装curl
apt_install jq

# 检测是否已经安装了geoiplookup
if ! command -v geoiplookup &> /dev/null; then
    echo "geoiplookup Not installed, start installation..."
    apt_update
    apt_install geoip-bin -y
    echo "geoiplookup The installation is complete!"
fi

if ! command -v mmdblookup &> /dev/null; then
    echo "mmdblookup Not installed, start installation..."
    apt_update
    apt_install mmdb-bin
    echo "mmdblookup The installation is complete!"
fi

# 检测GeoLite2-Country.mmdb文件是否存在
if [ ! -f "/usr/share/GeoIP/GeoLite2-Country.mmdb" ]; then
    echo "The file /usr/share/GeoIP/GeoLite2-Country.mmdb does not exist. downloading..."
    
    # 使用curl命令下载文件
    curl -L -o /usr/share/GeoIP/GeoLite2-Country.mmdb "${proxygithub}https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb"
    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "Download completed."
    else
        echo "Download failed. The script terminates."
        exit 1
    fi
fi

# 如果当前目录下不存在Pscan，则自动下载
if [ ! -f "./Pscan" ]; then
    curl -k -L "${proxygithub}https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/tools/Pscan_linux_$(archAffix)" -o "Pscan"
	chmod +x Pscan
fi

# 如果当前目录下不存在Piplist，则自动下载
if [ ! -f "./Piplist" ]; then
    curl -k -L "${proxygithub}https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/tools/Piplist_linux_$(archAffix)" -o "Piplist"
	chmod +x Piplist
fi

file_path="AS${asn}.txt"
url="https://asn2cidr.090227.xyz/AS${asn}"

upcidr2ip() {
	curl -k -L "$url" -o "$file_path"

	# 检测临时目录是否存在
	if [ -d "temp" ]; then
	  # 目录存在，清空目录内容
	  rm -rf "temp"/*
	  echo "目录已存在，已清空内容。"
	else
	  # 目录不存在，创建目录
	  mkdir "temp"
	  echo "目录不存在，已新建目录。"
	fi

	  # 初始化计数器
	  count=1
	  
	  # 逐行处理文件
	  while IFS= read -r line; do
		# 跳过空行
		if [ -z "$line" ]; then
		  continue
		fi
		
		# 构建输出文件路径
		output_file="temp/$count.txt"
		
		# 执行命令
		./Piplist -IP "$line" -O "$output_file"
		
		echo "处理行: $line，输出文件: $output_file"
		
		# 增加计数器
		((count++))
	  done < "$file_path"
	  
	merged_file="AS${asn}ip.txt"
	# 检测AS${asn}ip.txt是否存在，存在则删除
	if [ -e "$merged_file" ]; then
	  rm -f "$merged_file"
	fi
	  
	# 合并temp目录下所有的txt文件到AS${asn}ip.txt
	if [ -d "temp" ]; then
	  cat "temp"/*.txt > "$merged_file"
	  echo "已合并所有txt文件到 $merged_file。"
	fi
}

# 检测文件是否存在
if [ -e "$file_path" ]; then
  # 文件存在，检测修改时间是否超过30天
  file_mtime=$(stat -c %Y "$file_path")
  current_time=$(date +%s)
  days_diff=$(( (current_time - file_mtime) / (24*3600) ))

  if [ "$days_diff" -gt 30 ]; then
    # 文件存在且超过30天，重新下载
    upcidr2ip
    echo "AS${asn}文件已存在但超过30天，已重新下载。"
  else
    echo "AS${asn}文件存在且未超过30天，无需重新下载。"
  fi
else
  # 文件不存在，下载文件
  echo "$file_path 文件不存在，开始更新下载。"
  upcidr2ip
fi

# 检测临时目录是否存在
if [ -d "temp" ]; then
  # 目录存在，清空目录内容
  rm -rf "temp"/*
  #echo "目录已存在，已清空内容。"
else
  # 目录不存在，创建目录
  mkdir "temp"
  #echo "目录不存在，已新建目录。"
fi

# 循环检测文件大小最多3次
for attempt in {1..3}; do
  # 获取文件大小（以字节为单位）
  file_size=$(stat -c %s "$file_path")
  #echo "文件大小: $file_size 字节"

  if [ "$file_size" -le 1024 ]; then
    echo "AS${asn} 文件大小小于等于1K，开始更新 AS${asn} 文件。"

    # 执行 upcidr2ip 命令
    upcidr2ip

    # 再次获取文件大小
    file_size=$(stat -c %s "$file_path")

    # 判断是否成功执行 upcidr2ip
    if [ "$file_size" -gt 1024 ]; then
      echo "AS${asn} 更新成功，文件大小为: $file_size 字节。"
      break
    else
      echo "AS${asn} 更新失败，尝试重新执行（尝试次数: $attempt）。"
    fi
  else
    break
  fi
done

  #echo "文件大小: $file_size 字节"
if [ $file_size -le 1024 ]; then
  echo "获取 AS${asn} 的 CIDR 失败。"
  exit 1
fi

# 检测AS${asn}ip.txt是否存在
if [ ! -e "AS${asn}ip.txt" ]; then
  echo "错误: 文件 AS${asn}ip.txt 不存在，脚本停止运行。"
  exit 1
fi

echo "正在验证 AS${asn} CloudFlare CDN IP..."
./Pscan -F "AS${asn}ip.txt" -P $port -T 512 -O "temp/ip0.txt" -timeout 1s > /dev/null 2>&1
awk 'NF' "temp/ip0.txt" | sed "s/:${port}$//" > "IPlus.txt"

echo "验证完成 AS${asn} CloudFlareIPlus "

echo "正在将IP按国家代码保存到ip文件夹内..."

# 检查ip文件夹是否存在
if [ -d "ip" ]; then
    # 如果文件夹存在，删除符合要求的文件
    rm -f "ip/*${port}.txt"
else
    # 如果文件夹不存在，创建文件夹
    mkdir "ip"
fi

# 逐行处理IPlus.txt文件
while read -r line; do
    ip=$(echo $line | cut -d ' ' -f 1)  # 提取IP地址部分
	result=$(mmdblookup --file /usr/share/GeoIP/GeoLite2-Country.mmdb --ip $ip country iso_code)
	country_code=$(echo $result | awk -F '"' '{print $2}')
	echo $ip >> "ip/${country_code}-${port}.txt"  # 写入对应的国家文件
done < IPlus.txt

cp -f IPlus.txt ip-${port}.txt
echo "最新CloudFlareIPlus 已保存至 IPlus.txt 并已将IP按国家分类保存到ip文件夹内..."
