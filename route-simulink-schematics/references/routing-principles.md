# Topology-First Simulink Routing Principles

## Empirical Basis

These rules were refined by comparing a user-routed IEEE 123-node three-phase
feeder with the closest preserved automatic layout. Both models contained the
same 341 root blocks and had zero block overlap and zero diagonal segments. The
human layout achieved the following lower-is-better changes:

| Metric | Human reference | Automatic candidate | Improvement |
|---|---:|---:|---:|
| Total Manhattan wire length | 91,147 | 141,274 | 35.48% |
| Bend count | 62 | 440 | 85.91% |
| Wire/block interior events | 13 | 417 | 96.88% |
| Orthogonal line crossings | 302 | 549 | 44.99% |
| Collinear line overlaps | 17 | 391 | 95.65% |
| Three-phase turn-signature mismatches | 16 | 84 | 80.95% |
| Canvas area | 22,308,685 | 27,251,575 | 18.14% |

The comparison found 256 moved blocks and 47 orientation changes. Forty-three
of the orientation changes switched between horizontal and vertical axes. This
shows why a rule that only flips left/right or up/down cannot recover the human
layout.

All 123 buses, 124 line modules, 85 loads, and 4 capacitors in the reference used
a 56-pixel cross-axis phase span and 20-pixel port pitch, with zero pitch
mismatches. Of 123 line-to-downstream-bus pairs, 114 were axis-matched and
cross-axis aligned, compared with 102 in the automatic layout.

Every load in both layouts faced its own bus, so upstream-facing orientation was
not a discriminating quality measure. The automatic layout placed 82 of 85 loads
directly inline with their buses; the human layout kept only 34 inline. The human
layout deliberately offset leaves where direct placement would obstruct a main
or secondary feeder. This is the strongest evidence for trunk-first priority.

The human reference still contained 13 wire/block detections localized to four
blocks. Treat those as audit exceptions, not style examples.

## Layout Grammar

### Main spine

A main spine is a long, nearly monotone chain from the source through important
branch buses. Represent it as repeated line–bus–line units on one horizontal or
vertical axis. Keep conductor pitch constant. Avoid moving the spine around a
leaf device.

### Continuation bus

At a degree-two continuation bus, align the incoming line, measurement bus, and
dominant outgoing line. Place any load or capacitor on an unused side. This makes
the topology readable without tracing labels.

### Branch hub

At a degree-three-or-more bus, reserve the straight direction for the dominant
continuation. Assign secondary feeders to separate side corridors. Fan out near
the bus, then keep each bundle straight. Do not send multiple feeders through a
single remote detour lane.

### Terminal branch

Place the terminal line and bus inline. Put the leaf load beyond the bus when the
space is clear; otherwise offset it into an adjacent free lane with one dogleg.

### Leaf device

The leaf's connection side must face the bus or the first local bend corridor,
but the leaf's center need not align with the bus. Main and secondary feeders
have placement priority over loads, capacitors, meters, and controls.

## Three-Phase Bundle Geometry

Treat A/B/C as one ribbon, not three independent wires.

- At ports, preserve phase order and pitch exactly.
- A straight ribbon uses three parallel segments of equal direction.
- At a 90-degree turn, all phases use the same turn order. Offset their bend
  coordinates by the phase pitch so the ribbon neither collapses nor reverses.
- Use one or two bends for normal local connections. Three or more bends require
  a visible obstacle or reserved corridor.
- Keep each phase's detour ratio close to the others. A single phase should not
  take a different side of an obstacle.
- Avoid collinear overlap between phases. It hides conductors and can make
  connectivity visually ambiguous.
- Place branch points in whitespace and make the three phase branch points form
  the same geometric pattern.

## Orientation Rules

Determine orientation after choosing a region's topology and corridors:

1. Select the dominant chain direction.
2. Rotate blocks so their conductor ports span the cross-axis and line up with
   neighboring modules.
3. Ensure the upstream connection exits the correct block side.
4. Verify the downstream side has enough space for the next block or fanout.
5. Verify ABC/abc text and block names remain visible.

Do not preserve an old horizontal/vertical axis merely because the block already
has it. Do not choose orientation solely from the vector between block centers;
a deliberately offset leaf can use a dogleg while retaining a clean port exit.

## Placement Before Routing

Use this order within each region:

1. fix bus locations defining the spine;
2. align line and regulator modules with those buses;
3. allocate branch corridors;
4. place loads and capacitors in remaining whitespace;
5. move labels away from conductor corridors;
6. draw or rewrite line points.

If a route needs a long excursion around an endpoint block, move or rotate that
block first. Endpoint-clearance routing is a final polish, not a substitute for
placement.

## Why the Earlier Automatic Method Failed

The earlier method optimized local constraints but lacked a hierarchy:

- It preserved each block's horizontal/vertical axis and only flipped direction,
  while the successful layout required many 90-degree rotations.
- It considered each connection separately instead of reserving shared feeder
  corridors and routing three phases as a ribbon.
- It forced leaves toward direct radial alignment, consuming the space needed by
  important continuations.
- It repaired endpoint penetration with distant top/bottom/left/right lanes,
  creating long rectangular loops and extra bends.
- Its score emphasized endpoint crossings, within-bundle overlap, and total
  length but omitted unrelated-bundle crossings, branch hierarchy, turn
  consistency, continuation alignment, and visual region compactness.
- It applied global rerouting after placement, allowing Simulink line-tree
  behavior to undo carefully chosen local routes.
- It used zero block overlap and zero diagonals as evidence of quality, although
  the automatic and human layouts both passed those weak tests.

## Acceptance Checklist

### Structure

- Same required blocks, ports, and connections as the validated functional model.
- No required unconnected port or dangling line.
- Model compiles and behavioral regressions pass.

### Blocks

- No overlapping rectangles.
- Consistent family sizes and port pitch.
- Labels and terminal markings visible.
- Main chains and branch hubs recognizable without reading every block name.

### Wires

- Orthogonal segments only unless the visual standard explicitly allows otherwise.
- No wire through a block interior or label.
- No hidden same-bundle overlap or phase-order reversal.
- Three phases share a turn signature and corridor.
- Main spines use fewer bends than subordinate branches.
- Leaves never force a main feeder into a long detour.

### Process

- Trusted user regions are locked.
- Repairs are local and re-audited before moving on.
- Whole-model and enlarged-region images are reviewed.
- Remaining metric exceptions are enumerated rather than silently accepted.
