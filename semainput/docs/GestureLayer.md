# Gesture Layer

## v40 three-finger activation fix

### Problem

v39 could still miss promotion when the cumulative anchor was initialized too late in the update path.

### Change

The arbitration anchor is now captured immediately when three-finger arbitration begins.
Activation still uses cumulative centroid displacement, but now from the correct start point.

### Result

This improves:
- reliable three-finger activation on smooth hardware
- clean separation between activation and post-lock smoothing
