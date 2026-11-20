import assert from 'node:assert/strict';
import { advanceProbe } from '../src/core/smoke.js';
const run = () => [0.25, 0.25, 0.5].reduce(advanceProbe, { angle: 0 });
const result = run();
assert.deepEqual(result, { angle: 1 });
assert.deepEqual(run(), result);
console.log(JSON.stringify({ probe: 'environment-only', result, deterministic: true }));
