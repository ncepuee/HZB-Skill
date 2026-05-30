---
name: power-system-dynamics-control
description: "Power System Dynamics and Control by Göran Andersson (ETH Zürich). Covers frequency dynamics, primary/secondary/tertiary frequency control, AGC, voltage control, excitation systems, FACTS devices, and power system stability. Use when working with power system frequency regulation, generator control, voltage stability, or power system dynamics."
metadata:
  author: HZB
  source: "Dynamics and Control of Electric Power Systems (Göran Andersson, ETH Zürich, 2012)"
  version: "1.0"
---

# Power System Dynamics and Control Skill

Expert knowledge from Göran Andersson's "Dynamics and Control of Electric Power Systems" (ETH Zürich Lecture Notes, 2012).

## 1. Introduction to Power System Control

### 1.1 Control Theory Basics

**Simple Control Loop**:
```
Reference → [Controller] → [Plant] → Output
                ↑                         |
                └─── [Sensor] ←───────────┘
```

**State Space Formulation**:
```
ẋ = f(x, u, p)
y = g(x, u, p)
```
- x: state vector
- u: control inputs
- p: parameters
- y: measured outputs

### 1.2 Power System Control Hierarchy

| Level | Time Scale | Function | Control Action |
|-------|-----------|----------|----------------|
| Primary | 1-10s | Frequency response | Governor droop control |
| Secondary | 10s-min | AGC / LFC | Load frequency control |
| Tertiary | min-hr | Economic dispatch | Optimal power flow |

## 2. Frequency Dynamics

### 2.1 Generator Swing Equation

**Single machine**:
```
2H * dω/dt = P_m - P_e - D(ω - ω_0)
```
- H: inertia constant (s)
- P_m: mechanical power
- P_e: electrical power
- D: damping coefficient

**Per-unit form**:
```
2H * dΔω/dt = ΔP_m - ΔP_e - D*Δω
```

### 2.2 System Frequency Response Model

**Aggregate generator model**:
```
Δω(s) = (1/(2Hs + D)) * (ΔP_m(s) - ΔP_L(s))
```

**Frequency nadir** (worst-case):
```
Δω_nadir ≈ -ΔP_L / (2H * ω_0)  (for large disturbances)
```

### 2.3 Load Frequency Dependency

**Load model**:
```
P_L = P_0 * (ω/ω_0)^α
```
- α ≈ 1-2 for industrial loads
- D = α * P_0/ω_0: load damping coefficient

## 3. Primary Frequency Control

### 3.1 Governor Droop Control

**Speed droop characteristic**:
```
ΔP_m = -1/R * Δω
```
- R: droop coefficient (typically 4-5%)
- Larger R → less aggressive control
- Smaller R → more aggressive, but risk instability

**Steady-state frequency deviation**:
```
Δω_ss = -ΔP_L / (D + 1/R_1 + 1/R_2 + ... + 1/R_n)
```

### 3.2 One-Area System Model

**Block diagram**:
```
ΔP_L → [1/(2Hs+D)] → Δω
           ↑
    [-1/R] ← Δω ← [Governor] → ΔP_m
```

**Transfer function**:
```
Δω(s)/ΔP_L(s) = -(1/(2Hs + D)) / (1 + 1/(R*(2Hs + D)))
```

### 3.3 Two-Area System

**Tie-line power flow**:
```
ΔP_tie = T_12 * (Δδ_1 - Δδ_2)
```
- T_12: synchronizing torque coefficient

**Area Control Error (ACE)**:
```
ACE_i = ΔP_tie,i + β_i * Δω_i
```
- β_i: frequency bias coefficient (typically β_i = D_i + 1/R_i)

### 3.4 Turbine Models

**Steam turbine (single stage)**:
```
G_t(s) = 1/(1 + s*T_t)
```
- T_t: turbine time constant (0.2-0.5s)

**Steam turbine (reheat)**:
```
G_t(s) = (1 + s*F_HP*T_R) / ((1 + s*T_t)(1 + s*T_R))
```
- F_HP: HP turbine power fraction
- T_R: reheat time constant

**Hydro turbine**:
```
G_t(s) = (1 - s*T_w) / (1 + s*T_w/2)
```
- T_w: water starting time (1-3s)
- Non-minimum phase behavior!

## 4. Secondary Frequency Control (AGC)

### 4.1 AGC Structure

**PI controller for AGC**:
```
ΔP_ref = -K_p * ACE - K_i * ∫ACE dt
```

**ACE formulation**:
```
ACE = ΔP_tie + β * Δω
```

### 4.2 One-Area AGC

**Closed-loop response**:
- Eliminates steady-state frequency error
- Restores Δω → 0

**Control parameters**:
- K_p: proportional gain (typical: 0.1-0.5)
- K_i: integral gain (typical: 0.01-0.1 s⁻¹)

### 4.3 Two-Area AGC

**Goals**:
1. Δω → 0 (frequency restoration)
2. ΔP_tie → 0 (tie-line scheduled power)

