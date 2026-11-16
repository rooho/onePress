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
