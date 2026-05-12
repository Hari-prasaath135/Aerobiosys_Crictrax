# 🎬 Animation Visual Reference & Timing Charts

## Animation Timeline Diagrams

### 🟢 Boundary 4 Animation (1200ms total)

```
Timeline:
0ms ━━━┓
       ┃ Scale: 0.0 → 1.5 (Elastic bounce)
600ms ━┛━━━━━━━━━━━┓
                    ┃ Scale: 1.5 → 0.0 (Decay)
1200ms ━━━━━━━━━━━━┛

Opacity:
0ms ━━━━━━━━━━━┓
               ┃ 1.0 → 0.0
1200ms ━━━━━━━━┛

Position (Y):
0ms ━━┓
      ┃ Drift: 0px → -100px
600ms ┃
      ┃━━━━━━━━━━━┓
1200ms ━━━━━━━━━━━━┛

Result: ⭕ ↗️ ⬇️ ✨
Expands outward while floating upward, then fades
```

**Key Frames:**
- **0ms:** Start - Size 0, Opacity 1, Position 0
- **600ms:** Peak - Size 1.5x, Opacity 1, Position -100px
- **1200ms:** End - Size 0, Opacity 0, Position -100px

---

### 🔵 Boundary 6 Animation (1200ms total)

```
Timeline:
0ms ━━━┓
       ┃ Scale: 0.0 → 2.0 (Elastic bounce)
600ms ━┛━━━━━━━━━━━┓
                    ┃ Scale: 2.0 → 0.0 (Decay)
1200ms ━━━━━━━━━━━━┛

Rotation:
0ms ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┃ 360° per 800ms (continuous)
1200ms ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┃ Completes 1.5 full rotations

Opacity:
0ms ━━━━━━━━━━━━━┓
                 ┃ 1.0 → 0.0
1200ms ━━━━━━━━━━┛

Result: 🔵 🔄 ↗️ ✨
Scales up while spinning, then fades with continued rotation
```

**Key Frames:**
- **0ms:** Start - Size 0, Rotation 0°, Opacity 1
- **300ms:** Quarter - Size 0.5x, Rotation 90°, Opacity 1
- **600ms:** Half - Size 1.0x, Rotation 180°, Opacity 1
- **900ms:** Three-quarter - Size 0.5x, Rotation 270°, Opacity 0.5
- **1200ms:** End - Size 0, Rotation 360°, Opacity 0

---

### 🔴 Wicket Animation (1400ms total)

```
Shake Effect:
0ms ━┓
     ┃ Shake: 0 → 20px → -20px → 0px
200ms┃ (400ms shake duration)
400ms┛
     ━━━━━━━━━━━━━━━━ (No more shake)

Scale:
0ms ━━━┓
       ┃ Scale: 0.0 → 1.8 (Elastic bounce)
700ms ━┛━━━━━━━━━━━┓
                    ┃ Scale: 1.8 → 0.0 (Decay)
1400ms ━━━━━━━━━━━━┛

Particle Spread:
0ms ━━━━━━┓
          ┃ Particles: Pos 0 → Distance × Opacity fade
700ms ━━━━┃
1400ms ━━━┛

Opacity:
0ms ━━━━━━━━━━━━━━━┓
                    ┃ 1.0 → 0.0
1400ms ━━━━━━━━━━━━┛

Result: 🔴 ⚡ 💥 ✨
Shakes violently, then explodes with particles radiating outward
```

**Key Frames:**
- **0ms:** Start - Shake begins, Scale 0, Particles at center
- **200ms:** Shake ends - Scale at peak (1.8x)
- **400ms:** Scale decay begins - Particles start spreading
- **700ms:** Half dispersal - Scale medium, Opacity 0.5
- **1400ms:** End - Scale 0, Opacity 0, Particles scattered

---

### 🦆 Duck Animation (1200ms total)

```
Timeline:
0ms ━━━┓
       ┃ Scale: 0.0 → 1.5 (Elastic bounce)
600ms ━┛━━━━━━━━━━━┓
                    ┃ Scale: 1.5 → 0.0 (Decay)
1200ms ━━━━━━━━━━━━┛

Rotation (Subtle):
0ms ━━━━━━┓
          ┃ Rotate: 0° → 5° → 0°
600ms ━━━━┃
1200ms ━━━┛

Opacity:
0ms ━━━━━━━━━━━━━┓
                 ┃ 1.0 → 0.0
1200ms ━━━━━━━━━━┛

Result: 🦆 ↔️ ✨
Bounces in with slight rotation, then fades out smoothly
```

**Key Frames:**
- **0ms:** Start - Size 0, Rotation 0°, Opacity 1
- **300ms:** Midpoint - Size 0.75x, Rotation 2.5°, Opacity 1
- **600ms:** Peak - Size 1.5x, Rotation 0°, Opacity 1
- **900ms:** Decay - Size 0.75x, Rotation -2.5°, Opacity 0.5
- **1200ms:** End - Size 0, Rotation 0°, Opacity 0

