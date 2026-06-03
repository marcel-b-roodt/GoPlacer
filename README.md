# GoPlacer

**Free, open-source asset placement toolkit for Godot 4.**

> Browse asset palettes, click to place, snap to floors, paint with brushes — all inside the editor.

[![CI](https://github.com/marcel-b-roodt/GoPlacer/actions/workflows/ci.yml/badge.svg)](https://github.com/marcel-b-roodt/GoPlacer/actions/workflows/ci.yml)

---

## What is GoPlacer?

GoPlacer is a Godot 4 EditorPlugin that brings palette-based asset placement directly into Godot. Create palettes of your reusable scenes and meshes, then click to place them in the 3D viewport with floor snapping, rotation snapping, and automatic parenting. Designed for level blockout, environment dressing, and prop scattering. No external tools required.

## Status

🔧 **Active development — Stage 0 (Foundation).**

Asset palettes, single-click placement, floor snapping, and target parenting are in progress. See [GUIDE.md](GUIDE.md) for what you can do right now.

## Installation

**From the Godot Asset Library** *(once listed)*:
1. Open **Project → AssetLib** inside Godot.
2. Search for **GoPlacer** and install.
3. Enable the plugin under **Project → Project Settings → Plugins**.

**From a release zip**:
1. Download the latest zip from [Releases](https://github.com/marcel-b-roodt/GoPlacer/releases).
2. Drop the `addons/go_placer/` folder into your project's `addons/` directory.
3. Enable the plugin under **Project → Project Settings → Plugins**.

**From source**:
```bash
git clone https://github.com/marcel-b-roodt/GoPlacer.git
```
Open `project.godot` in Godot 4. The plugin activates automatically.

## Quick Start

See **[GUIDE.md](GUIDE.md)** for a full walkthrough — creating palettes, placing assets, and using snap settings.

## Roadmap

| Stage | Version | Focus |
|---|---|---|
| 0 | `v0.1.x` | Palettes, single-click placement, floor snapping, target parent, undo |
| 1 | `v0.2.x` | Grid & surface snapping, normal alignment, rotation/scale shortcuts |
| 2 | `v0.3.x` | Brush painting, density, scale jitter, erase brush |
| 3 | `v0.4.x` | Multi-palette UI, tags, search, auto-parent detection |
| 4 | `v0.5.x` | Path scatter, foliage painting, collision masking, random selection |
| 5 | `v0.6.x` | Polish, keyboard shortcuts, preferences, ghost preview, thumbnails |
| 6 | `v1.0` | Full release, Asset Library, docs, demo project |

## AI Tooling Transparency Disclosure

Most code in this repository was generated with AI assistance and reviewed by the maintainer. Specifically:

- **Tooling:** [OpenCode](https://opencode.ai) (models previously run through VS Code Copilot integration), running GLM-5.1 or latest (an open-weight model from [Zhipu AI / THUDM](https://github.com/THUDM/GLM-4), [glm-4 license](https://huggingface.co/THUDM/glm-4-9b/blob/main/LICENSE)) via [Ollama](https://ollama.com). Other models, provided they are open-source and appropriately licensed, may also be used.
- **Human role:** Project architecture, feature design, code structure, acceptance testing, and all release decisions are made by the maintainer. Every AI-generated change is read, evaluated, and tested before merging. No code ships without human approval.
- **CI:** All code passes `gdparse` (syntax), `gdlint` (style), and a GdUnit4 test suite on every push via GitHub Actions.
- **Not used:** Autonomous agents, unsupervised commits, or unsupervised merges. No outside contributors.

If you have questions about how any piece of code was written or verified, please feel free to open an issue.

## Contributing

Bug reports and feature requests are welcome. Please open an issue first for significant changes.

## Support the project

GoPlacer is free and open-source. If it saves you time, consider supporting development on [Patreon](https://patreon.com/goplacer_godot) or [Ko-fi](https://ko-fi.com/marcelroodt).

## License

GPL v3 — see [LICENSE.md](LICENSE.md).