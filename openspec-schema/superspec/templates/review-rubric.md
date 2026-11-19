# Review Rubric — onePress V3.2 编码前评审判定表

> 本文件是 L2 评分、认知负荷阈值、AI Slop 清单与 L1 断言清单的**唯一来源**。
> 四份 `opsx-review` 命令体与三份 carrier skill 只引用本路径，不得复制锚点正文。
> 评分为**观察模式**：记录不单独阻断；阻断只由 `P0 > 0` 或 `P1 > 0` 触发。认知负荷与 P2/P3 均为建议项，不阻断 apply。

## 1. 缺陷级别（阻断判据）

| 级别 | 定义 | 是否阻断 |
|---|---|---|
| `P0 Blocking` | 违反 WCAG CRITICAL、契约缺章、关键流程不可用、Token 缺失导致文字不可读 | 是 |
| `P1 Major` | 四态缺失、热区不达标、暗色对比度不足、关键流程无法表达 | 是 |
| `P2 Minor` | 间距不一致、图标粗细不统一、次要文案层级混乱、单层列表 >8、单决策点并列选项 >4 | 否（建议） |
| `P3 Polish` | 微动效曲线、空态插图风格、非关键对齐 | 否（建议） |

准入线：`P0 = 0 且 P1 = 0`。`Critique ≥ 28/40` 与 `Audit ≥ 14/20` 仅作为观察信号记录，阈值校准前不阻断。

## 2. Critique 40 分制（尼尔森 10 项，每项 0–4）

> 4 = 无问题；3 = 轻微；2 = 中等；1 = 严重；0 = 灾难；不适用记 `n/a` 后按已评项折算。
> 这是项目自定义评分表，**不是** NN/g 的严重度量表（NN/g 的 0–4 用于单个问题的严重度）。

| # | 原则 | 0 分典型 | 4 分典型 |
|---|---|---|---|
| 1 | 系统状态可见 | 无 Loading / 无反馈 | 四态齐备且时序自然 |
| 2 | 系统与现实匹配 | 术语与用户语言脱节 | 文案与领域一致 |
| 3 | 用户控制与自由 | 破坏操作无确认 | 可撤销/二次确认齐备 |
| 4 | 一致性与标准 | 同类控件样式不一 | Token 与组件复用一致 |
| 5 | 错误预防 | 允许非法输入后才报错 | 约束前置、防呆完整 |
| 6 | 识别优于回忆 | 需要记住上一步信息 | 上下文与默认值充分 |
| 7 | 灵活性与效率 | 仅有单一路径 | 快捷键/批量为可选增强 |
| 8 | 美学与极简 | 信息过载、跳级标题 | 层级清晰、留白合理 |
| 9 | 帮助用户识别与修复错误 | 错误无定位、无建议 | 内联错误 + 修复建议 |
| 10 | 帮助与文档 | 关键概念无解释 | 就地提示与空态引导 |

**硬性认知负荷检查（不满足记 `P2` 建议，由人类决定是否升级）**：

1. 单层列表 ≤8 个未分组项；超出建议分组或分页。
2. 单一决策点并列可见选项 ≤4；超出建议改用次级页面或渐进披露。

## 3. Audit 20 分制（5 维，每维 0–4）

| 维度 | 检查点 |
|---|---|
| A11y | WCAG 2.2 AA：对比度、焦点可见、表单关联、装饰图标语义 |
| 性能预留 | `Loading` 骨架等高（CLS < 0.1）、动画只改变 opacity/transform、无布局抖动 |
| 主题变量覆盖 | 16 通道 Light/Dark 全量定义，无硬编码色值，`Ring` 暗底 ≥3:1 |
| 响应式排版 | 375/768/1024/1280 零横向滚动；长串折行；Chip/Badge 可展开 |
| 实现完整性 | 四态、防呆、热区、`prefers-reduced-motion`、错误文案与 CTA 齐备 |

## 4. AI Slop 62 类摘要（一票否决项摘录）

- 局促内边距（卡片内边距 <12px）或全站无节奏的等距堆叠；
- 跳级标题（h1 → h3）、标题无层级、正文与标签同权重；
- 缺按压态 / 缺 disabled 态 / 仅 hover 可发现；
- 紫粉渐变、发光阴影、玻璃拟态滥用；
- 灰字配灰底、暗色边框与背景无明度差；
- 图标粗细混用、Emoji 充当功能图标；
- 占位文案（Lorem ipsum）与无意义空态插图；
- 数字未对齐、表格无 `overflow-x-auto`、长标识符撑破布局。

