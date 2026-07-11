# IEEE 39 Worked Adapter

## Contents

1. Final contract
2. Example configuration
3. Lessons that generalize

## Final contract

The worked project used:

```text
baseMVA = 100
network base = 345 kV
Bus12 base = 230 kV
Bus30-Bus38 base = 20 kV
Bus39 base = 345 kV
Bus30-Bus38 = PV
Bus39 = REF/swing
```

The final model used G39 directly on Bus39, no T39, Y/Y transformers, and `Rm=Lm=inf`. Bus voltages were phase-to-ground p.u. complex phasors reduced to positive sequence. All angles were normalized to Bus39.

## Example configuration

```matlab
cfg = struct();
cfg.projectRoot = 'G:\PythonProject\Matlab_VibeCode\Case_IEEE39';
cfg.model = 'NE39bus_50Hz_24b_10SG_Full_Phasor';
cfg.caseFunction = 'case_ieee39';
cfg.solverFunction = 'pf_run_case';
cfg.addPaths = { ...
    fullfile(cfg.projectRoot,'PF_IEEE39'), ...
    fullfile(cfg.projectRoot,'PF_IEEE39','pf_function')};
cfg.referenceBus = 39;
cfg.simBusIds = (1:39).';
cfg.vmVariable = 'Umag_all';
cfg.vaVariable = 'Uangle_all';
cfg.vmFieldPattern = 'Vm__signal_%d_';
cfg.stopTime = '20';
cfg.outputDirectory = fullfile(cfg.projectRoot,'alignment-results');
cfg.reportPrefix = 'ieee39_10sg';

report = compare_ieee_pf_sim(cfg);
```

The final observed maximum errors were approximately:

```text
Vm: 6.51e-6 p.u.
Va: 6.82e-6 rad
reconstructed P: 2.30e-4 p.u.
reconstructed Q: 1.69e-4 p.u.
```

## Lessons that generalize

- A slack input Pg is not necessarily the solved slack output.
- Impedance-load nominal voltage is part of the load-flow contract.
- A D/Y transformer can dominate angle comparison even when power flow is otherwise correct.
- Steady-state electrical initialization is insufficient when external field commands disagree with saved machine states.
- Phase-to-phase phasors and element-wise magnitude/angle cannot be compared with a positive-sequence bus solution.
- Reference-angle normalization should be explicit in both code and model output.
- Small implementation-specific Ybus corrections must be labeled as numerical equivalence terms, not physical compensation devices.
