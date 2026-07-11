# SPS Alignment Notes

## Contents

1. Load-flow initialization
2. Loads and transformers
3. Machine initialization
4. Measurements
5. Common false diagnoses

## Load-flow initialization

`power_loadflow` internal bus IDs and ordering are implementation details. Build an explicit map from IEEE bus IDs to stable block paths. Keep a single REF/swing source unless the solver explicitly supports distributed slack.

Some MATLAB releases require a compatibility value in a synchronous-machine mask while the actual PV/swing type and voltage setpoint are supplied through the `power_loadflow` parameter structure. Validate the solved structure, not only mask text.

Set powergui to steady-state initialization for steady operating-point comparisons. Zero-state initialization answers a different question.

## Loads and transformers

Three-Phase Parallel RLC Load blocks are impedance loads. Their P/Q values define R/L/C at nominal voltage; changing nominal voltage changes the network admittance. Align nominal voltage to the intended operating-point voltage when matching a constant-P/Q power-flow target at one steady state.

Transformer checks must include:

- winding orientation and voltage side;
- vector group and phase shift;
- rating/base conversion;
- tap direction;
- series R/X split across windings;
- magnetizing Rm/Lm and whether the power-flow case includes the resulting shunt.

Do not add a fitted bus shunt and retain the physical magnetizing branch unless the case intentionally contains both.

## Machine initialization

Compare every constant input against the corresponding initial-state component. A machine can have a correct saved load-flow state and still leave it immediately when field voltage, mechanical torque, or active-power command changes at `t=0`.

Useful diagnostics:

```text
field command / initial Vf
mechanical command / initial electrical P
initial terminal Vm / requested Vset
initial current phase / transformer-side voltage phase
```

Ratios far from one are actionable even before a long simulation.

## Measurements

For positive-sequence bus voltage, use complex phase-to-ground phasors. Enable the p.u. option based on nominal phase-to-ground voltage when the block provides separate line-line and phase-ground bases.

Element-wise magnitude/angle of `[Va,Vb,Vc]` is not a positive-sequence scalar. Apply the symmetrical-component formula first.

A virtual Bus Creator output is not numeric. Use Bus to Vector, Mux, Vector Concatenate, or a MATLAB Function with an explicit interface before arithmetic.

## Common false diagnoses

- Changing `Ts` to fix a static voltage profile.
- Comparing a PLL's unwrapped absolute angle with a REF-normalized load-flow angle.
- Comparing phase-to-phase measurement with a phase-to-ground positive-sequence formula.
- Reading an input Q field as solved generator Q instead of `imag(S)`.
- Treating a D/Y phase shift as a Newton-Raphson convergence error.
- Assuming equal load P/Q labels imply equal impedance-load behavior.
- Assuming powergui steady-state initialization also aligns external machine commands.
