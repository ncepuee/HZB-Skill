---
name: dynamic-mode-decomposition
description: "Dynamic Mode Decomposition (DMD) data-driven modeling expert based on Kutz, Brunton et al. Covers DMD algorithm, exact DMD, optimized DMD, extended DMD, kernel DMD, online DMD, compressed DMD, and connections to Koopman operator theory. Use when working with spatiotemporal data analysis, fluid dynamics, power system dynamics, or data-driven dynamic modeling."
metadata:
  author: HZB
  source: "Dynamic Mode Decomposition: Data-Driven Modeling of Complex Systems (Kutz, Brunton, Brunton, Proctor, SIAM 2016)"
  version: "1.0"
---

# Dynamic Mode Decomposition (DMD) Skill

Expert knowledge from Kutz, Brunton et al.'s "Dynamic Mode Decomposition: Data-Driven Modeling of Complex Systems" (SIAM, 2016).

## 1. Overview

DMD is a data-driven algorithm that extracts spatiotemporal coherent structures from high-dimensional data, combining the spatial decomposition of PCA/POD with the temporal dynamics of Fourier analysis.

**Key idea**: Given time-series snapshots X₁, X₂, ..., Xₘ, DMD finds the best-fit linear operator A such that:
```
X_{k+1} = A * X_k
```
and computes its eigenvalues and eigenvectors (DMD modes).

## 2. Standard DMD Algorithm

### 2.1 Data Organization

**Snapshot matrices**:
```
X = [x₁ | x₂ | ... | x_{m-1}]   (n × (m-1))
X'= [x₂ | x₃ | ... | x_m  ]   (n × (m-1))
```
- n: spatial dimension (number of sensors/grid points)
- m: number of snapshots
- x_k ∈ ℝⁿ: k-th snapshot vector

### 2.2 SVD-based DMD (Exact DMD)

**Step 1**: Compute SVD of X
```
X ≈ U_r Σ_r V_r*    (rank-r truncated SVD)
```

**Step 2**: Project A onto POD subspace
```
Ã = U_r* X' V_r Σ_r⁻¹   (r × r reduced operator)
```

**Step 3**: Eigendecomposition of Ã
```
Ã w_i = λ_i w_i
```

**Step 4**: DMD modes (eigenvectors of A)
```
φ_i = (1/λ_i) X' V_r Σ_r⁻¹ w_i
```

**DMD eigenvalues**: λ_i (discrete-time)
**Continuous-time eigenvalues**: ω_i = ln(λ_i) / Δt

### 2.3 DMD Mode Properties

Each DMD mode has:
- **Spatial structure**: φ_i ∈ ℂⁿ (mode shape)
- **Temporal dynamics**: λ_iᵏ (exponential growth/decay + oscillation)
- **Frequency**: f_i = Im(ω_i) / (2π)
- **Growth rate**: σ_i = Re(ω_i)
- **Amplitude**: b_i (projection of initial condition)

**DMD reconstruction**:
```
x(t) ≈ Σᵢ φ_i * b_i * exp(ω_i * t)
```

## 3. DMD Variants

### 3.1 Exact DMD (Tu et al., 2014)

**Definition**: φ_i = (1/λ_i) X' V_r Σ_r⁻¹ w_i
- Mathematically rigorous definition
- Modes are eigenvectors of A = X' X⁺ (where X⁺ is pseudoinverse)

### 3.2 Optimized DMD (Askham & Kutz, 2018)

**Objective**: Minimize reconstruction error
```
min_{Φ,Ω,b} ||X' - Φ diag(b) e^{Ωt}||_F
```

**Advantages**:
- Handles irregularly sampled data
- More robust to noise
- Better amplitude estimation

### 3.3 Extended DMD (EDMD)

**Idea**: Lift measurements through dictionary of nonlinear observables
```
g(x) = [g₁(x), g₂(x), ..., g_N(x)]ᵀ
```

**EDMD operator**:
```
K = G' X' (X' X)⁻¹ X' G    (in lifted space)
```

