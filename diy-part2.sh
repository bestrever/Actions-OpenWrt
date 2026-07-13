#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)
set -e

echo "=== OpenWrt 自定义配置开始 ==="

# 1. 修改默认 IP
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
    echo "✓ 默认 IP 已改为 192.168.5.1"
fi

# 2. 修改默认主机名
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i 's/ImmortalWrt/IMOwrt/g' package/base-files/files/bin/config_generate
    echo "✓ 默认主机名已改为 IMOwrt"
fi

# 3. 修改默认密码为 root (利用预生成的 shadow hash)
if [ -f "package/base-files/files/etc/shadow" ]; then
    sed -i 's/root:::0:99999:7:::/root:$1$wOQMxYje$c4.B7iJ4\/o2Q\/z7dG.B040:19553:0:99999:7:::/g' package/base-files/files/etc/shadow
    echo "✓ 默认密码已设置"
fi

# 4. 修改默认主题为 Argon
if [ -f "feeds/luci/collections/luci/Makefile" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
    echo "✓ 默认主题已改为 Argon"
fi

# 5. 设置时区为上海
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
    echo "✓ 时区已设置为 CST-8（上海）"
fi

# 6. Web服务器配置 (默认 uhttpd，将 HTTP 重定向至 HTTPS)
if [ -f "package/network/services/uhttpd/files/uhttpd.config" ]; then
    sed -i 's/list listen_https.*/list listen_https\t0.0.0.0:443/g' package/network/services/uhttpd/files/uhttpd.config
    sed -i 's/option redirect_https.*/option redirect_https\t1/g' package/network/services/uhttpd/files/uhttpd.config
    echo "✓ uhttpd HTTPS 已配置"
fi

# 7. 编写首次开机脚本：自动将剩余空间格式化为 ext4 并挂载到 /opt (供 Docker 使用)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-docker-opt-partition
#!/bin/sh
# Docker /opt 自动分区脚本（首次启动时运行）

if [ ! -f /etc/opt_mounted ]; then
    echo "[INFO] 开始配置 Docker /opt 分区..."
    
    # 1. 识别系统盘（更可靠的方法）
    BOOT_DISK=$(lsblk -d -l -o NAME,MOUNTPOINT 2>/dev/null | grep " /$" | awk '{print $1}')
    
    if [ -z "$BOOT_DISK" ]; then
        echo "[WARN] 无法识别系统盘，跳过自动分区"
        touch /etc/opt_mounted
        exit 0
    fi
    
    # 移除分区号，获取磁盘设备名
    DISK_PATH="/dev/${BOOT_DISK%[0-9]*}"
    
    if [ ! -b "$DISK_PATH" ]; then
        echo "[ERROR] 磁盘路径无效: $DISK_PATH"
        touch /etc/opt_mounted
        exit 1
    fi
    
    echo "[INFO] 检测到系统盘: $DISK_PATH"
    
    # 2. 使用 parted 创建新分区（更安全可靠）
    if command -v parted >/dev/null 2>&1; then
        echo "[INFO] 使用 parted 创建分区..."
        LAST_SECTOR=$(parted -s "$DISK_PATH" print 2>/dev/null | tail -2 | head -1 | awk '{print $3}')
        
        if [ -n "$LAST_SECTOR" ]; then
            parted -s "$DISK_PATH" mkpart primary ext4 "$LAST_SECTOR" "100%" 2>/dev/null || {
                echo "[WARN] parted 分区创建失败，尝试使用 fdisk..."
                echo -e "n\np\n\n\n\nw" | fdisk "$DISK_PATH" 2>/dev/null || true
            }
        fi
    else
        echo "[INFO] 使用 fdisk 创建分区..."
        echo -e "n\np\n\n\n\nw" | fdisk "$DISK_PATH" 2>/dev/null || {
            echo "[WARN] fdisk 分区创建失败"
        }
    fi
    
    # 3. 等待系统识别新分区
    sleep 3
    udevadm settle 2>/dev/null || sleep 1
    
    # 4. 找到新分区
    NEW_PART=$(lsblk -l -n -o NAME "$DISK_PATH" 2>/dev/null | tail -n 1)
    NEW_PART_PATH="/dev/$NEW_PART"
    
    if [ ! -b "$NEW_PART_PATH" ]; then
        echo "[ERROR] 新分区识别失败"
        touch /etc/opt_mounted
        exit 1
    fi
    
    echo "[INFO] 新分区: $NEW_PART_PATH"
    
    # 5. 格式化为 ext4
    echo "[INFO] 格式化为 ext4..."
    mkfs.ext4 -F -L "docker-opt" "$NEW_PART_PATH" >/dev/null 2>&1 || {
        echo "[ERROR] ext4 格式化失败"
        touch /etc/opt_mounted
        exit 1
    }
    
    # 6. 获取 UUID 用于挂载（更可靠）
    PART_UUID=$(blkid -s UUID -o value "$NEW_PART_PATH" 2>/dev/null)
    
    # 7. 配置 fstab（使用 UUID 更可靠）
    echo "[INFO] 配置 fstab..."
    uci add fstab mount
    
    if [ -n "$PART_UUID" ]; then
        uci set fstab.@mount[-1].device="UUID=$PART_UUID"
        echo "[INFO] 使用 UUID 挂载: $PART_UUID"
    else
        uci set fstab.@mount[-1].device="$NEW_PART_PATH"
        echo "[INFO] 使用设备路径挂载: $NEW_PART_PATH"
    fi
    
    uci set fstab.@mount[-1].target='/opt'
    uci set fstab.@mount[-1].fstype='ext4'
    uci set fstab.@mount[-1].options='defaults,nofail'
    uci set fstab.@mount[-1].enabled='1'
    uci commit fstab
    
    # 8. 创建挂载点并挂载
    mkdir -p /opt
    mount /opt 2>/dev/null || {
        echo "[WARN] 首次挂载失败，将在重启后挂载"
    }
    
    touch /etc/opt_mounted
    echo "[INFO] Docker /opt 分区配置完成"
fi

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-docker-opt-partition
echo "✓ Docker /opt 自动分区脚本已更新（更安全可靠）"

echo "=== OpenWrt 自定义配置完成 ==="
