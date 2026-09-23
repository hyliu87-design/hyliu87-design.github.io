# 部署到 GitHub Pages（三步走）

> 目的：把本静态站免费放到 GitHub，得到 `https://<用户名>.github.io/` 这样的网址。
> 百度收录在 GitHub Pages 上很慢（详见 README 第 5 节）；想稳定被百度搜到，最终仍需境内托管 + 备案，
> 或至少绑定自己的域名（本仓已备好 `tools/set-domain.py` 与 `CNAME` 机制）。

## 第 0 步：准备账号与公钥（一次性）

1. 注册/登录 GitHub（用你的常用邮箱）。
2. 打开 https://github.com/settings/keys → **New SSH key** → Title 填 `sonmi` → Key 粘贴下面这条（本机公钥）：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOr9/8sBTCUhfyxEegnXJ4sXvvdr9rt4BVLDuzUJW3iA 1379948253@qq.com
```

   指纹可核对：`SHA256:gccEagY4ks4oQ6ENeUQea7ndsmAQVmKbcQZi48DzeMs`
3. 验证：在服务器上跑 `ssh -T git@github.com`，看到 `Hi <用户名>! You've successfully authenticated` 即成功。

## 第 1 步：建仓库（网页两步）

- 想要 **用户站**（网址最干净，推荐）：建仓库，名字必须**恰好等于** `<用户名>.github.io`
- 想要 **项目站**：仓库名随意（如 `homepage`），网址会带子目录 `/<仓库名>/`
- 可见性选 **Public**（Pages 免费版要求公开仓库）→ Create repository（**不要**勾选初始化 README）

## 第 2 步：推送（服务器上一条命令）

```bash
cd ~/personal-site
bash tools/push-github.sh <用户名>/<仓库名> main
# 例：bash tools/push-github.sh liuhaiyang/liuhaiyang.github.io main
```

脚本会依次：检查工作区是否干净 → 设远端 → 测 SSH 认证 → 推送 → 提示启用 Pages。

若你愿意提供一个临时 **Personal Access Token**（作用域勾 `repo` 即可），脚本还能顺手用 API 启用 Pages：

```bash
bash tools/push-github.sh <用户名>/<仓库名> main <TOKEN>
```
（不提供也行：仓库 **Settings → Pages → Source 选 `main` 与 `/(root)` → Save**。）

## 第 3 步：验证与收尾

```bash
# 1) 等 1–2 分钟，确认网址返回 200
curl -s -o /dev/null -w 'HTTP %{http_code}\n' https://<用户名>.github.io/

# 2) 把站点内的占位域名换成真实网址（canonical/og/hreflang/sitemap/robots 一起改）
cd ~/personal-site && python3 tools/set-domain.py <用户名>.github.io     # 或 <用户名>.github.io/<仓库名>

# 3) 提交并再推一次
git add -A && git -c user.name='Liu Haiyang' -c user.email='noreply@example.com' \
  commit -m "域名替换为 GitHub Pages 地址" && git push
```

## 以后想绑自己的域名（推荐，对百度友好得多）

1. `python3 tools/set-domain.py 你的域名`（脚本会写 CNAME 文件并改所有链接）。
2. 域名 DNS 加记录：
   - 根域 `@` → A 记录指向 GitHub Pages 的四个 IP：`185.199.108.153`、`185.199.109.153`、`185.199.110.153`、`185.199.111.153`
   - `www` → CNAME 指向 `<用户名>.github.io`
3. 仓库 Settings → Pages → Custom domain 填域名 → 勾 **Enforce HTTPS**。
4. 到 **ziyuan.baidu.com** 添加站点、完成验证、提交 `https://你的域名/sitemap.xml`，再跑 `bash tools/baidu-push.sh 你的域名 <token>` 主动推送。

## 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| `push-github.sh` 在第 3 步失败 | 公钥没加到 GitHub，或加错了账号；到 https://github.com/settings/keys 核对指纹 |
| 网址 404 | Pages 还没构建完（等 1–2 分钟）；或 Source 没设对（要 `main` + `/(root)`）；或仓库名不是 `<用户名>.github.io` 却访问了根域 |
| 页面样式丢失 | 站点里用了绝对路径；本仓全部使用相对路径，若自行改动请保持相对路径 |
| 仓库名写错想改名 | Settings → Repository name 改名，同时更新远端：`git remote set-url origin git@github.com:<用户名>/<新名>.git` |
| 想撤下站点 | Settings → Pages → 关闭，或把仓库设为 Private / 删除仓库 |
