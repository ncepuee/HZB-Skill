---
name: lewis-optimal-control
description: "F.L. Lewis《Optimal Control》(3rd Ed.) 核心知识。涵盖 LQR/LQG、动态规划、Pontryagin 原理、H∞ 控制、自适应控制。当设计最优控制器或求解最优控制问题时使用。"
metadata:
  author: HZB
  source: "Optimal Control, 3rd Edition (F.L. Lewis, V.L. Syrmos, Wiley, 2012)"
  version: "2.0"
---

# Lewis 最优控制 (第3版) Skill

## 1. 最优控制问题

### 1.1 基本问题
```
min J = φ(x(tf),tf) + ∫₀ᵗᶠ L(x,u,t)dt
s.t.  ẋ = f(x,u,t), x(0) = x₀
```
- φ: 终端代价
- L: 运行代价

### 1.2 约束类型
- 控制约束：u ∈ U
- 状态约束：x ∈ X
- 终端约束：ψ(x(tf),tf) = 0

## 2. 变分法与 Pontryagin 原理

### 2.1 Hamilton 函数
H(x,u,λ,t) = L(x,u,t) + λᵀf(x,u,t)

### 2.2 最优性条件（必要条件）
```
ẋ = ∂H/∂λ = f(x,u,t)          （状态方程）
λ̇ = -∂H/∂x = -Lₓ - λᵀfₓ       （协态方程）
∂H/∂u = 0                      （最小值条件）
```

### 2.3 横截条件
- 固定终端：x(tf) = xf（无额外条件）
- 自由终端：λ(tf) = ∂φ/∂x|ₓ(tf)
- 自由终端时间：H(tf) = -∂φ/∂t|ₓ(tf)

### 2.4 Pontryagin 最小值原理
H(x*,u*,λ*,t) ≤ H(x*,u,λ*,t), ∀u ∈ U
- 允许控制约束为不等式

## 3. LQR（线性二次调节器）

### 3.1 连续时间 LQR
```
min J = ∫₀^∞ (x'Qx + u'Ru)dt
s.t.  ẋ = Ax + Bu
```
最优控制：u = -Kx, K = R⁻¹B'P
P 满足 ARE：A'P + PA - PBR⁻¹B'P + Q = 0

### 3.2 LQR 性质
- 保证稳定裕度：GM ≥ 6dB, PM ≥ 60°
- 对参数变化鲁棒
- 最优闭环极点在 LQR 稳定区域边界

### 3.3 加权矩阵选择
- Q 大 → 状态调节快，控制量大
- R 大 → 控制量小，响应慢
- Bryson 法则：Q = diag(1/xᵢ,max²), R = diag(1/uⱼ,max²)

### 3.4 离散时间 LQR
```
min J = Σ(x'Qx + u'Ru)
s.t.  x(k+1) = Ax(k) + Bu(k)
```
u(k) = -Kx(k), K = (R+B'PB)⁻¹B'PA
DARE：P = Q + A'PA - A'PB(R+B'PB)⁻¹B'PA

## 4. LQG（线性二次高斯）

### 4.1 随机系统
```
ẋ = Ax + Bu + w,  w ~ N(0,Qn)
y = Cx + v,        v ~ N(0,Rn)
```

### 4.2 Kalman 滤波器
预测：x̂̇ = Ax̂ + Bu
更新：Kf = PC'(CPC'+Rn)⁻¹
协方差：APA' + Qn - APC'(CPC'+Rn)⁻¹CPA' = P

### 4.3 分离定理
LQG = LQR + Kalman 滤波器，独立设计

## 5. 动态规划

### 5.1 Bellman 方程
V(x,t) = min_u {L(x,u,t) + V(x+ẋΔt, t+Δt)}

### 5.2 最优性原理
最优策略的子策略也是最优的

### 5.3 LQR 的 Bellman 解
V(x) = x'Px
P 满足 Riccati 方程

## 6. H∞ 控制

### 6.1 动机
- 处理模型不确定性
- 最小化最坏情况性能

### 6.2 标准问题
min_K ‖Tzw‖∞
- Tzw：从外部扰动 w 到被调输出 z 的闭环传递

### 6.3 状态空间解
两个 Riccati 方程：
```
X: A'X + XA + C₁'C₁ - XB₂R⁻¹B₂'X + γ⁻²XBB'X = 0
Y: AY + YA' + B₁B₁' - YC₂'R⁻²C₂Y + γ⁻²YC'C Y = 0
```

## 7. 自适应控制

### 7.1 模型参考自适应控制 (MRAC)
- 参考模型：ẋm = Am·xm + Bm·r
- 控制律：u = θ'φ(x,r)
- 自适应律：θ̇ = -Γ·e·φ(x,r)

### 7.2 自校正控制
- 在线参数辨识 + 最优控制设计
- 辨识方法：RLS, 梯度法

### 7.3 Lyapunov 自适应设计
选择 Lyapunov 函数 V = e'Pe + θ̃'Γ⁻¹θ̃
推导自适应律使 V̇ ≤ 0

## 8. MATLAB 命令

```matlab
% LQR
[K, S, e] = lqr(A, B, Q, R);
[K, S, e] = dlqr(A, B, Q, R);  % 离散

% Kalman
[Kf, P, e] = kalman(sys, Qn, Rn);

% LQG
LQG = lqg(sys, Q_weight, R_weight);

% H∞
[K, CL, gamma] = hinfsyn(P, nmeas, ncont);

% Riccati 方程
[P, e, info] = care(A, B, Q, R);  % 连续
[P, e, info] = dare(A, B, Q, R);  % 离散
```

## 9. 关键公式

| 公式 | 表达式 | 用途 |
|------|--------|------|
| Hamilton | H = L + λ'f | 最优性 |
| Pontryagin | H(x*,u*) ≤ H(x*,u) | 最小值原理 |
| LQR | u = -Kx, K = R⁻¹B'P | 最优调节 |
| ARE | A'P+PA-PBR⁻¹B'P+Q=0 | LQR 解 |
| Kalman 增益 | Kf = PC'(CPC'+Rn)⁻¹ | 状态估计 |
| Bellman | V = min{L+V∘f} | 动态规划 |
| H∞ | min‖Tzw‖∞ | 鲁棒最优 |
