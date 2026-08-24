#!/bin/bash

# Lấy dòng thông tin Profile từ TLP
# Ví dụ: "TLP profile = performance/AC (manual)" hoặc "TLP profile = power-save/BAT (auto)"
TLP_LINE=$(sudo tlp-stat -s 2>/dev/null | grep "TLP profile")

# Kiểm tra xem có đang bị khóa thủ công hay không (chứa chữ "manual")
if echo "$TLP_LINE" | grep -q "manual"; then
    # Nếu chứa "performance/AC" thì là perf, ngược lại là save
    if echo "$TLP_LINE" | grep -q "performance/AC"; then
        CURRENT="perf"
    else
        CURRENT="save"
    fi
elif echo "$TLP_LINE" | grep -q "power-saver"; then
    CURRENT="power-saver"
else
    CURRENT="auto"
fi

case "$1" in
    "toggle")
        if [ "$CURRENT" = "auto" ]; then
            sudo tlp power-saver >/dev/null 2>&1
        elif [ "$CURRENT" = "power-saver" ]; then
            sudo tlp bat >/dev/null 2>&1
        elif [ "$CURRENT" = "save" ]; then
            sudo tlp ac >/dev/null 2>&1
        else
            sudo tlp start >/dev/null 2>&1
        fi
        
        # Kích hoạt cập nhật giao diện Waybar ngay lập tức
        pkill -SIGRTMIN+8 waybar
        ;;
        
    "status")
        if [ "$CURRENT" = "perf" ]; then
            echo '{"text": "⚡", "alt": "perf", "tooltip": "TLP: Đang Khóa Hiệu năng cao (AC)", "class": "performance"}'
        elif [ "$CURRENT" = "save" ]; then
            echo '{"text": "⚖️", "alt": "save", "tooltip": "TLP: Đang Khóa Cân Bằng (BAT)", "class": "save"}'
        elif [ "$CURRENT" = "power-saver" ]; then
            echo '{"text": "🌱", "alt": "power-save", "tooltip": "TLP: Đang Khóa Tiết Kiệm Pin", "class": "powersave"}'
        else
            # Lấy nguồn điện thực tế từ TLP để hiển thị trong chế độ Auto
            REAL_SOURCE=$(sudo tlp-stat -s 2>/dev/null | grep "Power source" | awk '{print $4}')
            echo '{"text": "🤖", "alt": "auto", "tooltip": "TLP: Tự động (Hiện tại: '"$REAL_SOURCE"')", "class": "auto"}'
        fi
        ;;
esac

