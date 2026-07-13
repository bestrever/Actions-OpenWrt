#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

# 1. 添加 iStore 源
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default

# 2. 替换 Passwall 仓库为 Openwrt-Passwall (包含核心与依赖)
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default

# 注：Mihomo, MosDNS, SSR-Plus, HomeProxy 和 CloudflareSpeedtest 
# 通常已包含在 ImmortalWrt 24.10 的自带源中，无需额外引入。
