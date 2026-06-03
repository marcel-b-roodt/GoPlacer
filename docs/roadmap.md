# GoPlacer — Development Roadmap

Target: **A complete asset placement toolkit for Godot 4, covering palette management, floor/surface snapping, brush painting, and scene-tree organisation.**

Stages are ordered by dependency and user value. Each stage should be releasable as a versioned milestone.

---

## Stage 0 — Foundation (`v0.1.x`) ✅

The scaffolding that all later work depends on. Plugin registers, bottom dock panel appears, palette and placement systems are wired.

| Item | Description | Status |
|---|---|---|
| EditorPlugin setup | `plugin.gd` registers bottom dock panel and placement controller | ✅ |
| Drawer-based panel | `GoPlacerDrawer` base class; Palette and Settings drawers in bottom dock | ✅ |
| Palette resource | `GoPlacerPalette` and `GoPlacerPaletteEntry` extend `Resource`; stored as `.tres` | ✅ |
| Palette CRUD | Create/delete palettes; add/remove entries via drag-and-drop; auto-discover from filesystem | ✅ |
| Palette persistence | Palettes saved as `.tres` in `res://palettes/`; auto-refresh on filesystem changes | ✅ |
| Single-click placement | Select entry → ghost preview → click to lock → drag to rotate → release to commit | ✅ |
| Floor snapping | `SnapHelper.raycast_scene()` — physics ray, mesh triangle, and Y=0 plane fallback | ✅ |
| Surface snapping | Ray-cast against any surface (walls, ceilings, angled terrain) | ✅ |
| Normal alignment | `SnapHelper._basis_up_aligned()` — orient Y-up to match surface normal | ✅ |
| AABB flush offset | `SnapHelper.flush_aabb_offset()` — snap object bottom to surface (support function) | ✅ |
| Azimuth / rotation | Configurable Y-rotation snap: Free, 15°, 30°, 45°, 90° | ✅ |
| Ctrl position snapping | Hold Ctrl to grid-snap placement position with configurable step | ✅ |
| Target parent | Auto-detect `GoPlacerParent` node; configurable parent in Settings drawer | ✅ |
| Undo / Redo | Every placement uses `EditorUndoRedoManager` via `PlacementController.commit_to_scene()` | ✅ |
| Ghost preview | Semi-transparent ghost follows cursor; excluded from raycasts | ✅ |
| Azimuth gizmo | Yellow arc + forward line during drag-rotate | ✅ |
| Clean architecture | `GhostManager`, `PlacementGizmo`, `InstanceFactory`, `PlacementController` extracted from plugin.gd | ✅ |
| CI pipeline | GitHub Actions: lint + test on every push/PR | ✅ |
| Copilot instructions | `docs/internal/copilot-instructions.md` + `AGENTS.md` symlink | ✅ |

---

## Stage 1 — Grid & Surface Snapping (`v0.2.x`)

Precision placement so objects land on-grid and on-surface.

| Item | Description |
|---|---|
| Grid snapping | Snap placement position to a configurable grid (matching or overriding editor grid step) |
| Rotation shortcut keys | `[` / `]` to rotate before placing; scroll wheel for continuous rotation |
| Scale shortcut keys | `+` / `-` to scale before placing |
| Placement origin offset | Configurable offset from the hit point (e.g., place by object bottom rather than centre) |

---

## Stage 2 — Brush Painting (`v0.3.x`)

Paint instances across surfaces with configurable density and randomness.

| Item | Description |
|---|---|
| Brush mode | Click-and-drag to scatter instances across the surface under the cursor |
| Density control | Instances per square metre; configurable in the dock |
| Scale jitter | Random scale variation per instance (min/max range) |
| Random Y rotation | Random rotation around Y within a configurable range |
| Erase brush | Shift+drag to remove placed instances under the cursor |
| Brush settings panel | Density, scale jitter, rotation range, falloff radius |

---

## Stage 3 — Multi-Palette & Organisation (`v0.4.x`)

Manage many palettes and keep placed objects organised.

| Item | Description |
|---|---|
| Multi-palette UI | Tab or list to switch between palettes quickly |
| Tag / category filtering | Filter palette entries by tag or category |
| Search | Text search across palette assets |
| Group naming | Optionally prefix placed instance names with palette or category |
| Statistics | Show count of placed instances per palette in the dock |

---

## Stage 4 — Advanced Placement (`v0.5.x`)

Power-user features for complex level layouts.

| Item | Description |
|---|---|
| Scatter along path | Distribute instances along a Path3D with configurable spacing and randomisation |
| Foliage-style painting | Continuous painting on terrain meshes with LOD-aware scattering |
| Collision masking | Filter ray-cast layers so placement only snaps to specific surfaces |
| Random asset selection | Pick randomly from multiple assets in a palette entry for natural variation |
| Undo groups | Group multiple brush strokes into a single undo step |

---

## Stage 5 — Polish & UX (`v0.6.x`)

Making everything feel finished.

| Item | Description |
|---|---|
| Keyboard shortcuts | Full configurable shortcut system for placement mode toggles |
| Contextual tooltips | Hover hints showing current snap settings and shortcuts |
| Preferences panel | Plugin preferences: snap defaults, brush defaults, parent node path |
| Theme support | Respects Godot editor dark/light theme |
| Cursor indicators | Viewport overlay showing placement preview (ghost instance at cursor) |
| Asset thumbnails | Generate and cache thumbnails for palette entries from scenes/meshes |

---

## Stage 6 — v1.0 Release

- All Stage 0–5 items complete and tested.
- Asset Library submission approved.
- Online documentation live.
- Demo project published.

---

## Future / Post-v1.0 (`v1.x+`)

| Idea | Notes |
|---|---|
| Procedural rules | Weight rules for which assets appear where (slope, height, biome) |
| Export placed data | Export placement data as JSON for runtime use |
| Noise-driven painting | Use FastNoiseLite to drive density and selection variations |