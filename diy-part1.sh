#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)
set -e

echo "=== 开始配置自定义源 ==="

# 备份原始 feeds 配置
cp feeds.conf.default feeds.conf.default.bak

# 1. 添加 iStore 源（文件管理、应用商店）
echo "[INFO] 添加 iStore 源..."
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default

# 2. 添加 Passwall 和 Passwall2 源（两个版本都需要）
echo "[INFO] 添加 Passwall 源..."
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default

# 3. 添加 Passwall2 源（新版本，功能更完整）
echo "[INFO] 添加 Passwall2 源..."
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main' >> feeds.conf.default

# 4. 添加 HomeProxy 源（Clash 代理）
echo "[INFO] 添加 HomeProxy 源..."
echo 'src-git homeproxy https://github.com/immortalwrt/homeproxy.git;main' >> feeds.conf.default

# 5. 添加 MosDNS 源（DNS 解析工具）
echo "[INFO] 添加 MosDNS 源..."
echo 'src-git mosdns https://github.com/sbwml/luci-app-mosdns.git;main' >> feeds.conf.default

# 6. 添加 Mihomo 源（Clash Meta 实现）
echo "[INFO] 添加 Mihomo 源..."
echo 'src-git mihomo https://github.com/morytyann/OpenWrt-Mihomo.git;main' >> feeds.conf.default

# 7. 添加 SSR-Plus 源（SSR 客户端 - 从 fw876 维护）
echo "[INFO] 添加 SSR-Plus 源..."
echo 'src-git ssrplus https://github.com/fw876/helloworld.git;main' >> feeds.conf.default

# 8. 添加 CloudflareSpeedtest 源
echo "[INFO] 添加 CloudflareSpeedtest 源..."
echo 'src-git cloudflarespeedtest https://github.com/immortalwrt/luci-app-cloudflarespeedtest.git;main' >> feeds.conf.default

# 9. 显示当前已添加的所有源
echo ""
echo "=== 已配置的自定义源 ==="
grep -E '^src-git' feeds.conf.default | tail -n +1 || echo "[WARN] 未找到任何 src-git 源"

echo ""
echo "✓ 自定义源配置完成"
echo "[TIPS] 后续执行 './scripts/feeds update -a' 更新所有源"
echo "[TIPS] 然后执行 './scripts/feeds install -a' 安装所有包"
