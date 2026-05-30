---
name: multivariable-control
description: "Multivariable feedback control analysis and design expert based on Skogestad & Postlethwaite's textbook. Use when working with MIMO systems, H-infinity control, mu-analysis, robust control design, SVD analysis, condition number, RGA, or any multivariable control theory problem."
metadata:
  author: HZB
  source: "Multivariable Feedback Control: Analysis and Design, 2nd Edition (Skogestad & Postlethwaite, 2005)"
  version: "1.0"
---

# Multivariable Feedback Control Skill

Expert knowledge from Skogestad & Postlethwaite's "Multivariable Feedback Control: Analysis and Design" (2nd Edition, Wiley, 2005).

## Core Concepts

### 1. Multivariable Plant Representation

**Transfer Function Matrix G(s)**:
- MIMO system: y = G(s)u + d
- G(s) is p×m (p outputs, m inputs)
- G_ij(s): transfer function from input j to output i

**State-Space Representation**:
```
ẋ = Ax + Bu
y = Cx + Du
```
- G(s) = C(sI - A)^(-1)B + D

### 2. Singular Value Decomposition (SVD)

For any p×m matrix G at frequency ω:
```
G(jω) = U Σ V*
```
- U: p×p unitary (output directions)
- V: m×m unitary (input directions)
- Σ: p×m diagonal with σ_1 ≥ σ_2 ≥ ... ≥ σ_min(p,m) ≥ 0

**Key properties**:
- σ̄(G) = σ_1: maximum singular value (worst-case gain)
- σ̲(G) = σ_min: minimum singular value (best-case gain)
- Condition number: κ(G) = σ̄/σ̲

### 3. Relative Gain Array (RGA)

```
Λ = G ⊗ G^(-T)
```
- ⊗ denotes element-by-element multiplication (Hadamard product)
- RGA number λ_ij: ratio of open-loop to closed-loop gain

**Properties**:
- Row sums and column sums equal 1
- RGA ≈ identity → decentralized control may work
- Large RGA elements → input-output pairing sensitivity
- RGA near 0.5 at crossover → avoid pairing

### 4. Condition Number and Plant Scaling

**Condition number κ(G)**:
- κ = σ̄/σ̲
- Large κ → ill-conditioned, difficult to control
- Goal: scale plant so κ is close to 1

**Scaling approach**:
- Input scaling: D_u (account for input magnitudes)
- Output scaling: D_y (account for output tolerances)
- G_scaled = D_y^(-1) G D_u

### 5. System Zeros

**Transmission zeros**: z where rank(G(z)) < min(p,m)
- Multivariable zeros from det[G(s)] = 0 (square systems)
- Invariant zeros: zeros of the Smith-McMillan form

**RHP zeros impose fundamental limitations**:
- BW ≤ |z_RHP|/2 (approximate)
- Overshoot ≥ |G(0)/G(z_RHP)| for step response

### 6. Fundamental Limitations (SISO Review)

**Bode Integral** (for stable plants):
```
∫₀^∞ ln|S(jω)| dω = π Σ Re(p_k)
```
- Waterbed effect: pushing down sensitivity in one frequency range causes it to rise elsewhere
- RHP poles increase the integral → unavoidable peaks

**Bode Sensitivity Integral**:
- T + S = I (complementary sensitivity + sensitivity)
- |S| small → good tracking, robustness to disturbances
- |T| small → good noise attenuation, robustness to multiplicative uncertainty

### 7. MIMO Performance Specifications

**Sensitivity function**: S = (I + GK)^(-1)
**Complementary sensitivity**: T = I - S = GK(I + GK)^(-1)

**Performance criteria**:
- σ̄(S) ≤ 1/|W_1(jω)| (disturbance rejection)
- σ̄(T) ≤ 1/|W_2(jω)| (noise attenuation, robustness)
- σ̄(KS) ≤ 1/|W_3(jω)| (control effort)

**Mixed sensitivity problem**:
```
min_K ||W_1 S; W_2 T; W_3 KS||∞
```

### 8. H∞ Control

**H∞ norm**:
```
||G||∞ = max_ω σ̄(G(jω))
```

**Standard H∞ problem**:
- Generalized plant P(s) with exogenous inputs w, control inputs u, regulated outputs z, measured outputs y
- Find controller K(s) that stabilizes and minimizes ||T_zw||∞

**H∞ loop shaping** (McFarlane-Glover):
1. Shape open-loop: L_0 = W_2 G W_1
2. Design robust controller for shaped plant
3. Guarantees: robust stability and specified loop shape

