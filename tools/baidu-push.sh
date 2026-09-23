#!/usr/bin/env bash
# 百度「普通收录」API 主动推送 + sitemap 检查
# 用法: bash baidu-push.sh <你的域名> <百度推送token> [sitemap.xml 的 URL 列表文件]
# 说明: token 在 ziyuan.baidu.com → 普通收录 → API 提交 里查看（形如 xxxxxxxx）
set -uo pipefail
DOMAIN="${1:?用法: bash baidu-push.sh <域名> <token> [urls.txt]}"
TOKEN="${2:?缺少百度推送 token}"
LIST="${3:-}"

UA='Mozilla/5.0 (compatible; MySiteBaiduPush/1.0)'

if [ -n "$LIST" ] && [ -f "$LIST" ]; then
  URLS="$(grep -oE 'https?://[^"<>[:space:]]+' "$LIST" | sort -u)"
else
  URLS="https://$DOMAIN/
https://$DOMAIN/en.html"
fi

n=$(printf '%s\n' "$URLS" | grep -c .)
echo "[$(date -Is)] 准备推送 $n 条 URL 到百度（站点 $DOMAIN）"

resp=$(printf '%s' "$URLS" | curl -s --max-time 60 \
  -H 'Content-Type:text/plain' --data-binary @- \
  "http://data.zz.baidu.com/urls?site=$DOMAIN&token=$TOKEN")

echo "百度返回: $resp"
echo "$resp" | grep -q '"success"' && echo "✔ 推送成功（success 字段为本次可推送配额）" || echo "✗ 推送失败，检查 site/token 是否匹配、域名是否已验证"

echo
echo "—— 抓取自检（应能取到你的首页，且 robots.txt 允许 Baiduspider）——"
curl -s -o /dev/null -w "  首页 HTTP %{http_code}  %{time_total}s\n" "https://$DOMAIN/"
curl -s "https://$DOMAIN/robots.txt" | head -5 | sed 's/^/  robots: /'