**Connection to Koopman**: EDMD approximates the Koopman operator with polynomial/rbf dictionaries.

### 3.4 Kernel DMD

**Trick**: Use kernel trick to avoid explicit lifting
```
K(x_i, x_j) = ⟨g(x_i), g(x_j)⟩
```

**Kernel DMD** works in n-dimensional feature space without computing it explicitly.

### 3.5 Online DMD (Hemati et al., 2017)

**Recursive update** for streaming data:
```
X_{k+1} = [X_k, x_{new}]     (append new snapshot)
```

**Incremental SVD** or **rank-1 updates** to avoid recomputing full SVD.

### 3.6 Compressed DMD

**Idea**: Apply random projection before DMD
```
C X ≈ C U_r Σ_r V_r*    (compressed measurements)
```
- Reduces computational cost for very high-dimensional data
- Preserves dominant DMD modes with high probability

### 3.7 Multi-Resolution DMD (MR-DMD)

**Strategy**: Separate low-frequency content from transient dynamics
1. Apply DMD to full data
2. Remove modes that are present throughout
3. Apply DMD to remaining residual in shorter windows
4. Repeat recursively

**Captures**: Multi-scale dynamics, intermittent features

### 3.8 Physics-Informed DMD (piDMD)

**Constrain DMD operator** to respect physics:
- A is symmetric (Hamiltonian systems)
- A is unitary (conservative systems)
- A is normal (linearizable systems)

**Method**: Solve constrained optimization in SVD basis.

## 4. Koopman Operator Theory

### 4.1 Koopman Operator

**Definition**: For dynamical system x_{k+1} = F(x_k), the Koopman operator K acts on observables g:
```
K g = g ∘ F
```
- Infinite-dimensional linear operator
- Acts on function space, not state space

### 4.2 Koopman Eigenfunctions

```
K φ_j = λ_j φ_j
```
- φ_j: Koopman eigenfunctions
- λ_j: Koopman eigenvalues
- Observable can be expanded: g(x) = Σⱼ φ_j(x) v_j

### 4.3 DMD as Koopman Approximation

**DMD** = linear Koopman approximation with g(x) = x (full-state observable)

**EDMD** = Koopman approximation with richer dictionary g(x)

**Connection**:
- DMD modes ≈ projection of Koopman eigenfunctions onto data
- DMD eigenvalues ≈ Koopman eigenvalues (for observable subspace)

## 5. DMD for Power Systems

### 5.1 Power System Modal Analysis

**Application**: Extract oscillation modes from PMU data
```
x(t) = [δ₁(t), δ₂(t), ..., δ_n(t), ω₁(t), ..., ω_n(t)]ᵀ
```
- δ: rotor angles
- ω: frequencies

**DMD output**:
- Inter-area modes (0.1-1 Hz)
- Local modes (1-3 Hz)
- Control modes

### 5.2 Transient Stability Assessment

**DMD-based predictor**:
```
x(t + Δt) ≈ Σ φ_i b_i λ_i^(t/Δt)
```
- Predict future trajectory from limited measurements
- Detect instability if |λ_i| > 1

### 5.3 Converter System Dynamics

**Application to inverter-based systems**:
- Extract converter control modes
- Identify poorly damped oscillations
- Real-time stability monitoring

## 6. Truncation and Model Selection

### 6.1 Rank Selection

**Singular value decay**: Plot σ_i vs i
- Choose r such that energy captured ≳ 99%
```
Σ_{i=1}^{r} σ_i² / Σ_{i=1}^{n} σ_i² ≥ 0.99
```

### 6.2 DMD Mode Selection

**Criteria for important modes**:
1. **Amplitude**: |b_i| (modes contributing most to dynamics)
2. **Damping**: |λ_i| close to 1 (persistent modes)
3. **Frequency**: Match physical expectations

**Sparsity-promoting DMD**: Select fewest modes that capture dynamics
```
min ||b||₁  s.t.  ||X' - Φ diag(b) Λ||_F ≤ ε
```

