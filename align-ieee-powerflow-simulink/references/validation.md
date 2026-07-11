# Validation and Acceptance

## Contents

1. Validation layers
2. Suggested tolerances
3. Required reporting

## Validation layers

Validate progressively:

1. **Case structure**: unique IDs, valid bus types, one REF, valid branch endpoints, nonzero series impedance.
2. **Static parameter equality**: bases, topology, branches, shunts, loads, generators, transformer sides.
3. **Native load flow**: case solver and SPS load flow both converge.
4. **Initial state**: simulation at `t=0` matches the intended operating point.
5. **Settled dynamic state**: final window is stationary and matches the case.
6. **Power balance**: direct measured or reconstructed P/Q agrees, with method labeled.

## Suggested tolerances

Choose tolerances from model fidelity and state them explicitly. Suggested starting tiers:

| Tier | Vm p.u. | Va rad | P/Q p.u. | Use |
|---|---:|---:|---:|---|
| Exact numerical | `1e-6` | `1e-6` | `1e-5` | Same Ybus and algebraic model |
| Strong alignment | `1e-4` | `1e-4` | `1e-3` | SPS phasor vs custom NR solver |
| Engineering match | `1e-3` | `1e-3` | `1e-2` | Different but documented implementations |

Do not weaken tolerances to hide systematic errors. A common offset across generator buses usually indicates angle reference or transformer vector group; voltage-dependent errors often indicate load nominal voltage, tap, shunt, or base mismatch.

## Required reporting

Report:

- solver convergence and maximum mismatch;
- maximum absolute Vm/Va/P/Q errors and bus IDs;
- REF bus values on both sides;
- simulation stop time and final-window drift when available;
- whether P/Q is direct device measurement, SPS load-flow output, or Ybus reconstruction;
- unresolved warnings and measurement limitations;
- exact files, model names, MATLAB release, and adapter configuration.

Passing Vm/Va does not prove direct generator P/Q is correct if P/Q was reconstructed from the same case Ybus. Label the evidence honestly.
