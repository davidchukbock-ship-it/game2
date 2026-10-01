// Точка входа для Node.js-хостинга (Hostinger: «Entry file»): миграции MySQL и запуск сервера игры.
// Сайт собирается командой сборки (pnpm run build) и отдаётся самим сервером. См. docs/HOSTINGER.md.
process.argv[2] = 'start';
import('./scripts/hostinger.mjs').catch((err) => {
  console.error(err);
  process.exit(1);
});
