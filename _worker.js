// 从指定的 URL 获取 IP 列表
async function fetchIPs() {
	const response = await fetch("https://raw.githubusercontent.com/cmliu/CloudFlareIPlus/refs/heads/main/IPlus.txt");
	const text = await response.text();

	// 检测文件是否包含 '\r\n'，如果包含则使用 '\r\n' 拆分，否则使用 '\n'
	const separator = text.includes('\r\n') ? '\r\n' : '\n';

	// 将文本按行拆分，并过滤掉空行
	return text.split(separator).filter(line => line.trim() !== '');
}

// 随机获取指定数量的 IP
async function getRandomIPs(ips, count) {
	// 随机打乱 IP 列表
	const shuffled = ips.sort(() => 0.5 - Math.random());
	// 返回前 count 行
	return shuffled.slice(0, count);
}

export default {
	async fetch(request, env, ctx) {
		// 获取 IP 列表
		const ips = await fetchIPs();
		
		// 如果 IP 数量少于 7000，返回所有内容
		if (ips.length < 7000) {
				return new Response(ips.join('\n'), {
						headers: { 'Content-Type': 'text/plain' },
				});
		}

		// 获取随机的 7000 行 IP
		const randomIPs = await getRandomIPs(ips, 7000);

		// 对随机获取的 IP 进行排序
		const sortedIPs = randomIPs.sort();

		// 将排序后的 IP 列表拼接为字符串
		const responseText = sortedIPs.join('\n');
		
		// 返回排序后的 IP
		return new Response(responseText, {
				headers: { 'Content-Type': 'text/plain' },
		});
	},
};
