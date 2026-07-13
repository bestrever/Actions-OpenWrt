#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名
sed -i 's/ImmortalWrt/IMOwrt/g' package/base-files/files/bin/config_generate

# 3. 修改默认密码为 root (利用预生成的 shadow hash)
sed -i 's/root:::0:99999:7:::/root:$1$wOQMxYje$c4.B7iJ4\/o2Q\/z7dG.B040:19553:0:99999:7:::/g' package/base-files/files/etc/shadow

# 4. 修改默认主题为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 5. 设置时区为上海
sed -i "s/'UTC'/'CST-8'\n        set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# 6. Web服务器配置 (默认 uhttpd，将 HTTP 重定向至 HTTPS)
# ImmortalWrt 默认就是 uhttpd，这里确保启动时启用 HTTPS
sed -i 's/list listen_https.*/list listen_https\t0.0.0.0:443/g' package/network/services/uhttpd/files/uhttpd.config
sed -i 's/option redirect_https.*/option redirect_https\t1/g' package/network/services/uhttpd/files/uhttpd.config

# 7. 编写首次开机脚本：自动将剩余空间格式化为 ext4 并挂载到 /opt (供 Docker 使用)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-docker-opt-partition
#!/bin/sh
# 仅在第一次启动时运行
if [ ! -f /etc/opt_mounted ]; then
    # 获取系统盘符 (例如 /dev/sda 或 /dev/nvme0n1)
    ROOT_DISK=$(lsblk -d -n -o NAME | head -n 1)
    DISK_PATH="/dev/$ROOT_DISK"
    
    # 自动将剩余空间新建为分区
    echo -e "n\n\n\n\n\nw" | fdisk $DISK_PATH
    
    # 重新加载分区表
    partprobe $DISK_PATH
    sleep 2
    
    # 找到最新生成的分区 (假设为最后一个分区)
    NEW_PART=$(lsblk -l -o NAME $DISK_PATH | tail -n 1)
    NEW_PART_PATH="/dev/$NEW_PART"
    
    # 格式化为 ext4
    mkfs.ext4 $NEW_PART_PATH
    
    # 配置 fstab 自动挂载到 /opt
    uci add fstab mount
    uci set fstab.@mount[-1].target='/opt'
    uci set fstab.@mount[-1].device="$NEW_PART_PATH"
    uci set fstab.@mount[-1].fstype='ext4'
    uci set fstab.@mount[-1].options='rw,sync'
    uci set fstab.@mount[-1].enabled='1'
    uci commit fstab
    
    mkdir -p /opt
    mount $NEW_PART_PATH /opt
    touch /etc/opt_mounted
fi
exit 0
EOF
