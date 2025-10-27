Vulkan Grass Rendering
==================================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* Author: Crystal Jin
  *  [LinkedIn](https://www.linkedin.com/in/xiaoyue-jin), [personal website](https://xiaoyuejin.com)

* Tested on: Windows 11, i7-14700K @ 3.40GHz, 64GB RAM, NVIDIA GeForce RTX 4080 SUPER


## Project Overview

Real-time grass rendering using quadratic Bezier blade guides and GPU tessellation. A compute pass simulates physical forces and performs blade culling; a graphics pipeline tessellates and shades visible blades. Rendering uses indirect draw fed from compute-written counts.

![pro5_display-ezgif com-video-to-gif-converter (2)](https://github.com/user-attachments/assets/920849aa-88ab-4b9d-8321-bc1a6970ee77)


|  |  |
|---|---|
| ![f29ac77998f78670f849e71e5c3c5457](https://github.com/user-attachments/assets/38565925-81d5-434e-a48d-76b6e282dd12) | ![b691e70a80f72cbffdd8cf0c0de9bb75](https://github.com/user-attachments/assets/80a5e5ef-0507-4283-a937-7ff0ebf45387) |



## Grass Rendering using Bézier Curves

<img width="562" height="443" alt="image" src="https://github.com/user-attachments/assets/68d0fd6a-0463-4107-9f64-8c4e5021b034" />

Each blade is a **quadratic Bézier ribbon**: a center spine (`v0 → v1 → v2`) with width extruded perpendicular to the spine.

- **One patch per blade**  
  - **VS** passes attributes  
  - **TCS** sets tessellation levels  
  - **TES** evaluates Bézier and extrudes width, then projects to clip space
- **Local frame per blade**  
  - `forward` from orientation around `up`  
  - `side = up × forward`  
  - width **tapers** toward the tip
- **Curve via de Casteljau**  
  - `P(u) = mix(mix(v0, v1, u), mix(v1, v2, u), u)`  
  - `position = P + (v − 0.5) * width(u) * side`
- **Dynamics from compute**: forces update `v2` each frame (gravity, recovery, wind), so tessellation renders the *bent* shape.
- **UVs** use `(v, u)` consistently for simple texturing.


## Force Simulation

### Binding Resources
- **Camera UBO** set **0** (view/proj) and **Time UBO** set **1** ( `deltaTime`, `totalTime`, culling toggles/params ) feed the compute pass.
- **SSBOs** set **2** provide: input blades, output *culled* blades, and indirect draw args.

**References:**  
`src/shaders/compute.comp:7`, `src/shaders/compute.comp:12`, `src/shaders/compute.comp:43`

### Gravity
Applies constant **downward acceleration** plus a **forward bias** so blades bend slightly in their facing direction.  
**References:** `src/shaders/compute.comp:89`, `src/shaders/compute.comp:93`

### Recovery
Spring-like term pulls the deformed tip back toward the upright target  
`iV2 = v0 + up * height`, scaled by per-blade **stiffness**.  
**References:** `src/shaders/compute.comp:96`, `src/shaders/compute.comp:98`

### Wind
Position- and time-varying wind direction; influence scales with **squared alignment** to blade facing for stronger response when aligned.  
**References:** `src/shaders/compute.comp:100`, `src/shaders/compute.comp:110`


## Culling Tests

### Orientation Culling

![pro5_o-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/afea92bb-f98a-4aff-a829-eaac69c5a3a1)


- **Goal:** Remove blades viewed **edge-on** that would render thinner than a pixel and cause aliasing.  
- **Method:** Project `camera → blade` direction onto the grass plane and compare to the blade’s **width direction**; cull if `abs(dot)` exceeds a threshold.  
- **Controls:**  
  - `Time.enableOrientationCull`  
  - `Time.orientationThreshold` (default ~ `0.9`)  
  - Toggle with **`O`**

### View-Frustum Culling

![pro5_f-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/0c48e2bf-1245-4528-940e-f1893ff79537)

- **Goal:** Skip blades entirely **outside** the camera frustum to avoid wasted work.  
- **Method:** Test **three points** per blade in clip space — base `v0`, midpoint `m = 0.25*v0 + 0.5*v1 + 0.25*v2`, and guide `v1`. Cull only if **all** are outside, with a **tolerance** for conservative keeping.  
- **Controls:**  
  - `Time.enableFrustumCull`  
  - `Time.frustumTolerance` (e.g., `0.05–0.2` to soften edges)  
  - Toggle with **`F`**

### Distance Culling

![pro5_d-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/7d455a59-4379-4123-ab8c-4406574fe868)


- **Goal:** Thin **distant** blades that contribute little visually and may cause shimmering.  
- **Method:** Partition `[0, maxDistance]` into `bucketCount` bins; **keep probability decreases with distance** using a deterministic per-blade hash (stable over time).  
- **Controls:**  
  - `Time.enableDistanceCull`  
  - `Time.maxDistance`  
  - `Time.bucketCount` (more buckets → smoother falloff)  
  - Toggle with **`D`**


## Performance Analysis

### Setup & Methodology
To isolate algorithmic effects from camera variance, all trials used a **consistent view direction**:
- Same angle for **naive** and **orientation** tests.
- **Zoom-in** for **view-frustum** culling to maximize outside-FOV rejection.
- **Zoom-out** for **distance** culling, targeting **~⅔ blades rendered**.

This keeps each culling mode’s advantage **stable across grass densities**.

### Scaling With Blade Count

<img width="1379" height="980" alt="fps_vs_grass_naive" src="https://github.com/user-attachments/assets/999ba14b-9ee2-407b-96cd-293f1077a2be" />


- Naive rendering scales roughly **inversely with blade count**; **tessellation and rasterization** dominate as counts grow.
- **Compute** simulation cost is linear in blades but comparatively **small**; the bottleneck shifts to tessellation/fragment with higher counts.
- Expect near-linear **FPS drop per 4×** blade increase until other limits (fill-rate, geometry throughput) kick in.

### Culling Impact by Test

<img width="1579" height="1080" alt="fps_vs_grass_all_methods_clean" src="https://github.com/user-attachments/assets/2fd85648-fbb1-4248-a4c0-fe0427363d95" />


#### Orientation Culling
- Removes blades viewed **edge-on**; benefit depends on view direction relative to blade facing.  
- Consistent **1.3–1.8×** speedups; strongest at grazing angles where many blades are edge-on.

#### View-Frustum Culling
- Discards **out-of-view** blades; benefit grows with scene size and **tighter FOV**.  
- Often **1.8–2.3×** at higher counts when the frustum clips large areas.

#### Distance Culling
- Thins **distant** blades uniformly; reduces tessellation/fragment work while preserving nearby detail.  
- **1.8–2.5×** improvements at mid/high counts; controlled by `maxDistance` and `bucketCount`.
