# AGENTS.md - Home Assistant 前端开发指南

本指南为在 Home Assistant 前端仓库工作的代理提供必要信息。

## 构建、Lint 和测试命令

### 基本命令

```bash
# Lint 和格式化
yarn lint              # 运行所有 linter (ESLint + Prettier + TypeScript + Lit)
yarn format            # 自动修复 ESLint + Prettier 问题
yarn lint:eslint       # 仅 ESLint
yarn format:eslint     # ESLint 自动修复
yarn lint:prettier     # Prettier 检查
yarn format:prettier   # Prettier 自动修复
yarn lint:types        # TypeScript 类型检查（不带文件参数！）
yarn lint:lit          # Lit 分析器

# 测试
yarn test              # 使用 Vitest 运行所有测试
yarn test:coverage     # 运行测试并生成覆盖率报告

# 构建
yarn build             # 构建前端（script/build_frontend 的别名）
script/build_frontend  # 完整构建流程
script/release         # 构建并创建发布包
```

### 关键 TypeScript 警告

**绝不要使用文件参数运行 `yarn lint:types` 或 `tsc`**（例如 `yarn lint:types src/file.ts`）。当 tsc 接收文件参数时，它会忽略 `tsconfig.json` 并将 `.js` 文件输出到 `src/`，污染代码库。始终不带参数运行。如果意外生成了 `.js` 文件，使用 `git clean -fd src/` 清理。

## 代码风格指南

### TypeScript 和导入

- **严格 TypeScript**：启用所有严格标志，避免 `any` 类型
- **类型导入**：对仅类型导入使用 `import type`
- **一致导入**：使用 `@typescript-eslint/consistent-type-imports`
- **无未使用导入**：ESLint 强制执行；未使用变量前缀为 `_`
- **正确接口**：为所有数据结构定义接口

```typescript
// 好的做法
import type { HomeAssistant } from "../types";
import { fireEvent } from "../common/dom/fire_event";

interface EntityConfig {
  entity: string;
  name?: string;
}

// 不好的做法
import { HomeAssistant } from "../types";
const hass: any = ...;
```

### 命名约定

- **PascalCase**：类型、类、接口、自定义元素
- **camelCase**：变量、方法、函数
- **私有方法**：需要前导下划线（`_methodName`）
- **公共方法**：禁止前导下划线
- **组件前缀**：`ha-`（Home Assistant）、`hui-`（Lovelace UI）、`dialog-`（对话框）

### 格式化和 Lint

- **ESLint**：扩展 Airbnb、TypeScript 严格、Lit、Web Components、可访问性
- **Prettier**：强制 ES5 尾随逗号
- **无 console 语句**：使用正确的日志记录（`no-console: "error"`）
- **行长度**：Prettier 默认（80 字符），除了 `*.globals.ts` 文件（9999 字符）

### Lit Web Components

- **使用 Lit 3.x 模式**：需要现代 Lit 实践
- **扩展 LitElement**：使用 `LitElement`、`SubscribeMixin` 或其他 mixin
- **自定义元素名称**：使用 `@customElement("ha-component")`
- **属性**：使用 `@property()` 表示公共 API，`@state()` 表示内部状态
- **样式**：使用 `static get styles()` 和 `css` 模板字面量
- **渲染**：实现返回 `html` 模板的 `render()` 方法

```typescript
@customElement("ha-my-component")
export class HaMyComponent extends LitElement {
  @property({ attribute: false })
  hass!: HomeAssistant;

  @state()
  private _config?: MyConfig;

  static get styles() {
    return css`
      :host {
        display: block;
        padding: var(--ha-space-4);
      }
    `;
  }

  render() {
    return html`<div>内容</div>`;
  }
}
```

### 样式最佳实践

- **CSS 自定义属性**：使用主题变量（`--primary-text-color`、`--card-background-color`）
- **间距令牌**：使用 `--ha-space-*`（1-20，4px 增量）而不是硬编码值
- **移动优先**：为移动设备设计，为桌面增强
- **RTL 支持**：确保布局在 RTL 语言中工作
- **Material Design**：在适当的地方使用 Material Web Components

### 错误处理和数据管理

- **Try-catch 块**：所有 API 调用必须有错误处理
- **WebSocket API**：使用 `home-assistant-js-websocket` 进行后端通信
- **优雅降级**：处理加载、错误和不可用状态
- **实时更新**：订阅状态变化以获取实时数据

