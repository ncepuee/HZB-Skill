---
name: align-ieee-powerflow-simulink
description: Align, debug, and validate IEEE standard bus power-flow cases against MATLAB/Simulink Specialized Power Systems phasor models. Use for IEEE 14/30/39/57/118 or custom N-bus systems when comparing MATPOWER-style case data with Simulink, checking PQ/PV/REF mappings, synchronizing line/transformer/load/generator parameters, initializing SPS power_loadflow, extracting positive-sequence voltage, normalizing the slack-angle reference, reconstructing P/Q, diagnosing unstable initialization, or producing numerical alignment reports.
---

# Align IEEE Power Flow and Simulink

Establish one explicit data contract between an IEEE power-flow case and a Simulink SPS phasor model, then prove alignment numerically. Treat IEEE 39 as an example adapter, not as the core schema.

## Required posture

- Inspect the current case, initialization code, model callbacks, masks, topology, and logged outputs before editing.
- Use the MATLAB release requested by the user. Do not silently use another installation.
- Keep power-flow input settings, solved outputs, model initial states, and measured dynamic outputs distinct.
- Do not claim alignment from parameter inspection alone. Run both solvers and report errors.
- Do not tune the Simulink time step to fix a static modeling mismatch. AC power flow has an iteration tolerance, not a time step.
- Preserve user changes. Make model edits transactionally and validate after reload.

## Workflow

### 1. Build the adapter

Identify:

- project root, model file, case function, solver function, MATLAB release;
- system base MVA and bus-specific base kV;
- bus ID order and the single REF/slack bus;
- PQ/PV/REF definitions and generator-to-bus mapping;
- Simulink output variables and their bus order;
- whether measured angles are absolute, transformer-shifted, PLL-wrapped, or already REF-normalized.

Read [references/data-contract.md](references/data-contract.md) before implementing a new system adapter.

Run `scripts/audit_ieee_case.m` on the case before touching the model.

### 2. Compare static network data

Compare by electrical identity, not display position:

1. bus topology and voltage levels;
2. line from/to, R, X, total B, status, and model type;
3. transformer orientation, ratio/tap, winding voltages, vector group, series impedance, rating, Rm/Lm;
4. load P/Q signs, load implementation, nominal voltage, and frequency;
5. generator bus type, P command, voltage command, rating, and connection side;
6. explicit shunts, line charging, and implementation-specific Ybus corrections.

For impedance loads, equal displayed P/Q is insufficient: nominal voltage determines the equivalent R/L/C. For transformer vector groups, compare angles on the same physical side or model the phase shift explicitly.

### 3. Align the SPS load flow

Use `power_loadflow(model,'parameters')` and `power_loadflow(model,'solve',parameters)` when available. Map machines and buses by stable block paths or explicit adapter data; do not assume SPS internal bus IDs equal IEEE bus numbers.

Set:

- PQ/PV/swing types;
- specified generator P/Q where applicable;
- PV/REF voltage commands;
- load values and signs;
- steady-state powergui initialization.

For release-specific mask constraints, keep compatible mask values and inject actual types/setpoints through the returned load-flow parameter structure.

### 4. Align dynamic initial conditions and inputs

Verify that each machine's saved initial state and external constant inputs describe the same operating point. At minimum compare:

- rotor speed and angle;
- stator current magnitude and phase;
- field voltage and field command;
- mechanical power/torque and active-power command.

A powergui steady-state solution does not protect the model from an external field or mechanical command that changes at `t=0`. Large command-to-initial-value ratios are a primary instability diagnostic.

Read [references/sps-alignment.md](references/sps-alignment.md) for SPS-specific failure modes.

### 5. Establish one voltage measurement contract

For balanced positive-sequence comparison, measure phase-to-ground complex phasors in p.u. and compute:

```matlab
a = complex(-0.5, sqrt(3)/2);
V1 = (Vabc(1) + a*Vabc(2) + a^2*Vabc(3)) / 3;
Vm = abs(V1);
Va = atan2(imag(V1), real(V1));
```

Do not use element-wise Complex-to-Magnitude-Angle output as a positive-sequence bus voltage. Do not feed a virtual bus into arithmetic; convert homogeneous scalar bus elements to a vector first.

Normalize both sides to the same reference:

```matlab
VaRef = atan2(sin(Va - Va(refIndex)), cos(Va - Va(refIndex)));
```

If a D/Y transformer remains between the IEEE bus and the measurement point, either move the measurement to the matching side or apply the documented vector-group shift. Never hide it by changing arbitrary initial angles.

### 6. Run numerical validation

Use `scripts/compare_ieee_pf_sim.m` after the adapter is defined. It:

- runs the case solver and Simulink model;
- maps simulation outputs to power-flow bus IDs;
- normalizes both angles to the REF bus;
- compares Vm and Va;
- reconstructs `S = V .* conj(Ybus*V)` on the case Ybus;
- writes a comparison CSV and summary when an output directory is provided.

Distinguish reconstructed P/Q from directly measured device P/Q. For direct generator comparison, use the solved complex power field, typically `real(S)` and `imag(S)`, rather than an input Q field.

Read [references/validation.md](references/validation.md) before declaring success.

### 7. Diagnose in dependency order

When results disagree, investigate in this order:

1. base MVA, base kV, units, signs, and bus order;
2. topology, line charging, taps, shunts, and Ybus;
3. load implementation and nominal voltage;
4. PQ/PV/REF mapping, P commands, and V commands;
5. transformer side and vector-group phase shift;
6. SPS load-flow parameter injection;
7. machine initial conditions and external commands;
8. measurement type, positive-sequence extraction, angle units, and reference;
9. solver tolerance and dynamic settling.

Do not jump to solver settings before exhausting modeling-contract differences.

## Deliverables

Produce:

- a concise discrepancy list with block/case references;
- a bus comparison table containing PF/simulation Vm, REF-normalized Va, and errors;
- optional reconstructed P/Q columns with explicit labeling;
- maximum errors with bus IDs and tolerances;
- a statement of what was and was not directly measured;
- a reproducible run command or adapter configuration;
- a record of model edits and validation performed.

## Resources

- [references/data-contract.md](references/data-contract.md): adapter and result schemas.
- [references/sps-alignment.md](references/sps-alignment.md): SPS load-flow, transformer, load, initialization, and measurement pitfalls.
- [references/validation.md](references/validation.md): tolerance tiers and acceptance rules.
- [references/ieee39-example.md](references/ieee39-example.md): worked IEEE 39 adapter and lessons.
- `scripts/audit_ieee_case.m`: deterministic case-structure audit.
- `scripts/compare_ieee_pf_sim.m`: generic final numerical comparison.
