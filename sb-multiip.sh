#!/usr/bin/env bash

clear
echo "======================================"
echo "   Sing-box Multi-IP Installer"
echo "======================================"

# 检测 IPv4
IPS=($(ip -4 addr show scope global | awk '/inet /{print $2}' | cut -d/ -f1))

echo ""
echo "检测到以下IP："
for i in "${!IPS[@]}"; do
  echo "$((i+1)). ${IPS[$i]}"
done

echo ""
echo "请选择模式："
echo "1. 单IP"
echo "2. 双IP"
echo "3. 自定义多IP"
read -p "输入选项: " MODE

SELECTED_IPS=()

case "$MODE" in
  1)
    SELECTED_IPS=("${IPS[0]}")
    ;;
  2)
    SELECTED_IPS=("${IPS[0]}" "${IPS[1]}")
    ;;
  3)
    echo "输入IP编号（空格分隔，例如: 1 2）:"
    read -a IDX
    for i in "${IDX[@]}"; do
      SELECTED_IPS+=("${IPS[$((i-1))]}")
    done
    ;;
  *)
    echo "无效选项"
    exit 1
    ;;
esac

echo ""
echo "你选择的IP："
for ip in "${SELECTED_IPS[@]}"; do
  echo "- $ip"
done
echo ""
echo "正在生成节点参数..."

# UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Reality 密钥
KEY_OUTPUT=$(xray x25519 2>/dev/null)

PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep 'PrivateKey' | awk -F': ' '{print $2}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep 'PublicKey' | awk -F': ' '{print $2}')

echo ""
echo "=============================="
echo "UUID: $UUID"
echo "PublicKey: $PUBLIC_KEY"
echo "PrivateKey: $PRIVATE_KEY"
echo "=============================="
CONFIG_FILE="./sb-multiip-config.json"

echo ""
echo "正在生成配置文件: $CONFIG_FILE"

cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "level": "info"
  },
  "inbounds": [
EOF

for i in "${!SELECTED_IPS[@]}"; do
  ip="${SELECTED_IPS[$i]}"
  tag="in-ip$((i+1))"
  short_id=$(openssl rand -hex 8)
  server_name="www.microsoft.com"

  [ "$i" -gt 0 ] && echo "," >> "$CONFIG_FILE"

  cat >> "$CONFIG_FILE" <<EOF
    {
      "type": "vless",
      "tag": "$tag",
      "listen": "$ip",
      "listen_port": 443,
      "users": [
        {
          "uuid": "$UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$server_name",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "$server_name",
            "server_port": 443
          },
          "private_key": "$PRIVATE_KEY",
          "short_id": ["$short_id"]
        }
      }
    }
EOF
done

cat >> "$CONFIG_FILE" <<EOF
  ],
  "outbounds": [
EOF

for i in "${!SELECTED_IPS[@]}"; do
  ip="${SELECTED_IPS[$i]}"
  tag="out-ip$((i+1))"

  [ "$i" -gt 0 ] && echo "," >> "$CONFIG_FILE"

  cat >> "$CONFIG_FILE" <<EOF
    {
      "type": "direct",
      "tag": "$tag",
      "inet4_bind_address": "$ip"
    }
EOF
done

cat >> "$CONFIG_FILE" <<EOF
  ],
  "route": {
    "rules": [
EOF

for i in "${!SELECTED_IPS[@]}"; do
  in_tag="in-ip$((i+1))"
  out_tag="out-ip$((i+1))"

  [ "$i" -gt 0 ] && echo "," >> "$CONFIG_FILE"

  cat >> "$CONFIG_FILE" <<EOF
      {
        "inbound": ["$in_tag"],
        "outbound": "$out_tag"
      }
EOF
done

cat >> "$CONFIG_FILE" <<EOF
    ]
  }
}
EOF

echo ""
echo "配置文件已生成完成:"
echo "$CONFIG_FILE"