> 完整 62 条以评审子代理逐条比对为准；该摘要只用于快速自查。

## 5. L1 断言清单

| # | 断言 | 判据 |
|---|---|---|
| 1 | WCAG 2.2 AA | `AxeBuilder.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])` 零 violations（排除 `#sandbox-control-bar`） |
| 2 | 触控热区 | `button` / `[role=button]` / `input` / `select` / `a[class*=btn]` 渲染尺寸 ≥44×44；行内文本链接豁免 |
| 3 | 多视口防破版 | 375/768/1024/1280 下 `scrollWidth ≤ clientWidth` |
| 4 | 反模式 | CSS 变量声明块之外零 Hex；零 Emoji 功能图标 |
| 5 | CLS | 状态切换 `PerformanceObserver('layout-shift')` 累计 <0.1（沙箱代理指标） |

依赖缺失（Playwright / axe）时记 `L1: SKIP（<原因>）`，不阻断 L2/L3，不触发 `npm install`。

## 6. L1 脚本附录（唯一可执行副本）

```ts
// scripts/sandbox-preflight.spec.ts（模板包与变更 .review/ 目录同源）
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import path from 'path';

const sandboxPath = process.env.SANDBOX_PATH;
if (!sandboxPath) throw new Error('请指定 SANDBOX_PATH 环境变量');
const fileUrl = `file://${path.resolve(sandboxPath)}`;
const STATES = ['idle', 'loading', 'empty', 'error'];
const THEMES = ['light', 'dark'];

test.describe('onePress L1 sandbox pre-flight', () => {
  for (const theme of THEMES) {
    for (const state of STATES) {
      test(`[${theme}/${state}] a11y, targets, overflow, hex`, async ({ page }) => {
        await page.setViewportSize({ width: 1280, height: 800 });
        await page.goto(fileUrl);
        const themeBtn = page.locator(`[data-set-theme="${theme}"]`);
        if (await themeBtn.count() > 0) await themeBtn.click();
        const stateBtn = page.locator(`[data-set-state="${state}"]`);
        if (await stateBtn.count() > 0) await stateBtn.click();

        const axe = await new AxeBuilder({ page })
          .exclude('#sandbox-control-bar')
          .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
          .analyze();
        expect(axe.violations, JSON.stringify(axe.violations, null, 2)).toEqual([]);

        const undersized = await page
          .locator('main button, main [role="button"], main input, main select, main a[class*="btn"]')
          .evaluateAll((els) => els
            .filter((el) => {
              const s = window.getComputedStyle(el);
              return s.display !== 'none' && s.visibility !== 'hidden';
            })
            .map((el) => {
              const r = el.getBoundingClientRect();
              return { tag: el.tagName, text: (el.textContent || '').trim().slice(0, 24), w: Math.round(r.width), h: Math.round(r.height) };
            })
            .filter((i) => i.w < 44 || i.h < 44));
        expect(undersized, '存在 <44x44 的交互热区').toEqual([]);

        for (const width of [375, 768, 1024, 1280]) {
          await page.setViewportSize({ width, height: 812 });
          const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
          expect(overflow, `${width}px 出现横向溢出`).toBe(false);
        }

        const cls = await page.evaluate(async () => {
          const entries: number[] = [];
          const obs = new PerformanceObserver((list) => {
            for (const e of list.getEntries() as unknown as Array<{ value: number; hadRecentInput: boolean }>) {
              if (!e.hadRecentInput) entries.push(e.value);
            }
          });
          obs.observe({ type: 'layout-shift', buffered: true });
          await new Promise((r) => setTimeout(r, 300));
          obs.disconnect();
          return entries.reduce((a, b) => a + b, 0);
        });
        expect(cls, 'CLS 超过 0.1（沙箱代理指标）').toBeLessThan(0.1);

        const hexOutsideVars = await page.evaluate(() =>
          Array.from(document.styleSheets).flatMap((sheet) => {
            let rules: CSSRuleList = [] as unknown as CSSRuleList;
            try { rules = sheet.cssRules; } catch { return []; }
            return Array.from(rules)
              .filter((r) => !(r instanceof CSSStyleRule) || !r.selectorText.includes(':root'))
              .filter((r) => /#[0-9a-fA-F]{3,8}/.test(r.cssText) && !r.cssText.startsWith('--'))
              .map((r) => r.cssText.slice(0, 80));
          }));
        expect(hexOutsideVars, '变量声明块之外出现硬编码 Hex').toEqual([]);
      });
    }
  }
});
```
