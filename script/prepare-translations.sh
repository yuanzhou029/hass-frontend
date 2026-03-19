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

# 获取所有非英语语言代码
declare -A LANG_CODES

# 收集所有语言代码
for dir in app config custom; do
    for file in src/translations/$dir/*.json; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [[ $filename =~ ^([a-zA-Z-]+)-[a-fA-F0-9]+\.json$ ]]; then
                lang_code="${BASH_REMATCH[1]}"
                if [ "$lang_code" != "en" ]; then
                    LANG_CODES["$lang_code"]=1
                fi
            fi
        fi
    done
done

# 使用Python合并JSON文件的函数
merge_json_files() {
    local lang_code=$1
    local output_file=$2
    local temp_file="$TEMP_DIR/merge_temp.json"
    
    # 临时存储合并结果的Python脚本
    local python_script="$TEMP_DIR/merge_json.py"
    
    # 创建Python合并脚本 - 修正版本，确保所有键都正确合并
    # 特别处理ui.panel.app键的映射
    cat > "$python_script" << 'EOF'
import json
import sys
import os
import glob

lang_code = sys.argv[1]
base_dir = sys.argv[2]

print(f"Processing language: {lang_code}", file=sys.stderr)

result = {}

# 按顺序合并 app, config, custom 目录中的翻译
# 重要：确保所有翻译都合并到同一个结果中
for dir_name in ["app", "config", "custom"]:
    pattern = f"{base_dir}/src/translations/{dir_name}/{lang_code}-*.json"
    files = glob.glob(pattern)
    
    print(f"Looking for files in {dir_name} with pattern: {pattern}", file=sys.stderr)
    print(f"Found {len(files)} files", file=sys.stderr)
    
    if files:
        with open(files[0], 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                print(f"Loaded {len(data)} keys from {files[0]}", file=sys.stderr)
                
                # 将数据合并到结果中，确保所有键都被包含
                for key, value in data.items():
                    result[key] = value
                    # 用于调试
                    if 'error_app_not_installed' in key:
                        print(f"Found key '{key}' with value: {value}", file=sys.stderr)
                        
            except json.JSONDecodeError as e:
                print(f"Warning: Could not decode JSON from {files[0]}: {e}", file=sys.stderr)

print(f"Final result has {len(result)} keys", file=sys.stderr)

# 重要：处理键映射，确保ui.panel.app.*键被正确填充
# 如果存在supervisor.ingress.error_app_not_installed，将其值映射到ui.panel.app.error_app_not_installed
if 'supervisor.ingress.error_app_not_installed' in result and 'ui.panel.app.error_app_not_installed' not in result:
    result['ui.panel.app.error_app_not_installed'] = result['supervisor.ingress.error_app_not_installed']
    print(f"Mapped supervisor.ingress.error_app_not_installed to ui.panel.app.error_app_not_installed", file=sys.stderr)

# 其他常见映射
if 'supervisor.my.error_app_not_installed' in result and 'ui.panel.app.error_app_not_installed' not in result:
    result['ui.panel.app.error_app_not_installed'] = result['supervisor.my.error_app_not_installed']

# 映射其他ui.panel.app相关的键
app_mappings = {
    'supervisor.ingress.error_app_no_ingress': 'ui.panel.app.error_app_no_ingress',
    'supervisor.ingress.error_app_not_running': 'ui.panel.app.error_app_not_running',
    'supervisor.ingress.start_app': 'ui.panel.app.start_app',
    'supervisor.ingress.app_starting': 'ui.panel.app.app_starting',
    'supervisor.ingress.error_starting_app': 'ui.panel.app.error_starting_app',
    'supervisor.ingress.error_creating_session': 'ui.panel.app.error_creating_session',
    'supervisor.ingress.error_app_not_ready': 'ui.panel.app.error_app_not_ready',
    'supervisor.ingress.retry': 'ui.panel.app.retry'
}

for source_key, target_key in app_mappings.items():
    if source_key in result and target_key not in result:
        result[target_key] = result[source_key]
        print(f"Mapped {source_key} to {target_key}", file=sys.stderr)

print(f"After mapping, result has {len(result)} keys", file=sys.stderr)

# 输出合并结果
output_file = sys.argv[3]
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
    
print(f"Written merged translation to {output_file}", file=sys.stderr)
EOF

    # 运行Python脚本进行合并
    python3 "$python_script" "$lang_code" "$(pwd)" "$temp_file" 2>/dev/null || python "$python_script" "$lang_code" "$(pwd)" "$temp_file"
    
    # 检查是否成功生成了合并后的文件
    if [ -s "$temp_file" ]; then
        cp "$temp_file" "$output_file"
        echo "  Merged translation for $lang_code written to $output_file"
    else
        echo "  Warning: Failed to merge translation for $lang_code"
    fi
}

# 处理每种语言
for lang_code in "${!LANG_CODES[@]}"; do
    echo "Processing language: $lang_code"
    
    # 合并 app, config, custom 目录的翻译到 frontend
    merge_json_files "$lang_code" "$TEMP_DIR/frontend/$lang_code.json"
    
    # 合并 config 目录的翻译到 backend
    config_file=$(find "src/translations/config" -name "${lang_code}-*.json" -type f 2>/dev/null | head -n 1)
    if [ -f "$config_file" ]; then
        echo "  Processing config translations for $lang_code..."
        cp "$config_file" "$TEMP_DIR/backend/$lang_code.json"
    fi
done

# 将临时目录中的文件移动到最终目标位置
mkdir -p translations/frontend translations/backend
cp -r "$TEMP_DIR/frontend/"* translations/frontend/ 2>/dev/null || true
cp -r "$TEMP_DIR/backend/"* translations/backend/ 2>/dev/null || true

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "Translation files prepared successfully!"