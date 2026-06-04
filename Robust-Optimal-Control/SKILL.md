---
name: robust-optimal-control
description: "Zhou, Doyle, Glover《Robust and Optimal Control》核心知识。涵盖 H∞ 控制、μ 综合、结构奇异值、模型降阶、鲁棒性能。当设计鲁棒控制器或进行不确定性分析时使用。"
metadata:
  author: HZB
  source: "Robust and Optimal Control (K. Zhou, J.C. Doyle, K. Glover, Prentice Hall, 1996)"
  version: "2.0"
---

# Zhou 鲁棒与最优控制 Skill

## 1. 不确定性建模

### 1.1 不确定性类型
- **参数不确定性**：模型参数在已知范围内变化
- **动态不确定性**：未建模动态
- **加性不确定性**：Gp = G + Δa, ‖Δa‖∞ ≤ wa
- **乘性不确定性**：Gp = (I+Δm)G, ‖Δm‖∞ ≤ wm

### 1.2 不确定性权函数
|wi(jω)| ≥ |Δi(jω)| 对所有可能的 Δi
- 低频小、高频大（典型形状）

## 2. H∞ 控制

### 2.1 H∞ 范数
‖G‖∞ = sup_ω σ̄(G(jω))
- 物理意义：最坏情况下的能量增益

### 2.2 标准问题框架
```
        ┌─────┐
   w ──→│  P  ├──→ z
        │     │
   u ──→│     ├──→ y
        └─────┘
```
- P：广义被控对象
- w：外部输入（扰动、噪声）
- z：被调输出（跟踪误差、控制量）
- u：控制输入
- y：测量输出

### 2.3 混合灵敏度问题
```
min_K ‖W₁S; W₂T; W₃KS‖∞
```
- S = (I+GK)⁻¹：灵敏度函数
- T = I-S：互补灵敏度函数
- W₁：性能权函数（低频大）
- W₂：鲁棒性权函数（高频大）
- W₃：控制量权函数

### 2.4 DGKF 解法
条件：
1. (A,B₂,C₂) 可稳可检
2. D₁₂, D₂₁ 满秩
3. γ > γopt

两个 Riccati 方程：
```
X∞: A'X + XA + C₁'C₁ - XB₂R⁻¹B₂'X + γ⁻²XBB'X = 0
Y∞: AY + YA' + B₁B₁' - YC₂'R⁻²C₂Y + γ⁻²YC'C Y = 0
```
稳定性条件：ρ(X∞Y∞) < γ²

## 3. 结构奇异值 μ 分析

### 3.1 μ 定义
μ_Δ(M) = 1/min{σ̄(Δ): det(I-MΔ)=0}
- Δ：结构化不确定性块
- μ < 1 ⟺ 鲁棒稳定

### 3.2 μ 上下界
- 下界：μ ≥ max_ω ρ(M)（谱半径）
- 上界：μ ≤ min_D σ̄(DMD⁻¹)
- MATLAB: `mussv(M, block)`

### 3.3 μ 综合
```
min_K max_ω μ_Δ(P(K)(jω))
```
- D-K 迭代：交替优化 K 和 D
- MATLAB: `dksyn(P, nmeas, ncont)`

### 3.4 鲁棒性能
μ(M) < 1 对增广不确定性块 Δ̃ = diag(Δ, Δp)
- Δp：性能虚拟块

## 4. LQR/LQG

### 4.1 LQR
```
min J = ∫(x'Qx + u'Ru)dt
u = -Kx, K = R⁻¹B'P
```
P 满足 ARE：A'P + PA - PBR⁻¹B'P + Q = 0

### 4.2 LQG
- Kalman 滤波器：x̂̇ = Ax̂ + Bu + L(y-Cx̂)
- 分离定理：LQR + KF 独立设计

### 4.3 LQG/LTR
1. 设计 LQR Kx
2. 设计 KF L 使恢复输入端裕度
3. 恢复条件：σ̄(GK(jω)) → σ̄(C(jωI-A)⁻¹B)

## 5. 模型降阶

### 5.1 均衡实现
- Hankel 奇异值：σᵢ = √(λᵢ(WcWo))
- Wc：可控性格拉姆矩阵
- Wo：可观性格拉姆矩阵

### 5.2 截断方法
- 平衡截断：保留大 σᵢ 的状态
- Hankel 范数逼近：‖G-Gr‖∞ ≈ 2Σᵢ₌ᵣ₊₁ⁿ σᵢ

### 5.3 降阶误差界
‖G-Gr‖∞ ≤ 2Σᵢ₌ᵣ₊₁ⁿ σᵢ

## 6. MATLAB 命令

```matlab
% H∞ 设计
[K, CL, gamma] = hinfsyn(P, nmeas, ncont);
[K, CL] = mixsyn(G, W1, W2, W3);

% μ 分析
bnd = mussv(M, blk);
[mu, D] = mussv(M, blk);

% μ 综合
[K, CL, bnd] = dksyn(P, nmeas, ncont);

% LQR
[K, S, e] = lqr(A, B, Q, R);

% 模型降阶
[Gred, info] = balred(G, order);
```

## 7. 关键公式

| 公式 | 表达式 | 用途 |
|------|--------|------|
| H∞ 范数 | sup_ω σ̄(G(jω)) | 最坏增益 |
| 混合灵敏度 | min‖W₁S;W₂T;W₃KS‖∞ | 鲁棒设计 |
| μ 定义 | 1/min{σ̄(Δ):det(I-MΔ)=0} | 鲁棒稳定 |
| ARE | A'P+PA-PBR⁻¹B'P+Q=0 | LQR |
| Kalman | L=PC'(CPC'+Rn)⁻¹ | 状态估计 |
| 降阶误差 | ≤ 2Σσᵢ | 模型降阶 |
