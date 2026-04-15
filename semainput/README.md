# semainput

This version fixes three-finger arbitration anchor timing and lowers activation conservatism.

## Improvements

- arbitration anchor is captured at three-finger arbitration start
- lazy anchor initialization removed from update path
- lower cumulative three-finger activation threshold
- retained cumulative activation, post-lock clamp, smoothing, confidence, and axis lock
