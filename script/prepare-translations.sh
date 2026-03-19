#!/bin/bash
# prepare-translations.sh - 翻译文件准备脚本

set -e

cd "$(dirname "$0")/.."

echo "Preparing translation files for build..."

# 设置环境变量，跳过夜间翻译获取
export SKIP_FETCH_NIGHTLY_TRANSLATIONS=1
echo "Set SKIP_FETCH_NIGHTLY_TRANSLATIONS=1 to prevent overwriting translations"

# 创建临时目录用于处理翻译文件
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# 创建临时的目标目录结构
mkdir -p "$TEMP_DIR/frontend" "$TEMP_DIR/backend"

# 处理 app 翻译文件
echo "Processing app translations..."
for file in src/translations/app/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if [[ $filename =~ ^([a-zA-Z-]+)-[a-fA-F0-9]+\.json$ ]]; then
            lang_code="${BASH_REMATCH[1]}"
            if [ "$lang_code" != "en" ]; then
                echo "Copying $filename -> $TEMP_DIR/frontend/$lang_code.json"
                cp "$file" "$TEMP_DIR/frontend/$lang_code.json"
            fi
        fi
    fi
done

# 处理 config 翻译文件
echo "Processing config translations..."
for file in src/translations/config/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if [[ $filename =~ ^([a-zA-Z-]+)-[a-fA-F0-9]+\.json$ ]]; then
            lang_code="${BASH_REMATCH[1]}"
            if [ "$lang_code" != "en" ]; then
                echo "Copying $filename -> $TEMP_DIR/backend/$lang_code.json"
                cp "$file" "$TEMP_DIR/backend/$lang_code.json"
            fi
        fi
    fi
done

# 处理 custom 翻译文件
echo "Processing custom translations..."
for file in src/translations/custom/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if [[ $filename =~ ^([a-zA-Z-]+)-[a-fA-F0-9]+\.json$ ]]; then
            lang_code="${BASH_REMATCH[1]}"
            if [ "$lang_code" != "en" ]; then
                echo "Copying $filename -> $TEMP_DIR/frontend/$lang_code.json"
                cp "$file" "$TEMP_DIR/frontend/$lang_code.json"
            fi
        fi
    fi
done

# 将临时目录中的文件移动到最终目标位置
mkdir -p translations/frontend translations/backend
cp -r "$TEMP_DIR/frontend/"* translations/frontend/ 2>/dev/null || true
cp -r "$TEMP_DIR/backend/"* translations/backend/ 2>/dev/null || true

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "Translation files prepared successfully!"