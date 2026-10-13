// Local-only rendering compatibility probe. No browser, shell, or shared macros.
const fs = require('node:fs');
const crypto = require('node:crypto');
const katex = require(process.argv[2]);
const input = fs.readFileSync(process.argv[3]);
const report = JSON.parse(input);
const rows = report.rows.map(r => {
  const check = text => {
    try {
      katex.renderToString(text ?? '', {throwOnError:true, trust:false, strict:'error', maxExpand:1000, maxSize:10, macros:{}});
      return typeof text === 'string' && text.length > 0;
    } catch { return false; }
  };
  return {sha256:r.sha256, prediction_rendered:check(r.prediction), reference_rendered:check(r.ground_truth)};
});
fs.writeFileSync(process.argv[4], JSON.stringify({renderer:'KaTeX 0.16.22',
  report_sha256:crypto.createHash('sha256').update(input).digest('hex'), denominator:rows.length,
  prediction_failures:rows.filter(r=>!r.prediction_rendered).length,
  reference_failures:rows.filter(r=>!r.reference_rendered).length,
  note:'Post-hoc renderer compatibility only; does not change predeclared exact match normalization or establish mathematical correctness.', rows}, null, 2));
