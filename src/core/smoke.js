// Environment probe only. Game rules and Test Contract are not implemented here.
export function advanceProbe(state, seconds) {
  if (!Number.isFinite(seconds) || seconds < 0) throw new RangeError('seconds must be finite and non-negative');
  return { angle: state.angle + seconds };
}
