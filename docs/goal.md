# GoPlacer — Project Goal

## North Star

> **Bring first-class asset placement tooling to Godot 4, so level designers can block out and populate worlds without fighting the scene tree.**

GoPlacer is a Godot 4 EditorPlugin that gives designers the palette-based, snap-aware placement workflow they expect from tools like Unity's Prefab Palette or Unreal's Foliage mode — directly inside Godot. It targets indie developers, level designers, and solo creators who want to paint props onto surfaces, organise assets into reusable palettes, and parent placed objects to targeted containers without manual drudgery.

---

## What GoPlacer Is

- A **palette-driven prop placer** — browse, search, and pick assets from named palettes, then click to place them in the viewport.
- A **snap-aware placement engine** — floor snapping, surface snapping, grid snapping, and azimuth/orientation control so props land exactly where they belong.
- A **brush painter** — paint instances of an asset across a surface with configurable density, scale jitter, and random rotation.
- A **parenting system** — placed instances are parented to a user-specified container node, keeping the scene tree clean.
- **Open-source and community-driven** — free to use, transparently developed, GPL v3 licensed.

## What GoPlacer Is Not

- A replacement for manual scene organisation (it accelerates placement, not design intent).
- A procedural generation system (though it can be combined with one).
- A runtime spawning library. GoPlacer targets the Godot **editor** only; it does not ship code into your game build.

---

## Success Criteria (v1.0 core placement workflow)

| Capability | Target |
|---|---|
| Asset palettes | Create, edit, and save palettes of PackedScene / Mesh resources; drag to reorder |
| Palette browsing | Searchable, icon-previewed list in a dock panel |
| Single-click placement | Select an asset from the palette, click in the viewport to place an instance |
| Floor snapping | Ray-cast down from the mouse; snap the instance origin to the hit surface (floor/surface) |
| Azimuth / orientation | Configurable snap angles for Y-axis rotation (0°, 15°, 30°, 45°, 90°, free) |
| Grid snapping | Optional grid snap aligned with the editor grid step |
| Target parent | Placed instances are parented to a specified node; default is the scene root |
| Undo / Redo | Every placement is undoable via Godot's EditorUndoRedoManager |
| Brush painting | Click-drag to scatter instances with density, scale jitter, and random rotation |
| Multi-palette | Switch between multiple palettes; persist palettes as .tres resources |

---

## Guiding Principles

1. **Editor-first.** Every workflow must feel native to Godot. No detached windows, no external processes.
2. **Fast to place.** A designer should go from "I want a tree" to "tree is in the scene" in two clicks or less.
3. **Non-destructive.** Placed instances are real scene nodes — they can be moved, edited, or deleted by hand after placement.
4. **Organised.** Target parent keeps the scene tree structured; no flat lists of thousands of nodes under root.
5. **Stable.** Test coverage on all algorithmic code. A broken plugin that pollutes a scene is worse than a missing feature.