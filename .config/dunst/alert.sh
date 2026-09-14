#! /bin/bash

/usr/bin/paplay /home/anlv/.config/dunst/notification.ogg
# $1 = App Name, $2 = Summary, $3 = Body

# Kết hợp tiêu đề và nội dung thông báo
NEW_TEXT=$(echo -e "$2\n$3")

# Kiểm tra nếu nội dung trống thì thoát luôn
if [ -z "$NEW_TEXT" ]; then
    exit 0
fi

# Kiểm tra xem nội dung đã tồn tại trong cliphist chưa
# cliphist list trả về danh sách kèm ID, dùng grep để tìm chính xác nội dung
if cliphist list | cut -f2- | grep -Fxq "$NEW_TEXT"; then
    # Nếu đã có trong cliphist thì thoát, không copy nữa
    exit 0
else
    # Nếu chưa có thì tiến hành copy vào clipboard
    echo -n "$NEW_TEXT" | wl-copy
fi

