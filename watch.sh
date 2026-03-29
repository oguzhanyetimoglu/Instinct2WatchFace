#!/bin/bash

SDK="/Users/oguzhanyetimoglu/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.1-2025-06-19-f69b94140/bin"
PRJ="/Users/oguzhanyetimoglu/Desktop/Instinct2WatchFace"
KEY="/Users/oguzhanyetimoglu/Desktop/developer_key"

echo "🔨 Building..."
"$SDK/monkeyc" \
    -o "$PRJ/bin/Instinct2WatchFace.prg" \
    -f "$PRJ/monkey.jungle" \
    -d instinct2 \
    -y "$KEY" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build OK — restarting simulator..."
killall "simulator" 2>/dev/null
killall "ConnectIQ" 2>/dev/null
killall "monkeydo" 2>/dev/null
sleep 2
"$SDK/connectiq" &
for i in $(seq 1 15); do
    sleep 1
    if pgrep -x "simulator" > /dev/null; then
        sleep 3
        break
    fi
done
"$SDK/monkeydo" "$PRJ/bin/Instinct2WatchFace.prg" instinct2 &
