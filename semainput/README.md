# semainput v41

This version adds a calibrated `scale_factor` field to pinch gestures.

## Improvements

- `scale_factor` field added to `pinch_begin` and `pinch` events: ratio of
  current to previous finger separation, suitable for direct use in
  pinch-to-zoom (`zoom *= event.scale_factor`)
- `delta` field recalibrated to pixel-distance difference (`sqrt(cur) -
  sqrt(prev)`) rather than the previous scaled squared-distance approximation
- `scale_hint` and `delta` retained for backward compatibility
