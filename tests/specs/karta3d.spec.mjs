// [TILLAGT v5.1464.0] 3D-kartan far aldrig krascha nar den byggs. En ny region gjorde det en gang, och spelets
// vanliga test visar 2D-kartan, sa felet syntes inte forran inloggat.
import { test, expect } from '@playwright/test';

test('3D-kartan byggs utan JS-fel', async ({ page }) => {
  const fel = [];
  page.on('pageerror', e => fel.push(e.message));
  await page.goto('/genesis-3d.html');
  await page.waitForTimeout(3000);
  expect(fel).toEqual([]);
});