**Tuning considerations**:
- Too aggressive: oscillations between areas
- Too slow: large frequency deviations

### 4.4 Participation Factors

**Economic dispatch in AGC**:
```
ΔP_ref,i = α_i * ΔP_total
```
- Σα_i = 1
- Based on generation cost, participation factors

## 5. Voltage Control

### 5.1 Reactive Power - Voltage Relationship

**Simplified network**:
```
Q ≈ (V_s - V_r) * V_r / X
```
- Reactive power primarily affects voltage magnitude
- Active power primarily affects voltage angle

### 5.2 Generator Excitation Control

**Automatic Voltage Regulator (AVR)**:
```
ΔE_fd = K_A * (V_ref - V_t)
```
- K_A: AVR gain (typical: 200-400)
- V_t: terminal voltage

**Excitation system model (IEEE Type 1)**:
```
G_ex(s) = K_A / ((1 + s*T_A)(1 + s*T_E))
```

### 5.3 Power System Stabilizer (PSS)

**Purpose**: Damp low-frequency oscillations (0.1-2 Hz)

**PSS transfer function**:
```
G_PSS(s) = K_s * (s*T_w)/(1 + s*T_w) * (1 + s*T_1)/(1 + s*T_2)
```
- T_w: washout time constant (5-10s)
- T_1, T_2: lead-lag compensation

**Input signals**: Δω, ΔP_e, Δf

### 5.4 Generator Capability Curve

**Limits**:
- Over-excitation limit (field current)
- Under-excitation limit (steady-state stability)
- Armature current limit

## 6. FACTS Devices

### 6.1 Static VAR Compensator (SVC)

**Control law**:
```
Q_SVC = (V_ref - V_t) * K_SVC
```
- Provides fast reactive power support
- Limits: inductive and capacitive

### 6.2 Thyristor-Controlled Series Capacitor (TCSC)

**Effective reactance**:
```
X_eff = X_L * (1 - σ/π - sin(2σ)/(2π))
```
- σ: firing angle
- Controls power flow and improves stability

### 6.3 Static Synchronous Compensator (STATCOM)

**Current injection**:
```
I_STATCOM = (V_ref - V_t) * Y_STATCOM
```
- Voltage source converter based
- Faster response than SVC

## 7. Power System Stability

### 7.1 Small-Signal Stability

**Eigenvalue analysis**:
- Eigenvalues of system state matrix A
- Damping ratio: ζ = -σ/|λ|
- Critical modes: low frequency (0.1-2 Hz), poorly damped

**Participation factors**:
```
p_ki = |v_ki| * |u_ki|
```
- Identifies which states participate in which modes

### 7.2 Transient Stability

**Equal area criterion** (single machine infinite bus):
```
A_accel = ∫(P_m - P_e) dδ  (during fault)
A_decel = ∫(P_e - P_m) dδ  (after fault clearing)
```
- Stable if A_decel ≥ A_accel

**Critical clearing time**:
- Maximum time to clear fault and maintain synchronism

### 7.3 Voltage Stability

**P-V curve (nose curve)**:
- Maximum power transfer point = voltage collapse point
- Voltage stability margin: distance to nose point

**Q-V sensitivity**:
```
dQ/dV < 0: voltage stable
dQ/dV > 0: voltage unstable
```

## 8. Key Formulas

| Formula | Expression | Application |
|---------|-----------|-------------|
| Swing eq | 2H·dω/dt = Pm-Pe-DΔω | Frequency dynamics |
| Droop | ΔPm = -Δω/R | Primary control |
| ACE | ΔPtie + β·Δω | AGC signal |
| Tie-line | ΔPtie = T12(Δδ1-Δδ2) | Area interconnection |
| Q-V | Q ≈ (Vs-Vr)Vr/X | Voltage-reactive power |
| AVR | ΔEfd = KA(Vref-Vt) | Excitation control |
| PSS | Ks·sTw/(1+sTw)·lead-lag | Oscillation damping |

## 9. MATLAB/Simulation

```matlab
% Frequency response
sys_f = tf(1, [2*H D]);
step(sys_f);

% Governor droop
R = 0.05;  % 5% droop
G_gov = tf(-1/R, 1);

% Steam turbine
T_t = 0.3;
G_turb = tf(1, [T_t 1]);

% AVR
K_A = 200; T_A = 0.05;
G_avr = tf(K_A, [T_A 1]);

% PSS design
T_w = 10; T1 = 0.1; T2 = 0.02;
G_pss = tf([T_w 0], [T_w 1]) * tf([T1 1], [T2 1]);
```

## 10. Typical Parameter Ranges

| Parameter | Typical Range | Unit |
|-----------|--------------|------|
| Inertia H | 2-10 | s |
| Droop R | 3-5 | % |
| Frequency bias β | 0.5-1.0 | pu/Hz |
| Turbine T_t | 0.2-0.5 | s |
| Reheat T_R | 5-10 | s |
| Water time T_w | 1-3 | s |
| AVR gain K_A | 200-400 | - |
| PSS gain K_s | 1-20 | - |
