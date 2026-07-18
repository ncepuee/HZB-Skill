---
name: route-simulink-schematics
description: Create, rearrange, or audit human-readable Simulink and Simscape schematics using topology-first placement and orthogonal bundled routing. Use for .slx/.mdl layout work, tangled or overlapping wires, line-through-block defects, three-phase parallel wiring, branch-heavy feeder diagrams, reproducing a user-edited visual style, or comparing an automatic layout with a trusted reference. Do not use as a substitute for behavioral, numerical, or electrical validation.
---

# Route Simulink Schematics

Route the model as a readable schematic of its topology. Choose block positions and
orientations before drawing wires; treat multi-conductor connections as atomic
bundles; preserve trusted user regions.

Read [routing-principles.md](references/routing-principles.md) before changing a
branch-heavy or multi-conductor model. It contains the priority order, layout
grammar, anti-patterns, and empirical IEEE 123-node reference evidence behind
this workflow.

## Protect the Reference

1. Treat the latest user-edited model as read-only ground truth unless the user
   explicitly asks to change it.
2. Save a timestamped backup before any model edit. Never overwrite the only
   trusted visual reference.
3. Record protected blocks, regions, and line corridors. Keep their positions,
   orientations, and line points unchanged during unrelated repairs.
4. If a previous automatic version exists, preserve it as the candidate for
   comparison. Do not infer the old layout from the edited file.

## Inspect Before Editing

1. Follow the active Simulink model-building skill's library-policy gate when it
   is available.
2. Use structured `model_read` before local MATLAB analysis or editing. Read the
   root first, then only the subsystems needed for routing.
3. Extract block names, positions, orientations, port locations, line trees,
   line points, and physical connectivity with `get_param` when geometry is not
   exposed by structured tools.
4. Export a whole-model image plus enlarged images of branch hubs. Numerical
   metrics cannot determine whether a schematic is easy to read.
5. Classify the connectivity graph:
   - source and slack chain;
   - main spine segments;
   - degree-two continuation chains;
   - branch hubs with three or more incident devices;
   - terminal lines;
   - leaf loads, capacitors, monitors, and controls.

## Place Topology First

Work from the graph hierarchy, not from the existing canvas coordinates.

1. Reserve long horizontal or vertical corridors for main spines.
2. Place each line block and its downstream bus inline whenever practical. Match
   their cross-axis spans and phase-port coordinates exactly.
3. At degree-two buses, keep the upstream line, bus, and dominant downstream line
   as one straight chain. A load must not interrupt this chain.
4. At a branch hub, assign one clear direction to each important outgoing feeder.
   Keep turns in whitespace and separate adjacent branch corridors.
5. Place loads and capacitors last. If a straight leaf placement obstructs a
   feeder, offset the leaf into a free side lane and use one short, parallel
   dogleg bundle.
6. Choose orientation from the complete local chain and available corridor.
   Allow 90-degree rotation. Merely flipping a block so LConn faces the geometric
   upstream center is insufficient.
7. Keep labels, phase names, and ABC/abc terminal markings visible. Adjust
   `NamePlacement` only after positions and orientations stabilize.
8. Use a consistent grid and block family dimensions. For a three-phase family,
   keep the same cross-axis span and port pitch across buses, lines, and leaves.

## Route in Priority Order

Route one visual region at a time:

1. main spine bundles;
2. secondary feeder bundles;
3. branch-hub junctions;
4. loads and capacitors;
5. measurement and control signals.

For every multi-conductor bundle:

- preserve conductor order from source to destination;
- use the same ordered H/V turn signature for all conductors;
- keep constant pitch on every shared straight and through every bend;
- turn the bundle together; stagger bend coordinates only by the phase pitch;
- use the fewest bends compatible with clearance;
- branch in whitespace, never inside a block or label;
- do not merge distinct conductors onto one coordinate;
- avoid global `routeLine` after a manual or protected layout is established.

When a route is poor, reconsider nearby block orientation and position before
adding a distant detour lane. Long rectangular loops are evidence of a placement
failure, not a routing solution.

## Optimize Lexicographically

Accept a lower-priority improvement only when it does not worsen a higher one:

1. preserve electrical and signal connectivity;
2. zero unconnected required ports and dangling lines;
3. zero block overlap and wire penetration through block interiors;
4. zero same-bundle overlap, phase-order reversal, and diagonal segments;
5. minimize crossings between unrelated bundles;
6. maximize straight continuation of main spines and line-to-bus pairs;
7. minimize bend count, wire length, and detour ratio;
8. keep branch corridors separated and visually symmetric;
9. minimize canvas area without crowding labels or ports.

Do not collapse these criteria into one lightly weighted sum. A shorter wire is
not better if it crosses a block, and a collision-free route is not good if it
creates many remote loops.

## Compare Against a Trusted Layout

Use the bundled read-only MATLAB analyzer when a human reference and an automatic
candidate are available:

```matlab
addpath('<skill>/scripts');
result = compare_simulink_schematic_layouts( ...
    "preferred_human_layout.slx", ...
    "automatic_candidate.slx", ...
    "layout_evidence");
```

Inspect these outputs:

- `layout_comparison_summary.json` for aggregate geometry;
- `block_layout_differences.csv` for moved, rotated, and resized blocks;
- `block_category_summary.csv` for family-level changes;
- `*_bundle_metrics.csv` for three-phase turn consistency;
- `*_line_block_conflicts.csv` for localized penetrations.

Treat the analyzer as evidence, not an automatic acceptance oracle. Some line
objects represent branches or duplicated visual segments; verify suspicious
counts on exported images.

## Repair Locally

1. Rank conflict regions by topology importance and violation count.
2. Freeze already-correct neighboring regions.
3. For one region, try in order: small translation, axis rotation, leaf offset,
   branch-corridor reassignment, then local line-point rewrite.
4. Re-read that region and re-run geometry checks.
5. Stop changing the region once it passes; do not globally normalize it later.

## Validate and Save

Before saving:

1. Re-read the edited scope and confirm block/connection counts.
2. Run structural checks for unconnected ports and dangling lines.
3. Update or compile the model to catch port, domain, and parameter errors.
4. Confirm zero diagonals, zero block overlap, zero same-bundle overlap, and no
   line-through-device defects. Review every remaining exception visually.
5. Export the whole model and representative branch hubs for visual review.
6. Run the model's behavioral or numerical regression separately. For power
   systems, layout success does not prove power-flow agreement.
7. Save to the requested Simulink release explicitly and reopen that artifact.

Report the saved model path, protected reference path, structural results,
geometry metrics, visual exceptions, and behavioral validation separately.
