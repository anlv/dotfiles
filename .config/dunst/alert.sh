#! /bin/bash
/usr/bin/paplay /home/anlv/.config/dunst/notification.ogg

SUMMARY="$2"
BODY="$3"

# Kết hợp
if [ -n "$SUMMARY" ] && [ -n "$BODY" ]; then
    NEW_TEXT=$(printf '%s\n%s' "$SUMMARY" "$BODY")
elif [ -n "$SUMMARY" ]; then
    NEW_TEXT="$SUMMARY"
elif [ -n "$BODY" ]; then
    NEW_TEXT="$BODY"
else
    exit 0
fi

[ -z "$NEW_TEXT" ] && exit 0

# Lấy danh sách ID (chỉ dòng bắt đầu bằng số + TAB)
mapfile -t IDS < <(cliphist list | grep -oP '^\d+(?=\t)' || cliphist list | awk -F'\t' '/^[0-9]+\t/ {print $1}')

# Duyệt từng ID, decode và so sánh
for id in "${IDS[@]}"; do
    [ -z "$id" ] && continue
    if [ "$(cliphist decode "$id" 2>/dev/null)" = "$NEW_TEXT" ]; then
        exit 0   # Đã từng có → không copy
    fi
done

# Chưa từng có → copy
printf '%s' "$NEW_TEXT" | wl-copy
