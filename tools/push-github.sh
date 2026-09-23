#!/usr/bin/env bash
# 把本站推到 GitHub 并（可选）启用 Pages。
# 用法: bash tools/push-github.sh <owner/repo> [分支] [GH_TOKEN]
#   例: bash tools/push-github.sh liuhaiyang/liuhaiyang.github.io main
# 需要: 你的 SSH 公钥已加到 GitHub 账号（推送用 SSH，无需 token）。
#       若给了 GH_TOKEN，则顺带用 API 启用 Pages 并打印网址。
set -uo pipefail
REPO="${1:?用法: bash tools/push-github.sh <owner/repo> [分支] [GH_TOKEN]}"
BRANCH="${2:-main}"
TOKEN="${3:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[1/5] 检查仓库状态"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "  不是 git 仓库，先 git init"; exit 1; }
[ -n "$(git status --porcelain)" ] && { echo "  有未提交改动，先提交："; git status --short; exit 1; }
echo "  干净，当前分支 $(git rev-parse --abbrev-ref HEAD)，提交 $(git log --oneline -1)"

echo "[2/5] 设置远端并改分支名为 $BRANCH"
git remote remove origin 2>/dev/null
git remote add origin "git@github.com:$REPO.git"
git branch -M "$BRANCH"

echo "[3/5] 测 SSH 认证（未加公钥会在这里失败）"
if timeout 15 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "  ✔ SSH 认证通过"
else
  echo "  ✗ SSH 未认证 —— 到 https://github.com/settings/keys 添加你的公钥后再跑本脚本"
  echo "    你的公钥: $(cat ~/.ssh/id_ed25519.pub 2>/dev/null | cut -c1-60)…"
  exit 2
fi

echo "[4/5] 推送"
git push -u origin "$BRANCH" 2>&1 | tail -4 | sed 's/^/  /'

echo "[5/5] 启用 Pages"
OWNER="${REPO%%/*}"; NAME="${REPO##*/}"
if [ -n "$TOKEN" ]; then
  code=$(curl -s -o /tmp/pages.json -w '%{http_code}' -X POST \
    -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/pages" \
    -d "{\"source\":{\"branch\":\"$BRANCH\",\"path\":\"/\"}}")
  if [ "$code" = "201" ] || [ "$code" = "409" ]; then
    echo "  ✔ Pages 已启用（HTTP $code）"
  else
    echo "  ⚠ API 返回 HTTP $code，内容：$(head -c 200 /tmp/pages.json)"
    echo "    可手动启用：仓库 Settings → Pages → Source: $BRANCH / (root)"
  fi
else
  echo "  未提供 token —— 手动启用：仓库 Settings → Pages → Source: $BRANCH / (root) → Save"
fi

if [ "$NAME" = "$OWNER.github.io" ]; then URL="https://$OWNER.github.io/"; else URL="https://$OWNER.github.io/$NAME/"; fi
echo
echo "  预期网址: $URL"
echo "  等 1–2 分钟后自检："
echo "    curl -s -o /dev/null -w 'HTTP %{http_code}\\n' $URL"
echo "  上线后记得把占位域名换成真实网址（canonical/og/sitemap/robots 一起改）："
echo "    bash tools/set-domain.py ${URL#https://}"
echo "  再提交推送一次即可。"
