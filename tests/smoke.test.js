import test from 'node:test';
import assert from 'node:assert/strict';
import { advanceProbe } from '../src/core/smoke.js';
test('probe rejects invalid elapsed time without mutating input', () => {
  const input = { angle: 0 };
  for (const value of [-1, NaN, Infinity]) assert.throws(() => advanceProbe(input, value), RangeError);
  assert.deepEqual(input, { angle: 0 });
});
