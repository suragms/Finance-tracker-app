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
      if (file.endsWith('.dart')) {
        results.push(file);
      }
    }
  });
  return results;
}

const files = walk(path.join(__dirname, '../flutter-app/lib'));
let providers = [];

files.forEach(f => {
  const content = fs.readFileSync(f, 'utf8');
  
  // match things like: final sessionProvider = Provider...
  const match1 = content.matchAll(/final\s+(\w+Provider|\w+Notifier)\s*=/g);
  for (const m of match1) providers.push(m[1]);
  
  // match Riverpod 2.0 classes
  const match2 = content.matchAll(/class\s+(\w+)\s+extends\s+(?:\_\$?\w+|(?:AutoDispose)?(?:Async)?Notifier|(?:Async)?Notifier|StateNotifier|ChangeNotifier|<.+>)/g);
  for (const m of match2) {
      if(m[1].includes('Provider') || m[1].includes('Notifier') || content.includes('@riverpod')) {
          providers.push(m[1]);
      }
  }
});

console.log([...new Set(providers)].join('\n'));
