#!/usr/bin/env python3
"""把站点内的占位域名统一替换成真实域名（canonical / og:url / hreflang / sitemap / robots），
   并写 CNAME（自定义域用）。

用法：
  python3 tools/set-domain.py liuhaiyang.github.io           # GitHub 用户站
  python3 tools/set-domain.py <用户名>.github.io/<仓库名>     # GitHub 项目站
  python3 tools/set-domain.py liuhaiyang.cn                  # 以后绑自定义域
不带参数则只报告当前占位状态，不改文件。
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def site_files():
    """站点内所有含占位域名的文本文件（自动发现，避免新增页面被漏掉）。"""
    import glob
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, "*.html")) + glob.glob(os.path.join(ROOT, "*.xml"))
                    + glob.glob(os.path.join(ROOT, "*.txt"))):
        if os.path.basename(p) in ("README.md",):
            continue
        out.append(os.path.basename(p))
    return out or ["index.html", "en.html", "sitemap.xml", "robots.txt"]

FILES = site_files()

def current_domain():
    """从 index.html 的 canonical 读出当前域名，支持反复改域名（不只 example.com 占位）。"""
    try:
        s = open(os.path.join(ROOT, "index.html"), encoding="utf-8").read()
        m = re.search(r'<link rel="canonical" href="(https://[^"]+)"', s)
        if m:
            return m.group(1).rstrip("/").replace("https://", "", 1)
    except FileNotFoundError:
        pass
    return "example.com"

def report():
    cur = current_domain()
    print(f"  当前域名：{cur}")
    for f in FILES:
        p = os.path.join(ROOT, f)
        s = open(p, encoding="utf-8").read()
        hits = re.findall(rf"https?://{re.escape(cur)}[^\s\"'<>]*", s)
        uniq = sorted(set(hits))
        print(f"    {f:<22} {len(uniq)} 处：{', '.join(uniq[:3])}{' …' if len(uniq) > 3 else ''}")

def main():
    if len(sys.argv) < 2:
        print("  未提供域名 —— 只做检查（不改文件）")
        report()
        print("\n  用法: python3 tools/set-domain.py <域名>       例: liuhaiyang.github.io")
        print("        python3 tools/set-domain.py <用户>.github.io/<仓库>")
        return
    dom = sys.argv[1].strip().strip("/")
    if not re.fullmatch(r"[A-Za-z0-9.-]+(?:/[A-Za-z0-9._-]+)?", dom):
        sys.exit(f"  域名格式不对: {dom}")
    base = f"https://{dom}"
    cur = current_domain()
    changed = 0
    for f in FILES:
        p = os.path.join(ROOT, f)
        s = open(p, encoding="utf-8").read()
        new = s.replace(f"https://{cur}", base).replace("https://example.com", base)
        if new != s:
            open(p, "w", encoding="utf-8").write(new)
            changed += 1
            print(f"  ✔ {f} 已更新")
    print(f"  （原域名 {cur} → {dom}）")
    # 自定义域（非 github.io）才需要 CNAME，用作 GitHub Pages 的域名绑定
    if not dom.endswith("github.io"):
        open(os.path.join(ROOT, "CNAME"), "w").write(dom.split("/")[0] + "\n")
        print(f"  ✔ CNAME 已写入（{dom}）")
    else:
        c = os.path.join(ROOT, "CNAME")
        if os.path.exists(c):
            os.remove(c)
            print("  · 已移除 CNAME（github.io 不需要）")
    print(f"\n  完成：{changed} 个文件更新为 {base}")
    print("  提醒：sitemap.xml 里 <lastmod> 也建议改成今天；百度站长平台的站点域名要与此一致。")

if __name__ == "__main__":
    main()