### 9. Structured Singular Value (μ-analysis)

**Definition**:
```
μ_Δ(M) = 1 / min{σ̄(Δ) : det(I - MΔ) = 0}
```
- Δ: structured uncertainty block diagonal
- μ < 1 ⟺ robust stability guaranteed

**μ-analysis framework**:
- LFT (Linear Fractional Transformation): M-Δ structure
- Real parametric uncertainty: Δ contains real scalars
- Complex uncertainty: Δ contains complex blocks
- Mixed real/complex: both types simultaneously

**Robust performance**: μ(M) < 1 for augmented M with performance block

### 10. Controller Design Methods

**LQR/LQG**:
- LQR: min J = ∫(x'Qx + u'Ru)dt
- K = -R^(-1)B'P (where P solves Riccati equation)
- LQG = LQR + Kalman filter

**H∞ design via DGKF**:
- State-feedback: K = -R^(-1)(B'X + F_12' C_1)
- Output-feedback: full information → observer-based

**Loop transfer recovery (LTR)**:
- Design state-feedback Kx first
- Add observer with LTR to recover robustness at plant input

### 11. Uncertainty Modeling

**Additive uncertainty**: G_p = G + W_a Δ_a, σ̄(Δ_a) ≤ 1
**Multiplicative uncertainty**: G_p = (I + W_m Δ_m)G, σ̄(Δ_m) ≤ 1
**Inverse multiplicative**: G_p = G(I + W_i Δ_i)^(-1)

**Uncertainty weights**:
- |W_m(jω)| ≥ |(G_p - G)/G| for all possible plants G_p
- Typically: |W_m| small at low freq, ~1 at high freq

### 12. Robust Stability and Performance

**Robust stability (RS)**: System stable for all ||Δ||∞ ≤ 1
- Necessary and sufficient: μ_Δ(M_11) < 1 ∀ω

**Nominal performance (NP)**: Performance with nominal plant
- σ̄(S) < 1/|W_1| ∀ω

**Robust performance (RP)**: Performance for all ||Δ||∞ ≤ 1
- μ_Δ̃(M) < 1 where Δ̃ includes performance block

### 13. MIMO Frequency Response Analysis

**Singular value plots**:
- σ̄(G) and σ̲(G) vs frequency
- Gives worst-case and best-case gains

**Characteristic gain loci**:
- Eigenvalues of G(jω)
- Generalized Nyquist theorem

**Gershgorin bands**:
- Approximate eigenvalue locations from diagonal dominance
- Conservative but simple

## Design Workflow

### Step 1: Plant Analysis
1. Plot singular values σ̄(G) and σ̲(G)
2. Compute condition number κ(G)
3. Compute RGA at crossover frequency
4. Identify RHP zeros and their limitations
5. Scale plant appropriately

### Step 2: Performance Requirements
1. Define bandwidth ω_B for each output
2. Specify disturbance rejection requirements
3. Determine noise attenuation needs
4. Set control effort limits

### Step 3: Controller Architecture
- Decentralized (pair RGA with κ)
- Full MIMO (H∞, μ-synthesis)
- Sequential loop closing

### Step 4: Robustness Analysis
1. Define uncertainty model (W_m, W_a)
2. Compute μ for robust stability
3. Check robust performance μ < 1

## MATLAB/Simulation Commands

```matlab
% SVD analysis
[U,S,V] = svd(G);
sigma(G);  % Singular value plot

% RGA computation
RGA = G .* inv(G).';
cond(G)  % Condition number

% H∞ design (Robust Control Toolbox)
[K,CL,GAM] = hinfsyn(P,nmeas,ncont);
W1 = ...; W2 = ...; W3 = ...;
[K,CL] = mixsyn(G,W1,W2,W3);

% μ-analysis (Robust Control Toolbox)
bnd = mussv(M,blk);
```

## Quick Reference

| Concept | Formula | Meaning |
|---------|---------|---------|
| SVD | G = UΣV* | Gain in each direction |
| RGA | Λ = G ⊗ G^(-T) | Input-output pairing |
| Condition # | κ = σ̄/σ̲ | Ill-conditioning measure |
| Sensitivity | S = (I+GK)^(-1) | Disturbance amplification |
| Comp. Sens. | T = I-S | Noise amplification |
| H∞ norm | max_ω σ̄(G) | Worst-case gain |
| μ | 1/min{σ̄(Δ):det(I-MΔ)=0} | Robust stability margin |
