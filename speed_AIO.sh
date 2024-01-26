#!/bin/bash
# $ ./speed.sh us 443 4 xxxx.com xxxx@gmail.com xxxxxxxxxxxxxxx 
export LANG=zh_CN.UTF-8
auth_email="xxxx@gmail.com"    #你的CloudFlare注册账户邮箱 *必填
auth_key="xxxxxxxxxxxxxxx"   #你的CloudFlare账户key,位置在域名概述页面点击右下角获取api key。*必填
zone_name="xxxx.com"     #你的主域名 *必填

area_GEC="yx"    #自动更新的二级域名前缀
port=443 #自定义测速端口 不能为空!!!
ips=4    #获取更新IP的指定数量，默认为4 

speedtestMB=90 #测速文件大小 单位MB，文件过大会拖延测试时长，过小会无法测出准确速度
speedlower=10  #自定义下载速度下限,单位为mb/s
lossmax=0.75  #自定义丢包几率上限；只输出低于/等于指定丢包率的 IP，范围 0.00~1.00，0 过滤掉任何丢包的 IP
speedqueue_max=2 #自定义测速IP冗余量

telegramBotUserId="" # telegram UserId
telegramBotToken="6599852032:AAHhetLKhXfAIjeXgCHpish1DK_NHo3BCrk" #telegram BotToken https://t.me/ACFST_DDNS_bot
telegramBotAPI="api.telegram.ssrc.cf" #telegram 推送API,留空将启用官方API接口:api.telegram.org
###############################################################以下脚本内容，勿动#######################################################################
speedurl="https://speed.cloudflare.com/__down?bytes=$((speedtestMB * 1000000))" #官方测速链接
proxygithub="https://mirror.ghproxy.com/" #反代github加速地址，如果不需要可以将引号内容删除，如需修改请确保/结尾 例如"https://mirror.ghproxy.com/"

#带有地区参数，将赋值第1参数为地区
if [ -n "$1" ]; then 
    area_GEC="$1"
fi

#带有端口参数，将赋值第2参数为端口
if [ -n "$2" ]; then
    port="$2"
fi

#带有更新IP的指定数量参数，将赋值第3参数为端口
if [ -n "" ]; then
    ips="$3"
fi

#带有CloudFlare账户邮箱参数，将赋值第5参数
if [ -n "$5" ]; then
    auth_email="$5"
fi

#带有CloudFlare账户key参数，将赋值第6参数
if [ -n "$6" ]; then
    auth_key="$6"
fi

# 选择客户端 CPU 架构
archAffix(){
    case "$(uname -m)" in
        i386 | i686 ) echo '386' ;;
        x86_64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        s390x ) echo 's390x' ;;
        * ) red "不支持的CPU架构!" && exit 1 ;;
    esac
}

update_gengxinzhi=0
apt_update() {
    if [ "$update_gengxinzhi" -eq 0 ]; then
        sudo apt update
        update_gengxinzhi=$((update_gengxinzhi + 1))
    fi
}

# 检测并安装软件函数
apt_install() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 未安装，开始安装..."
        apt_update
        sudo apt install "$1" -y
        echo "$1 安装完成！"
    fi
}

# 检测并安装 Git、Curl、unzip 和 awk
apt_install git
apt_install curl
apt_install unzip
apt_install awk
apt_install jq

TGmessage(){
if [ -z "$telegramBotAPI" ]; then
    telegramBotAPI="api.telegram.org"
fi
#解析模式，可选HTML或Markdown
MODE='HTML'
#api接口
URL="https://${telegramBotAPI}/bot${telegramBotToken}/sendMessage"
if [[ -z ${telegramBotToken} ]]; then
   echo "Telegram 推送通知未配置。"
else
   res=$(timeout 20s curl -s -X POST $URL -d chat_id=${telegramBotUserId}  -d parse_mode=${MODE} -d text="$1")
    if [ $? == 124 ];then
      echo "Telegram API请求超时，请检查网络是否能够访问Telegram或者更换telegramBotAPI。"          
    else
      resSuccess=$(echo "$res" | jq -r ".ok")
      if [[ $resSuccess = "true" ]]; then
        echo "Telegram 消息推送成功！"
      else
        echo "Telegram 消息推送失败，请检查Telegram机器人的telegramBotToken和telegramBotUserId！"
      fi
    fi
fi
}

