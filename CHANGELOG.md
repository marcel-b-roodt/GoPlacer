# Changelog

All notable changes to GoPlacer are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org).

---

## [Unreleased]

---

## [0.1.0] — 2026-06-03

### Added
- Bottom dock panel with Palettes and Settings drawers
- Palette auto-discovery from `res://palettes/`, auto-refresh on filesystem changes
- Palette CRUD: create, delete, add/remove entries via drag-and-drop from FileSystem dock
- `EditorResourcePreview`-based thumbnail generation for palette entries
- Entry selection → placement FSM: IDLE → PREVIEWING → DRAG_ROTATE → back to PREVIEWING
- Ghost preview: semi-transparent blue material, collision disabled, raycast exclusion
- 3-layer raycast cascade: physics (with Area3D) → mesh-face Moller-Trumbore → floor plane (Y=0) fallback
- Face normal direction guarantee: mesh normals always face toward camera
- Surface snapping with normal alignment: Y-up aligns to outward surface normal
- Azimuth gizmo: yellow arc + forward direction line during drag-rotate
- Ctrl-held position snapping (configurable grid) and azimuth snapping (rotation snap dropdown)
- AABB flush offset: objects sit flush on surfaces using support-function projection (toggle in Settings)
- Target parent auto-detection (`GoPlacerParent` node) and manual override in Settings
- Undo/Redo integration for every placement via `EditorUndoRedoManager`
- `InstanceFactory` — shared utility for creating instances from palette entries
- `GhostManager` — extracted ghost lifecycle (spawn, clear, RID collection, collision disable, material overlay)
- `PlacementGizmo` — extracted gizmo rendering (arc mesh, line mesh, positioning)
- `PlacementController` — cleaned up, dead code removed, public getters for settings
- Social content template and queue system (`docs/internal/social/`)
- Copilot instructions (`docs/internal/copilot-instructions.md` + `AGENTS.md` symlink)
- CI pipeline: `gdparse` + `gdlint` on every push/PR via GitHub Actions
- Release scripts: `scripts/release.sh`, `scripts/release-dev.sh`, `scripts/release/prepare_release_notes.sh`

### Changed
- Normal alignment now correctly orients Y-up to surface normal (was pointing -Z along normal)
- AABB flush offset computes using inward-facing support function (adapted from GoBuild)
- Committed instances now copy ghost transform directly (prevents double AABB offset)
- `plugin.gd` reduced from 454 lines to ~200 lines by extracting `GhostManager`, `PlacementGizmo`, `InstanceFactory`
- Private field access replaced with public getters on `PlacementController`