```typescript
try {
  const result = await fetchEntityRegistry(this.hass.connection);
  this._processRe(result);
} catch (err) {
  showAlertDialog(this, {
    text: `加载失败：${err.message}`,
  });
}
```

## 常见模式

### 创建面板

```typescript
@customElement("ha-panel-myfeature")
export class HaPanelMyFeature extends SubscribeMixin(LitElement) {
  @property({ attribute: false })
  hass!: HomeAssistant;

  @property({ type: Boolean, reflect: true })
  narrow!: boolean;

  hassSubscribe() {
    return [
      subscribeEntityRegistry(this.hass.connection, (entities) => {
        this._entities = entities;
      }),
    ];
  }
}
```

### 对话框实现

- 使用 `ha-dialog` 组件和 `HassDialog<T>` 接口
- 使用 `@state() private _open = false` 控制对话框可见性
- 关闭时触发 `dialog-closed` 事件
- 使用 `header-title` 和 `header-subtitle` 属性
- 使用 `ha-dialog-footer` 和 `primaryAction`/`secondaryAction` 插槽
- 为第一个可聚焦元素添加 `autofocus`

### 国际化

- 始终使用 `this.hass.localize()` 处理用户面向文本
- 在 `translations/en.json` 中添加翻译键
- 对动态内容使用占位符

```typescript
this.hass.localize("ui.panel.config.updates.update_available", {
  count: 5,
});
```

## Copilot 指令参考

详细的组件库、可访问性、性能、安全性和审查要求指南，请参考 `.github/copilot-instructions.md`。关键部分包括：

- **组件库**：Dialog、Form (ha-form)、Alert (ha-alert)、Tooltip、键盘快捷键
- **可访问性**：ARIA 标签、键盘导航、屏幕阅读器支持、WCAG AA 对比度
- **性能**：代码分割、延迟加载、虚拟滚动、记忆化
- **安全性**：HTML 清理、输入验证、HTTPS、CSP 合规性
- **审查清单**：TypeScript、ESLint、Prettier、Lit 分析器、测试、翻译

## 文本和复制指南

- **删除 vs 移除**：删除 = 永久（删除任务），移除 = 可逆（移除权限）
- **创建 vs 添加**：创建 = 从头开始（创建组），添加 = 现有项目（添加用户到组）
- **术语**：使用"集成"而不是"组件"，完整的"Home Assistant"（从不"HA"）
- **句子大小写**：所有文本（标题、按钮、标签）使用句子大小写，不是标题大小写
- **美式英语**：标准拼写和术语
- **主动语态**："删除自动化"而不是"自动化应该被删除"
- **避免行话**：使用家庭自动化用户熟悉的术语

## 项目结构

- ` - 主源代码（TypeScript、Lit 组件）
- `test/` - 测试文件（Vitest）
- `gallery/` - 组件文档和示例
- `build-scripts/` - 构建工具
- `script/` - 开发脚本
- `.github/` - GitHub 工作流和模板
- `pyproject.toml` - Python 包配置（用于 PyPI 发布）

## 关键依赖

- **Lit 3.3.2**：Web Components 框架
- **TypeScript 5.9.3**：类型检查
- **Vitest 4.0.18**：测试框架
- **ESLint 9.39.4**：Lint 工具
- **Prettier 3.8.1**：代码格式化
- **Rspack 1.7.8**：构建打包器
- **Material Web 2.4.1**：UI 组件

## 开发工作流

1. 从 main 创建功能分支
2. 按照代码风格指南进行更改
3. 运行 `yarn lint` 检查所有 linter
4. 运行 `yarn format` 自动修复问题
5. 运行 `yarn test` 验证测试通过
6. 使用 `.github/PULL_REQUEST_TEMPLATE.md` 创建 PR
7. 确保所有检查通过后再合并

## 常见陷阱

- 不要使用 `querySelector` - 使用 ref 或组件属性
- 不要直接操作 DOM - 让 Lit 处理渲染
- 不要使用全局样式 - 将样式限定在组件范围内
- 不要阻塞主线程 - 对繁重计算使用 Web Worker
- 不要忽视 TypeScript 错误 - 修复所有类型问题
- 不要硬编码文本 - 始终使用本地化
- 不要忘记错误处理 - 所有异步操作都需要 try-catch