## 7. Noise and Data Quality

### 7.1 Noise Effects

- Noise biases DMD eigenvalues toward unit circle
- High noise → spurious modes
- **Ensemble DMD**: Average DMD over multiple realizations

### 7.2 Data Preprocessing

1. **Centering**: Subtract temporal mean
2. **Windowing**: Apply Hanning window to reduce spectral leakage
3. **Filtering**: Low-pass filter for high-frequency noise
4. **Downsampling**: Reduce data dimension if needed

### 7.3 Delay Embedding DMD

For systems with hidden states:
```
x_delay = [x(t), x(t-τ), x(t-2τ), ..., x(t-(d-1)τ)]ᵀ
```
- Takens' embedding theorem
- Recovers hidden dynamics from time-delay coordinates

## 8. Computational Aspects

### 8.1 Complexity

| Method | Complexity | Best For |
|--------|-----------|----------|
| Standard DMD | O(nm²) | Small n, many snapshots |
| SVD-based DMD | O(nmr) | High-dimensional data |
| Streaming DMD | O(nr²) per update | Real-time applications |
| Compressed DMD | O(sm²) | Very large n (s << n) |

### 8.2 MATLAB Implementation

```matlab
% Standard DMD
X = data(:, 1:end-1);
X2 = data(:, 2:end);
r = 10; % truncation rank
[U, S, V] = svd(X, 'econ');
U_r = U(:, 1:r); S_r = S(1:r,1:r); V_r = V(:, 1:r);
A_tilde = U_r' * X2 * V_r / S_r;
[W, D] = eig(A_tilde);
Phi = X2 * V_r / S_r * W; % DMD modes
lambda = diag(D); % DMD eigenvalues
omega = log(lambda) / dt; % continuous-time
```

### 8.3 Python Implementation (PyDMD)

```python
from pydmd import DMD
dmd = DMD(svd_rank=10)
dmd.fit(data.T)
# DMD modes
print(dmd.modes.shape)  # (n, r)
# DMD eigenvalues
print(dmd.eigs)
# Reconstruction
reconstructed = dmd.reconstructed_data
```

## 9. Connections to Other Methods

| Method | Relationship to DMD |
|--------|-------------------|
| **PCA/POD** | DMD = POD + temporal dynamics |
| **Fourier** | DMD with uniformly sampled periodic data ≈ DFT |
| **SSA** | Singular Spectrum Analysis ≈ delay-embedded DMD |
| **ERA** | Eigensystem Realization ≈ impulse-response DMD |
| **NARMA** | Nonlinear ARMA ≈ EDMD with polynomial basis |
| **Reservoir Computing** | Reservoir ≈ random EDMD |

## 10. Applications

| Domain | Application | DMD Advantage |
|--------|------------|---------------|
| Fluid dynamics | Turbulence coherent structures | Extract spatial modes + frequencies |
| Power systems | Oscillation mode extraction | Real-time modal analysis |
| Neuroscience | Brain dynamics from fMRI | High-dimensional time series |
| Video processing | Background/foreground separation | Dynamic scene decomposition |
| Climate | ENSO, climate modes | Spatiotemporal pattern extraction |
| Robotics | System identification | Data-driven linearized models |

## 11. Key Formulas

| Formula | Expression | Meaning |
|---------|-----------|---------|
| DMD operator | A = X' X⁺ | Best-fit linear map |
| Exact DMD mode | φ_i = (1/λ_i)X'V_rΣ_r⁻¹w_i | Spatial structure |
| DMD eigenvalue | λ_i | Discrete-time dynamics |
| Continuous eigenvalue | ω_i = ln(λ_i)/Δt | Growth + frequency |
| Reconstruction | x(t) = Σφ_i b_i e^{ω_i t} | Full spatiotemporal |
| Koopman | K g = g∘F | Infinite-dim linear operator |
| EDMD | K = G'X'(X'X)⁻¹X'G | Finite Koopman approx |
