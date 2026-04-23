const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(function(file) {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.controller.ts')) {
        results.push(file);
      }
    }
  });
  return results;
}

const files = walk(path.join(__dirname, '../nest-backend/src'));
const endpoints = [];

files.forEach(f => {
  const content = fs.readFileSync(f, 'utf8');
  let controllerPath = '';
  const cMatch = content.match(/@Controller\((['"`])(.*?)\1\)/);
  if (cMatch) {
    controllerPath = cMatch[2];
  }

  const routes = content.matchAll(/@(Get|Post|Put|Delete|Patch)\((['"`])?(.*?)\2?\)/g);
  for (const r of routes) {
    const method = r[1].toUpperCase();
    const routePath = r[3] || '';
    let fullPath = `/${controllerPath}/${routePath}`.replace(/\/+/g, '/').replace(/\/$/, '');
    if (fullPath === '') fullPath = '/';
    endpoints.push(`[${method}] ${fullPath}`);
  }
});

console.log(endpoints.join('\n'));
