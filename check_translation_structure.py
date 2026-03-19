import json

try:
    with open('translations/frontend/zh-Hans.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        print('Has panel key:', 'panel' in data)
        if 'panel' in data:
            print('Panel keys:', list(data['panel'].keys()))
        else:
            print('Top level keys:', list(data.keys())[:10])
            # Check for ui.panel structure
            if 'ui' in data and 'panel' in data['ui']:
                print('Has ui.panel structure:', list(data['ui']['panel'].keys()))
except Exception as e:
    print(f"Error: {e}")
    # Try to read first few lines to see the structure
    with open('translations/frontend/zh-Hans.json', 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i < 10:
                print(line.strip())
            else:
                break