# **🏗️ HeidNodes Framework**

![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Maintained](https://img.shields.io/badge/maintained%3F-yes-green?style=for-the-badge)
![Melos](https://img.shields.io/badge/monorepo-managed%20with%20Melos-magenta?style=for-the-badge)

> **HeidNodes** is an actively maintained fork of [FlNodes](https://github.com/WilliamKarolDiCioccio/fl_nodes) focused on **drag improvements, performance optimizations, and enhanced rendering stability**.

---

## 🎯 What is HeidNodes?

**HeidNodes** is a modular, high-performance Flutter framework for building node-based visual editors and graph interfaces. Built on a proven foundation and enhanced with stability fixes, optimized drag interactions, and refined rendering performance.

### 📍 Fork Focus

This fork addresses critical issues found in the original FlNodes:

- ✅ **Drag & Drop Fixes** — Improved node dragging stability, better proxy handling, and smoother interactions
- ✅ **Rendering Optimizations** — Reduced unnecessary repaints, smarter viewport culling, optimized link rendering
- ✅ **Performance Tuning** — Better memory management, efficient spatial hashing, reduced jank during complex operations
- ✅ **Stability Enhancements** — Fixed edge cases in layout calculations, improved state synchronization, robust parent data handling

---

## 💡 Use Cases

Build professional-grade node editors for:

- 🎮 **Visual Scripting Editors** – Game logic, automation flows, or state machines.
- 🛠 **Workflow & Process Designers** – Business rules, decision trees, and automation paths.
- 🎨 **Shader & Material Graphs** – Build custom shaders visually.
- 📊 **Dataflow Tools** – ETL pipelines, AI workflows, and processing graphs.
- 🤖 **ML Architecture Visualizers** – Visualize and configure neural networks.
- 🔊 **Modular Audio Systems** – Synthesizers, effect chains, or sequencing tools.
- 🧠 **Graph-Based UIs** – Mind maps, dependency trees, and hierarchical structures.

---

## 🏗️ Framework Architecture

The HeidNodes Framework is organized as a monorepo with specialized packages:

### 📦 Core Packages

- [**`fl_nodes_core`**](./packages/fl_nodes_core) – The engine that powers HeidNodes: rendering (Flutter shaders), infrastructure, node graph system, and optimized drag handling.

- [**`fl_nodes`**](./packages/fl_nodes) – A proxy export package that maintains backward compatibility with earlier versions.

### 🔌 Utilities & Examples

- [**`fl_context_menu`**](./packages/fl_context_menu) – Context menu utility used in examples.
- [**`examples/fl_nodes_example`**](./examples/fl_nodes_example) – Main example app showcasing the framework and optimizations.
- [**`examples/fl_context_menu_example`**](./examples/fl_context_menu_example) – Context menu example.
- [**`benchmarks`**](./benchmarks) – Performance benchmarks and profiling tools.

### 🚀 Coming Soon

- **`fl_nodes_visual_scripting`**
- **`fl_nodes_mind_maps`**
- **`fl_nodes_flow_graphs`**

---

## 📚 Getting Started

For a fast and easy setup, check out our [Quickstart Guide](https://github.com/daslaller/HeidNodes/wiki/Quickstart). It covers the basics to get you up and running with **HeidNodes** in no time.

If you're migrating from the original FlNodes, the `fl_nodes` package maintains full backward compatibility while providing access to the new performance-enhanced architecture.

---

## 📦 Installation

Choose the package that fits your needs:

```yaml
dependencies:
  # For most users - high-level API with full features
  fl_nodes: ^latest_version

  # For advanced users needing low-level control
  fl_nodes_core: ^latest_version
```

Regardless of the package you choose, you must add the following asset:

```yaml
flutter:
  shaders:
    - packages/fl_nodes_core/shaders/grid.frag
```

Then, run:

```bash
flutter pub get
```

---

## 🧪 Running Examples & Benchmarks

All melos commands are defined in root `pubspec.yaml`:

```bash
melos bootstrap              # Install all deps
melos run example            # Run example in Chrome
melos run example:profile    # Profile mode with performance insights
melos run example:release    # Optimized release build
melos run format             # dart format across all packages
melos run analyze            # dart analyze --fatal-infos across all packages
```

**Note:** Run tests manually per-package with `flutter test`. Performance benchmarks are in the `benchmarks/` directory.

---

## 🚀 Key Improvements in HeidNodes

### Drag & Drop Enhancements

- **Proxy Offset Management** — Accurate offset tracking during drag operations
- **State Synchronization** — Improved parent data consistency during interactions
- **Smooth Interactions** — Reduced latency in drag operations with optimized hit testing

### Rendering Optimizations

- **Compositor-Isolated Link Tiers** — Static links cached, only active tier animates
- **Viewport Culling** — Smart spatial hash querying with inflation buffer
- **Reduced Repaints** — Granular dirty flags for selective rendering updates
- **Port Batching** — Grouped port rendering by style to reduce draw calls

### Performance Tuning

- **Modal Handling** — Proper layout synchronization when overlays are active
- **Locale Change Resilience** — Forced full passes prevent text rendering desynchronization
- **Lazy Layout** — Children only laid out if dirty or outside viewport
- **Efficient Event Handling** — Categorized events (Paint, Layout, Drag, Tree) for targeted updates

### Stability

- **Robust Renderbox Tracking** — Cached layout rects prevent state desync
- **Safe Parent Data Access** — Null checks and defensive copies throughout
- **Well-Tested Edge Cases** — Handles complex scenarios (collapse, selection, hover, locale changes)

---

## 📊 Current Input Support

**Legend:**

- ✅ Supported
- ❌ Unsupported
- ⚠️ Partial
- 🧪 Untested

| 🖥️Desktop and 💻 Laptop: | Windows | Linux | macOS |
| ------------------------ | ------- | ----- | ----- |
| **native/mouse**         | ✅      | ✅    | ✅    |
| **native/trackpad**      | ✅      | 🧪    | ✅    |
| **web/mouse**            | ✅      | ✅    | ✅    |
| **web/trackpad**         | ✅      | ✅    | 🧪    |

| 📱 Mobile | Android | iOS |
| ---------- | ------- | --- |
| **native** | ✅      | 🧪  |
| **web**    | ✅      | 🧪  |

---

## 🔄 Comparison with Original FlNodes

| Feature | Original | HeidNodes |
| --- | --- | --- |
| **Drag Stability** | ⚠️ Baseline | ✅ Optimized |
| **Rendering Performance** | Good | ✅ Enhanced |
| **Link Rendering** | ✅ | ✅ Optimized (tiered) |
| **Backward Compatibility** | N/A | ✅ Full |
| **Spatial Hashing** | ✅ | ✅ Improved querying |
| **Modal Support** | ⚠️ Basic | ✅ Robust |

---

## 🙌 Contributing

We'd love your help in making **HeidNodes** even better! You can contribute by:

- 💡 [Suggesting improvements](https://github.com/daslaller/HeidNodes/issues)
- 🐛 [Reporting bugs](https://github.com/daslaller/HeidNodes/issues)
- 🔧 [Submitting pull requests](https://github.com/daslaller/HeidNodes/pulls)
- 👏 [Sharing what you've built](https://github.com/daslaller/HeidNodes/discussions)

### Development Guidelines

See [AGENTS.md](./AGENTS.md) for architecture overview and coding conventions.

---

## 📜 License

**HeidNodes** is open-source and released under the [MIT License](LICENSE.md).  
Based on the original FlNodes by [WilliamKarolDiCioccio](https://github.com/WilliamKarolDiCioccio/fl_nodes).

---

## 🚀 Let's Build Together!

Enjoy using HeidNodes and **create amazing node-based UIs** for your Flutter apps! 🌟

For questions or support, open an issue or reach out via discussions.
