# GoPlacer — Architecture

> **Who this is for:** contributors and anyone curious about how the plugin is structured internally.
> For *using* GoPlacer, see [GUIDE.md](../GUIDE.md).

---

## Layer map

| Layer | Path | Description |
|---|---|---|
| Plugin entry point | `addons/go_placer/plugin.gd` | `EditorPlugin` root. Registers bottom dock, orchestrates placement FSM. |
| Core / UI | `addons/go_placer/core/` | `GoPlacerPanel` (dock container), `GoPlacerDrawer` (collapsible section base), `GoPlacerPaletteDrawer`, `GoPlacerSettingsDrawer`. |
| Palette | `addons/go_placer/palette/` | `GoPlacerPalette` and `GoPlacerPaletteEntry` resources. Persisted as `.tres` files. |
| Placement | `addons/go_placer/placement/` | `PlacementController` (state + undo/redo), `SnapHelper` (raycast, snap, AABB, basis), `GhostManager` (preview lifecycle), `PlacementGizmo` (arc + line rendering), `InstanceFactory` (asset instantiation). |
| Tests | `tests/` | GdUnit4 suites mirroring the addon structure. |

---

## Single-path placement flow

The placement pipeline has **one** path:

1. User selects a palette entry → `plugin.gd::start_placing()` → `GhostManager.spawn()`
2. Mouse motion → `plugin.gd::_update_ghost_position()` → `SnapHelper.raycast_scene()` → `SnapHelper.apply_placement_transform()` on ghost
3. Click to lock → `plugin.gd::_on_click_lock()` → enter `DRAG_ROTATE`
4. Drag to set azimuth → `plugin.gd::_update_drag_rotation()` + `PlacementGizmo.update()`
5. Release to commit → `plugin.gd::_commit_place()` → `InstanceFactory.create_from_entry()` → copy ghost transform → `PlacementController.commit_to_scene()`
6. Ghost hidden, stays in `PREVIEWING` for rapid re-placement.

**No alternate placement paths.**

---

## Key scripts

### `plugin.gd` — EditorPlugin orchestrator

Owns:
- Bottom dock panel creation and lifecycle
- Placement FSM state (`IDLE`, `PREVIEWING`, `DRAG_ROTATE`)
- 3D viewport input forwarding and dispatch
- Delegates ghost management to `GhostManager`
- Delegates gizmo rendering to `PlacementGizmo`
- Delegates instance creation to `InstanceFactory`
- Delegates undo/redo commit to `PlacementController`

### `placement/ghost_manager.gd` — Ghost preview lifecycle

Owns:
- Ghost node creation, material overlay, collision disabling
- RID collection for raycast exclusion
- Ghost visibility toggling
- `get_ghost()`, `get_exclusion_rids()`, `spawn()`, `clear()`

### `placement/placement_gizmo.gd` — Azimuth gizmo

Owns:
- Arc mesh and forward-direction line rendering
- Gizmo positioning aligned to surface normal
- `show()`, `update()`, `position_gizmo()`, `hide()`

### `placement/instance_factory.gd` — Asset instantiation

Static utility:
- `create_from_entry(entry)` — creates a `Node` from a `GoPlacerPaletteEntry` (PackedScene or Mesh)

### `placement/placement_controller.gd` — Settings state and undo/redo

Owns:
- Placement settings (floor snap, surface snap, normal align, AABB snap, rotation snap, position snap, target parent)
- Public getters for all settings (no more private field access from plugin.gd)
- `commit_to_scene()` — wraps undo/redo action for placing instances

### `placement/snap_helper.gd` — Raycast, snap, and transform utilities

Static utilities:
- `raycast_scene()` — full 3-layer raycast cascade (physics → mesh triangle → floor)
- `_raycast_mesh_faces()` + `_find_mesh_hit_ref()` — recursive scene-graph mesh triangle intersection
- `ray_triangle_intersect()` — Moller-Trumbore core math
- `floor_plane_intersect()` — Y=0 plane intersection
- `apply_placement_transform()` — position + normal alignment + AABB flush offset + azimuth rotation
- `flush_aabb_offset()` — compute flush-to-surface offset using AABB support function
- `_get_visual_aabb()` — recursive AABB computation from scene hierarchy
- `_basis_up_aligned()` — create basis with Y-up aligned to surface normal
- `find_target_parent()` — search for `GoPlacerParent` node or fall back to scene root
- `snap_angle()` — snap rotation angle to configurable step

### `core/go_placer_panel.gd` — Bottom dock container

Owns:
- Two drawers: Palettes and Settings
- Wires drawer → controller communication
- Provides `get_active_entry()` for external queries
- Visibility change stops placing

### `core/go_placer_drawer.gd` — Collapsible section base class

Provides:
- Collapsible header (toggle button) + `_content` VBoxContainer
- `_op_button()` helper for disabled-by-default action buttons
- `set_plugin()`, `set_open()`, `is_open()`, `refresh()` virtuals

### `core/go_placer_palette_drawer.gd` — Palette drawer

Owns:
- Palette dropdown (auto-discovered from `res://palettes/`)
- CRUD: create, delete, add/remove entries
- Entry grid with `EditorResourcePreview` thumbnails
- Palette `.tres` persistence on mutation

### `core/go_placer_settings_drawer.gd` — Settings drawer

Owns:
- Floor snap, surface snap, normal align, AABB snap checkboxes
- Rotation snap dropdown (Free / 15/30/45/90 degrees)
- Position snap spinbox (Ctrl-held grid)
- Target parent label with clear button
- All settings forwarded to `PlacementController` via setter methods

---

## Language policy

**All plugin code is GDScript.** No C#, no GDExtension. This ensures the plugin works in every Godot 4 project regardless of whether the user has .NET installed.

---

## Coordinate system

| Axis | Direction | Godot constant |
|---|---|---|
| X | Right | `Vector3.RIGHT = (1, 0, 0)` |
| Y | Up | `Vector3.UP = (0, 1, 0)` |
| +Z | Toward viewer | `Vector3.BACK = (0, 0, 1)` |
| -Z | Camera-forward | `Vector3.FORWARD = (0, 0, -1)` |

Normals from raycasts are **outward-facing** (away from surface). All alignment logic aligns local Y-up to the outward normal.

---

## Undo/Redo pattern

```gdscript
_placement_controller.set_active_entry(entry)
_placement_controller.commit_to_scene(instance, parent, scene_root)
```

---

## Drawer pattern

All collapsible UI sections extend `GoPlacerDrawer`:

```gdscript
class_name MyDrawer
extends GoPlacerDrawer

func _ready() -> void:
    _setup_drawer("My Section", true)  # title, starts open
    # Add children to _content
    var btn := Button.new()
    btn.text = "Action"
    _content.add_child(btn)
```

---

## Testing

Framework: **GdUnit4** (install from AssetLib).

Tests mirror the source path under `tests/`:
- `tests/core/go_placer_drawer_test.gd`
- `tests/palette/go_placer_palette_test.gd`
- `tests/placement/snap_helper_test.gd`
- `tests/placement/ghost_manager_test.gd`
- `tests/placement/instance_factory_test.gd`

Run locally: open the GdUnit4 panel in Godot -> **Run all tests**.
Run in CI: `MikeSchulze/gdUnit4-action` on every push/PR via `.github/workflows/ci.yml`.