---

## Animation Speed Comparison

```
Animation Speed (Visual Duration):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 Boundary 4:    ████████████ 1200ms (MEDIUM)
🔵 Boundary 6:    ████████████ 1200ms (MEDIUM)
🔴 Wicket:        ███████████████ 1400ms (LONGEST)
🦆 Duck:          ████████████ 1200ms (MEDIUM)

Perceived Speed (Curve):
🟢 Boundary 4:    Elastic Out (Fast → Slow)
🔵 Boundary 6:    Elastic Out (Fast → Slow) + Continuous Rotation
🔴 Wicket:        Combo (Shake Fast, Scale Elastic)
🦆 Duck:          Elastic Out (Fast → Slow)
```

---

## Size Progression Charts

### Boundary 4 Scale Progression
```
    1.5x │     ●●●
         │   ●       ●
         │  ●           ●
    1.0x │ ●               ●
         │●                   ●
    0.5x │                       ●
         │                           ●
    0.0x └─────────────────────────────
         0ms  300ms  600ms  900ms 1200ms

Curve: Elastic Out then fade
```

### Boundary 6 Scale Progression
```
    2.0x │      ●●●
         │    ●       ●
         │   ●           ●
    1.0x │  ●               ●
         │ ●                   ●
    0.5x │●                       ●
         │                           ●
    0.0x └─────────────────────────────
         0ms  300ms  600ms  900ms 1200ms

Curve: Elastic Out (larger peak than 4x)
Plus: 360° rotation every 800ms
```

### Wicket Scale Progression
```
    1.8x │      ●●●
         │    ●       ●
         │   ●           ●
    1.0x │  ●               ●
         │ ●                   ●
    0.5x │                       ●
         │                           ●
    0.0x └────────────────────────────────
         0ms 300ms 600ms 900ms 1200ms 1400ms

Curve: Elastic Out (highest peak)
Plus: Shake 0-400ms
Plus: Particles expand 0-1400ms
```

### Duck Scale Progression
```
    1.5x │     ●●●
         │   ●       ●
         │  ●           ●
    1.0x │ ●               ●
         │●                   ●
    0.5x │                       ●
         │                           ●
    0.0x └─────────────────────────────
         0ms  300ms  600ms  900ms 1200ms

Curve: Elastic Out
Plus: ±5° rotation
```

---

## Color Gradient Visualizations

### Boundary 4 - Green Theme
```
┌─────────────────────────────────┐
│  🟢 BOUNDARY 4 COLOR PALETTE     │
├─────────────────────────────────┤
│                                  │
│  Outer Ring:   ████ #4CAF50     │
│  Middle Ring:  ████ #8BC34A     │
│  Center:       ████ Gradient    │
│  Shadow:       ████ Green @0.6α │
│                                  │
│  Overall Feel: Fresh, Success    │
└─────────────────────────────────┘
```

### Boundary 6 - Blue Theme
```
┌─────────────────────────────────┐
│  🔵 BOUNDARY 6 COLOR PALETTE     │
├─────────────────────────────────┤
│                                  │
│  Background:   ████ #2196F3     │
│  Sweep Grad:   ████ #00BCD4     │
│  Inner:        ████ #0288D1     │
│  Shadow:       ████ Cyan @0.8α  │
│                                  │
│  Overall Feel: Powerful, Dynamic │
└─────────────────────────────────┘
```

### Wicket - Red/Orange Theme
```
┌─────────────────────────────────┐
│  🔴 WICKET COLOR PALETTE         │
├─────────────────────────────────┤
│                                  │
│  Sticks:       ████ #FF6B6B     │
│  Bails:        ████ #FFB74D     │
│  Particles:    ████ Red/Orange  │
│  Shadow:       ████ Red @0.6α   │
│                                  │
│  Overall Feel: Dramatic, Impact  │
└─────────────────────────────────┘
```

### Duck - Orange Theme
```
┌─────────────────────────────────┐
│  🦆 DUCK COLOR PALETTE           │
├─────────────────────────────────┤
│                                  │
│  Primary:      ████ #FF9800     │
│  Secondary:    ████ #FF6F00     │
│  Background:   ████ Gradient    │
│  Shadow:       ████ Orange @0.6α│
│                                  │
│  Overall Feel: Playful, Warm     │
└─────────────────────────────────┘
```

---

## Animation Composition Layers

### Boundary 4 Layers (Front to Back)
```
Layer 5: Fade effect (Opacity 1.0 → 0.0)
         │
Layer 4: Text "4 BOUNDARY" (Scaled with container)
         │
Layer 3: Inner circle (Solid green gradient)
         │
Layer 2: Middle ring (Light green border)
         │
Layer 1: Outer ring (Green border)
         │
Layer 0: Transparent background
```

