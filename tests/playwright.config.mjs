// Installningar for Genesis-testerna. Kor med: npm test (i mappen tests/).
import { defineConfig } from '@playwright/test';

const PORT = +(process.env.PORT || 4173);

// De sex skarmbredderna som tidigare kontrollerades for hand.
export const SKARMAR = [
  { name: '1920x1080', width: 1920, height: 1080 },
  { name: '1440x900', width: 1440, height: 900 },
  { name: '1280x800', width: 1280, height: 800 },
  { name: '1000x800', width: 1000, height: 800 },   // mellan 820 och 1280 ar karaktarsrutan som smalast
  { name: '820x1180', width: 820, height: 1180, touch: true },
  { name: '390x844', width: 390, height: 844, touch: true },
  { name: '360x740', width: 360, height: 740, touch: true },
];

export default defineConfig({
  testDir: './specs',
  timeout: 90_000,
  expect: { timeout: 10_000 },
  fullyParallel: true,
  workers: process.env.CI ? 2 : 3,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report' }]],
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'node server.mjs',
    url: `http://127.0.0.1:${PORT}/index.html`,
    reuseExistingServer: true,
    env: { PORT: String(PORT) },
  },
  projects: [
    { name: 'data', testMatch: /data\.spec\.mjs/ },
    ...SKARMAR.map(s => ({
      name: s.name,
      testMatch: /(ui|windfall|karta3d)\.spec\.mjs/,
      use: { viewport: { width: s.width, height: s.height }, hasTouch: !!s.touch, isMobile: false },
    })),
  ],
});
