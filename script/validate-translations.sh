#!/bin/bash
# validate-translations.sh - 验證翻譯文件是否包含中文內容

echo "開始驗證翻譯文件..."

# 清理並重新準備翻譯文件
rm -rf translations/
./script/prepare-translations.sh

# 遣行構建過程
npx gulp build-translations

# 檢查構建輸出中的中文翻譯
echo "檢查總體中文翻譯..."
ZH_FILE="build/translations/output/zh-Hans-dev.json"

if [ -f "$ZH_FILE" ]; then
    DEMO_COUNT=$(grep -o '"panel\.demo"[^}]*:[^}]*"演示\|Demo' "$ZH_FILE" | wc -l)
    CONFIG_COUNT=$(grep -o '"panel\.config"[^}]*:[^}]*"设置\|Settings' "$ZH_FILE" | wc -l)
    STATES_COUNT=$(grep -o '"panel\.states"[^}]*:[^}]*"概览\|Overview' "$ZH_FILE" | wc -l)
    
    echo "找到 '演示'(Demo) 翻譯: $DEMO_COUNT 個"
    echo "找到 '设置'(Settings) 翻譯: $CONFIG_COUNT 個"
    echo "找到 '概览'(Overview) 翻譯: $STATES_COUNT 個"
    
    TOTAL_ZH=$(grep -o '[^"]*概览\|设置\|演示\|首页\|地图\|历史\|媒体' "$ZH_FILE" | wc -l)
    echo "總共找到中文翻譯: $TOTAL_ZH 個"
    
    if [ $TOTAL_ZH -gt 10 ]; then
        echo "✓ 驗建成功：翻譯文件包含大量中文內容"
    else
        echo "✗ 驗建問題：翻譯文件中文內容不足"
    fi
else
    echo "✗ 錝建失敗：未找到中文翻譯文件"
fi

echo "驗證完成"