### Boundary 6 Layers (Front to Back)
```
Layer 5: Fade effect (Opacity 1.0 → 0.0)
         │
Layer 4: Text "6 SIX!" (Scaled with container)
         │
Layer 3: Inner circle (Blue gradient)
         │
Layer 2: Sweep gradient background (Rotating)
         │
Layer 1: Shadow effect (Cyan glow)
         │
Layer 0: Transparent background
```

### Wicket Layers (Front to Back)
```
Layer 5: Fade effect (Opacity 1.0 → 0.0)
         │
Layer 4: Particles 8x (Red/Orange dots)
         │
Layer 3: CustomPaint (Bails - Orange)
         │
Layer 2: CustomPaint (Sticks - Red)
         │
Layer 1: Shake container (±20px offset)
         │
Layer 0: Transparent background
```

### Duck Layers (Front to Back)
```
Layer 5: Fade effect (Opacity 1.0 → 0.0)
         │
Layer 4: Text "DUCK" label
         │
Layer 3: Duck emoji 🦆 (Large)
         │
Layer 2: Inner circle (Orange gradient)
         │
Layer 1: Glow shadow (Orange)
         │
Layer 0: Transparent background
```

---

## Particle System Details (Wicket Only)

```
Particle Properties:
├─ Count: 8 particles
├─ Colors: Alternating Red (#FF6B6B) & Orange (#FF9800)
├─ Size: 8x8 pixels each
├─ Shape: Circle
└─ Duration: 1400ms

Particle Spread Pattern:
                ↖ P0 (Red)
            ↑ P1 (Orange)
        ↗ P2 (Red)
    →  P3 (Orange)
Center ★
    ← P4 (Red)
        ↙ P5 (Orange)
            ↓ P6 (Red)
                ↘ P7 (Orange)

Distance Calculation:
Distance = 80px × (1 - t) + 150px × t
Where: t = elapsed_time / total_duration
Result: Particles start 80px away, reach 150px by end
```

---

## Performance Visualization

```
Frame Rate Performance:
60 ┃                                    🎬
   ┃ ████████████████████████████████████
   ┃ ████████████████████████████████████
   ┃ ████████████████████████████████████
50 ┃ ████████████████████████████████████
   ┃ ████████████████████████████████████
   ┃ ████████████████████████████████████
   └─────────────────────────────────────
   0ms              600ms            1200ms

Memory Usage:
     🟢 Boundary 4:    ████ 1.8MB
     🔵 Boundary 6:    ████ 1.8MB
     🔴 Wicket:        █████ 2.1MB
     🦆 Duck:          ████ 1.8MB
     ─────────────────────────
     Total Peak:       █████ 2.1MB
```

---

## Easing Curve Reference

```
Elastic Out Curve (Used in 4 & 6 & Duck):

     ●●●
   ●       ●
  ●           ●  ← Springy bounce effect
 ●               ●
●                   ●
                     ●
                       ●

Linear Curve (Used in 6 rotation):

●
  ●
    ●
      ●
        ●
          ●
            ●

Ease In Quad (Used in opacity fade):

                        ●
                    ●
                  ●
                ●
              ●
            ●
          ●
        ●
      ●
    ●
  ●
●
```

---

## Animation Combination Chart

```
Which animations play together:
(X = Can play simultaneously)

           │ 4  │ 6  │ W  │ Duck│
      ─────┼────┼────┼────┼─────┤
      4    │ -  │ X  │ X  │  X  │
      6    │ X  │ -  │ X  │  X  │
      W    │ X  │ X  │ -  │  ~  │
      Duck │ X  │ X  │ ~  │  -  │

Notes:
✓ (X) = Can overlap without issues
~ (~) = Can overlap but less common
- (-) = Same event, won't overlap
```

---

## Summary Reference Table

| Animation | Duration | Scale | Colors | Effects | FPS |
|-----------|----------|-------|--------|---------|-----|
| **4** | 1200ms | 0→1.5→0 | Green | Rings, Float | 60 |
| **6** | 1200ms | 0→2.0→0 | Blue | Rotate, Scale | 60 |
| **W** | 1400ms | 0→1.8→0 | Red | Shake, Burst | 60 |
| **🦆** | 1200ms | 0→1.5→0 | Orange | Scale, Glow | 60 |

---

## Quick Visual Reference

```
ANIMATION AT A GLANCE:

🟢 ⭕ ↗️  ← Boundary 4: Expanding rings float upward
🔵 🔄   ← Boundary 6: Rotating circle spirals
🔴 ⚡💥  ← Wicket: Shaking stump with particle burst
🦆 ↔️   ← Duck: Bouncy duck with glow

All animations: 60 FPS, Smooth, Professional
```

---

This visual reference guide helps you understand the exact timing, colors, and effects of each animation at a glance! 🎬✨
