# GoPlacer — How-To Guide

> Everything you need to start placing assets in Godot with GoPlacer.

---

## Table of Contents

1. [The big idea](#the-big-idea)
2. [Installation](#installation)
3. [The GoPlacer Panel](#the-goplacer-panel)
4. [Creating a palette](#creating-a-palette)
5. [Adding assets to a palette](#adding-assets-to-a-palette)
6. [Placing an asset](#placing-an-asset)
7. [Floor snapping](#floor-snapping)
8. [Rotation snapping](#rotation-snapping)
9. [Target parenting](#target-parenting)
10. [Undo and Redo](#undo-and-redo)

---

## The big idea

GoPlacer gives you a **palette** of reusable assets and a **click-to-place** workflow in the 3D viewport.

- **Palettes** are saved resources (.tres) that group assets together — trees, props, architecture, etc.
- **Placement** is a single click in the viewport: select an asset from the palette, click on a surface, and the instance appears.
- **Floor snapping** ray-casts downward so objects land on the ground.
- **Target parenting** keeps your scene tree clean by placing instances under a chosen parent node.

---

## Installation

1. Copy the `addons/go_placer/` folder into your project's `addons/` folder.
2. Open **Project → Project Settings → Plugins**.
3. Find **GoPlacer** and set it to **Enabled**.
4. A **GoPlacer** panel appears in the left dock.

---

## The GoPlacer Panel

The GoPlacer panel lives in the left dock. It has three sections:

| Section | What it does |
|---|---|
| **Palettes** | Create, rename, and delete palettes. Switch between them. |
| **Assets** | Shows the entries in the active palette. Click one to select it for placement. |
| **Settings** | Snap angle, target parent node, and brush settings (when available). |

If no palette is selected, the panel shows a prompt to create one.

---

## Creating a palette

1. Click **+ New Palette** in the panel header.
2. Give the palette a name (e.g. "Trees", "Props", "Architecture").
3. The palette is saved as a `.tres` resource in your project.

Palettes persist across editor sessions. You can have as many as you like.

---

## Adding assets to a palette

1. Select a palette in the panel.
2. Click **+ Add Asset** or drag a scene/mesh from the FileSystem dock.
3. Each entry stores a reference to a `PackedScene` or `Mesh`, a display name, and optional tags.

Drag entries to reorder them within the palette.

---

## Placing an asset

1. Click on an asset entry in the palette to select it.
2. Move your mouse over the 3D viewport.
3. Click to place an instance at the cursor position.

The instance is placed at the world position determined by the ray-cast from your mouse through the viewport. If **Floor Snapping** is enabled, the Y position adjusts to land on the surface below.

---

## Floor snapping

Floor snapping is **on by default**. It ray-casts downward from the mouse position to find the nearest surface below and places the asset at that height.

| Setting | What it does |
|---|---|
| **Enabled / Disabled** | Toggle floor snapping in the Settings section. |
| **Ray length** | How far down the ray-cast searches (default: 1000 units). |

When floor snapping is off, assets are placed at the cursor height in 3D space.

---

## Rotation snapping

GoPlacer supports configurable Y-axis rotation snapping for placed assets.

| Snap angle | Behaviour |
|---|---|
| **Free** | No snapping; rotate freely. |
| **15°** | Snap to 15° increments. |
| **30°** | Snap to 30° increments. |
| **45°** | Snap to 45° increments. |
| **90°** | Snap to 90° increments. |

Use `[` and `]` keys to rotate the placement angle before clicking. Use the mouse scroll wheel for fine rotation when in free mode.

---

## Target parenting

Placed instances need a parent node in the scene tree. By default, GoPlacer parents new instances to the scene root.

To specify a target parent:
1. In the **Settings** section, click the **Target Parent** node picker.
2. Select a node in your scene (e.g. a "Props" or "Environment" node).
3. All subsequent placements will parent to that node.

You can also add a node named **GoPlacerParent** to your scene. GoPlacer will detect it automatically and use it as the default parent.

---

## Undo and Redo

All GoPlacer operations are fully undoable through Godot's standard undo stack.

| Action | Shortcut |
|---|---|
| Undo | **Ctrl+Z** |
| Redo | **Ctrl+Shift+Z** |

This includes: placing an asset, deleting a placed asset, and creating/modifying palettes.