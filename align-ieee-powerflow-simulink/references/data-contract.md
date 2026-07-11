# Data Contract

## Contents

1. Case input contract
2. Solver result contract
3. Simulink adapter contract
4. Units and signs

## Case input contract

The bundled audit script expects a MATPOWER-style normalized structure:

```text
pfcase.baseMVA              positive scalar
pfcase.bus                  numeric matrix, at least 10 columns
pfcase.branch               numeric matrix, at least 6 columns
```

Default bus columns:

```text
[ID, Type, Vm, Va_deg, Pd, Qd, Pg, Qg, Vmin, Vmax]
```

Default branch columns:

```text
[From, To, R, X, B_total, Tap]
```

Default bus types are `PQ=1`, `PV=2`, `REF=3`. Build an adapter before using another convention.

## Solver result contract

`compare_ieee_pf_sim.m` expects the solver result to contain:

```text
result.success
result.bus                 table
result.bus.ID
result.bus.Vm
result.bus.Va_rad
result.bus.P_calc
result.bus.Q_calc
result.Ybus
```

Wrap MATPOWER `runpf` or another solver to this result contract rather than adding solver-specific branches to the core workflow.

## Simulink adapter contract

Required configuration fields:

```matlab
cfg.projectRoot
cfg.model
cfg.caseFunction
cfg.referenceBus
```

Common optional fields:

```matlab
cfg.solverFunction = 'pf_run_case';
cfg.addPaths = {...};
cfg.stopTime = '20';
cfg.vmVariable = 'Umag_all';
cfg.vaVariable = 'Uangle_all';
cfg.simBusIds = (1:n).';
cfg.vmFieldPattern = 'Vm__signal_%d_';
cfg.preSimulationFcn = [];
cfg.outputDirectory = '';
cfg.reportPrefix = 'ieee_alignment';
cfg.tolerances = struct('vm',1e-4,'va',1e-4,'p',1e-3,'q',1e-3);
```

Outputs may be numeric arrays, `timeseries` vectors, old Structure-with-Time values, or structs whose fields are scalar `timeseries`. Supply explicit `vmFields`/`vaFields` when automatic numeric-suffix ordering is unsafe.

## Units and signs

- Store power-flow P/Q on `baseMVA`; convert Simulink W/var by `baseMVA*1e6`.
- Use line-to-line RMS voltage for bus base kV unless the model explicitly defines another convention.
- Treat positive `Pd/Qd` as consumption in the case contract.
- Treat negative Q load as capacitive injection; map it to the model's capacitive parameter without reversing it twice.
- Store branch B as total line charging input. Document whether the solver uses simple pi or a distributed/SPS equivalent.
- Compare radians with radians. Convert degrees only at input/output boundaries.
- Normalize all angles to the same REF bus after accounting for transformer side and vector group.