download_CloudflareST() {
    # 发送 API 请求获取仓库信息（替换 <username> 和 <repo>）
    latest_version=$(curl -s https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$latest_version" ]; then
    	latest_version="v2.2.4"
    	echo "下载版本号: $latest_version"
    else
    	echo "最新版本号: $latest_version"
    fi
    # 下载文件到当前目录
    curl -L -o CloudflareST.tar.gz "${proxygithub}https://github.com/XIU2/CloudflareSpeedTest/releases/download/$latest_version/CloudflareST_linux_$(archAffix).tar.gz"
    # 解压CloudflareST文件到当前目录
    sudo tar -xvf CloudflareST.tar.gz CloudflareST -C /
	rm CloudflareST.tar.gz

}

# 尝试次数
max_attempts=5
current_attempt=1

while [ $current_attempt -le $max_attempts ]; do
    # 检查是否存在CloudflareST文件
    if [ -f "CloudflareST" ]; then
        echo "CloudflareST 准备就绪。"
        break
    else
        echo "CloudflareST 未准备就绪。"
        echo "第 $current_attempt 次下载 CloudflareST ..."
        download_CloudflareST
    fi

    ((current_attempt++))
done

if [ $current_attempt -gt $max_attempts ]; then
    echo "连续 $max_attempts 次下载失败。请检查网络环境时候可以访问github后重试。"
    exit 1
fi

area_GEC0="${area_GEC^^}"
if [ "$area_GEC0" = "CMCC" ]; then
    ip_txt="CMCC.txt"
else
    ip_txt="IPlus.txt"
fi

upip() {
    curl -L -o IPlus.txt "${proxygithub}https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/main/${ip_txt}"
}

if [ -e "$ip_txt" ]; then
    echo "$ip_txt文件就绪"
else
    echo "$ip_txt文件不存在，开始更新整合IP库"
    upip
fi

#带有域名参数，将赋值第4参数为地区
if [ -n "$4" ]; then 
    zone_name="$4"
    echo "域名 $4"
fi

#带有自定义测速地址参数，将赋值第7参数为自定义测速地址
if [ -n "$7" ]; then
    speedurl="$7"
    echo "自定义测速地址 $7"
else
    echo "使用默认测速地址 $speedurl"
fi

if [ $port -eq 443 ]; then
  record_name="${area_GEC}"
else
  record_name="${area_GEC}-${port}"
fi

#ip_txt="IPlus.txt"
result_csv="${area_GEC0}-${port}.csv"

if [ ! -f "$ip_txt" ]; then
    echo "$area_GEC0 地区IP文件 $ip_txt 不存在。脚本终止。"
    exit 1
fi

echo "$area_GEC0 地区IP文件 $ip_txt 存在"

echo "待处理域名 ${record_name}.${zone_name} （如您使用的是443端口的话，准备域名无需标注端口号。）"

record_type="A"     
#获取zone_id、record_id
zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
# echo $zone_identifier
readarray -t record_identifiers < <(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name.$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*')

record_count=0
for identifier in "${record_identifiers[@]}"; do
	# echo "${record_identifiers[$record_count]}"
	((record_count++))
done
speedqueue=$((ips + speedqueue_max)) #自定义测速队列，多测2条做冗余

#./CloudflareST -tp 443 -url "https://cs.cmliussss.link" -f "ip/HK.txt" -dn 128 -tl 260 -p 0 -o "log/HK.csv"
./CloudflareST -tp $port -url $speedurl -f $ip_txt -dn $speedqueue -tl 280 -tlr $lossmax -p 0 -sl $speedlower -o $result_csv

if [ "$record_count" -gt 0 ]; then
  for record_id in "${record_identifiers[@]}"; do

	# 执行 curl 命令并将结果保存到变量
	result=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_identifier}/dns_records/${record_id}" \
		 -H "X-Auth-Email: ${auth_email}" \
		 -H "X-Auth-Key: ${auth_key}" \
		 -H "Content-Type: application/json")

	# 提取 success 字段的值
	success=$(echo "${result}" | jq -r '.success')

	# 判断 success 的值并输出相应的提示
	if [ "${success}" == "true" ]; then
		echo "$record_name.$zone_name 删除成功"
	else
		echo "$record_name.$zone_name 删除失败"
	fi
    # 可以在这里添加适当的等待时间，以避免对 API 的过多请求
    sleep 1
  done
fi

#exit 1
TGtext0=""
sed -n '2,20p' $result_csv | while read line
do
    speed=$(echo $line | cut -d',' -f6)
    # 初始化尝试次数
    attempt=0
    
    # 更新DNS记录
    while [[ $attempt -lt 3 ]]
    do
	
		# 执行 curl 命令并将结果保存到变量
		result=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zone_identifier}/dns_records" \
			 -H "X-Auth-Email: ${auth_email}" \
			 -H "X-Auth-Key: ${auth_key}" \
			 -H "Content-Type: application/json" \
			 --data '{
			   "type": "'"${record_type}"'",
			   "name": "'"${record_name}"'.'"${zone_name}"'",
			   "content": "'"${line%%,*}"'",
			   "ttl": 60,
			   "proxied": false
			 }')

		# 提取 success 字段的值
		success=$(echo "${result}" | jq -r '.success')

		# 判断 success 的值并输出相应的提示
		if [ "${success}" == "true" ]; then
		    TGtext=$record_name'.'$zone_name' 更新成功: '${line%%,*}' 速度:'${speed}'MB/s'
			echo $TGtext
			break
			echo "创建成功"
		else

			# 输出 messages 内容
			messages=$(echo "${result}" | jq -r '.messages | join(", ")')
			#echo "错误信息: ${messages}"
			
			TGtext=$record_name'.'$zone_name' 更新失败: '${messages}
			echo $TGtext
			attempt=$(( $attempt + 1 ))
			echo "尝试次数: $attempt, 1分钟后将再次尝试更新..."
			sleep 60
		fi

    done
    
    TGtext0="$TGtext0%0A$TGtext"
    ips=$(($ips-1))    #二级域名序号递减
    if [ $ips -eq 0 ]; then
        TGmessage "CF官方优选域名维护完成！ $TGtext0"
        break
    fi

done
