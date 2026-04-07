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

PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep 'PrivateKey' | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep 'PublicKey' | awk '{print $3}')

echo ""
echo "=============================="
echo "UUID: $UUID"
echo "PublicKey: $PUBLIC_KEY"
echo "PrivateKey: $PRIVATE_KEY"
echo "=============================="
