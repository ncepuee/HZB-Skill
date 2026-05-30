---
name: control-beauty-vol2
description: "The Beauty of Control Vol.2: Optimal Control, MPC, and Kalman Filter. Covers optimization fundamentals, LQR, LQG, dynamic programming, Bellman equation, Model Predictive Control (MPC), Kalman filter, and stochastic estimation. Use when working with optimal control design, state estimation, predictive control, or stochastic systems."
metadata:
  author: HZB
  source: "控制之美 第2卷：最优化控制MPC与卡尔曼滤波器 (吴昊天)"
  version: "1.0"
---

# 控制之美 第2卷 Skill

Expert knowledge from 吴昊天's "控制之美 第2卷：最优化控制 MPC 与卡尔曼滤波器".

## 1. 最优化基础

### 1.1 无约束优化

**一阶必要条件**：∇f(x*) = 0
**二阶充分条件**：∇²f(x*) 正定（极小值）

**梯度下降法**：
```
x_(k+1) = x_k - α_k * ∇f(x_k)
```
- α_k: 步长（学习率）
- 收敛条件：0 < α < 2/L（L 是 Lipschitz 常数）

**Newton 法**：
```
x_(k+1) = x_k - [∇²f(x_k)]^(-1) * ∇f(x_k)
```
- 二次收敛，但需要 Hessian 矩阵

### 1.2 有约束优化

**等式约束**：min f(x) s.t. h(x) = 0

**Lagrange 乘子法**：
```
L(x, λ) = f(x) + λᵀh(x)
```
- 最优性条件：∇_x L = 0, ∇_λ L = 0

**不等式约束**：min f(x) s.t. g(x) ≤ 0

**KKT 条件**：
1. ∇f + Σμ_i∇g_i = 0 （平稳性）
2. g_i ≤ 0 （原始可行性）
3. μ_i ≥ 0 （对偶可行性）
4. μ_i * g_i = 0 （互补松弛）

### 1.3 二次规划 (QP)

```
min  (1/2)xᵀHx + fᵀx
s.t. Ax ≤ b, Aeq*x = beq
```
- H 正定：严格凸 QP，唯一解
- MATLAB: `quadprog(H, f, A, b, Aeq, beq)`

## 2. 动态规划与 Bellman 方程

### 2.1 离散时间动态系统

```
x_(k+1) = f(x_k, u_k)
```

**最优控制问题**：
```
min J = Σ_{k=0}^{N-1} l(x_k, u_k) + V_f(x_N)
```

### 2.2 Bellman 最优性原理

**Bellman 方程**（逆向递推）：
```
V_k(x) = min_u { l(x, u) + V_{k+1}(f(x, u)) }
```

- V_N(x) = V_f(x) （终端代价）
- 最优策略：u*_k = argmin { l(x, u) + V_{k+1}(f(x, u)) }

### 2.3 线性二次问题 (LQ)

**系统**：x_(k+1) = Ax_k + Bu_k

**代价函数**：
```
J = Σ (x_k'Qx_k + u_k'Ru_k) + x_N'Sx_N
```

**Bellman 解**：V_k(x) = x'P_k*x
```
P_k = Q + A'P_{k+1}A - A'P_{k+1}B(R + B'P_{k+1}B)^(-1)B'P_{k+1}A
K_k = (R + B'P_{k+1}B)^(-1)B'P_{k+1}A
```

**无限时域 LQR**（Riccati 方程）：
```
P = Q + A'PA - A'PB(R + B'PB)^(-1)B'PA
K = (R + B'PB)^(-1)B'PA
```

## 3. 线性二次调节器 (LQR)

### 3.1 连续时间 LQR

**问题描述**：
```
min J = ∫₀^∞ (x'Qx + u'Ru) dt
s.t.  ẋ = Ax + Bu
```

**最优控制律**：u = -Kx
```
K = R^(-1)B'P
```
其中 P 满足代数 Riccati 方程 (ARE)：
```
A'P + PA - PBR^(-1)B'P + Q = 0
```

**MATLAB**：`[K, P, e] = lqr(A, B, Q, R)`

### 3.2 LQR 设计参数选择

**Q 和 R 的物理意义**：
- Q: 状态权重矩阵，Q 越大 → 状态调节越快
- R: 控制权重矩阵，R 越大 → 控制越节能

**Bryson 法则**：
```
Q_ii = 1/x_{i,max}²,  R_jj = 1/u_{j,max}²
```

**调节 Q/R 比例**：
- Q/R 大 → 快速响应，大控制量
- Q/R 小 → 慢速响应，小控制量

### 3.3 LQR 的稳定性保证

**增益裕度**：
- 回路增益：[1/2, ∞)
- 等效于 GM = 6dB, PM ≥ 60°

**鲁棒性**：LQR 保证每个输入通道至少 60° 相位裕度

### 3.4 离散时间 LQR

**系统**：x_(k+1) = Ax_k + Bu_k

**代价**：J = Σ(x_k'Qx_k + u_k'Ru_k)

**最优控制**：u_k = -Kx_k
```
K = (R + B'PB)^(-1)B'PA
```
P 满足离散代数 Riccati 方程 (DARE)：
```
P = Q + A'PA - A'PB(R + B'PB)^(-1)B'PA
```

**MATLAB**：`[K, P, e] = dlqr(A, B, Q, R)`

## 4. 线性二次高斯 (LQG)

### 4.1 随机系统与卡尔曼滤波

**系统模型**：
```
x_(k+1) = Ax_k + Bu_k + w_k    (过程噪声)
y_k = Cx_k + v_k                (测量噪声)
```

**噪声统计**：
- w_k ~ N(0, Q_n)  （过程噪声协方差）
- v_k ~ N(0, R_n)  （测量噪声协方差）
- E[w_k * v_j'] = 0  （不相关）

### 4.2 卡尔曼滤波器

**预测步**：
```
x̂_(k|k-1) = A*x̂_(k-1|k-1) + B*u_(k-1)
P_(k|k-1) = A*P_(k-1|k-1)*A' + Q_n
```

**更新步**：
```
K_k = P_(k|k-1)*C' * (C*P_(k|k-1)*C' + R_n)^(-1)  (卡尔曼增益)
x̂_(k|k) = x̂_(k|k-1) + K_k*(y_k - C*x̂_(k|k-1))    (状态更新)
P_(k|k) = (I - K_k*C)*P_(k|k-1)                      (协方差更新)
```

**稳态卡尔曼增益**（无限时域）：
```
K_∞ = PC'(CPC' + R_n)^(-1)
```
P 满虑 Riccati 方程：
```
P = APA' + Q_n - APC'(CPC' + R_n)^(-1)CPA'
```

**MATLAB**：`[Kf, P, e] = kalman(sys, Q_n, R_n)`

### 4.3 卡尔曼滤波器的性质

- **最优性**：最小化估计误差协方差 E[(x - x̂)(x - x̂)']
- **无偏性**：E[x̂] = E[x]
- **一致性**：P 是实际误差协方差的上界（模型准确时为等号）

### 4.4 LQG 控制器

**分离定理**：LQG = LQR（状态反馈）+ 卡尔曼滤波器（状态估计）

**完整控制器**：
```
x̂_(k+1) = (A - BK - KfC + KfCBK)*x̂_k + Kf*y_k
u_k = -K*x̂_k
```

**MATLAB**：
```matlab
[K, ~, ~] = lqr(A, B, Q, R);          % LQR 增益
[Kf, ~, ~] = kalman(sys, Qn, Rn);      % 卡尔曼增益
LQG = lqg(sys, Q_weight, R_weight);    % 完整 LQG
```

## 5. 模型预测控制 (MPC)

### 5.1 MPC 基本原理

**核心思想**：在每个采样时刻求解有限时域优化问题，只执行第一步控制输入，然后重新优化（滚动时域）。

**标准 MPC 问题**：
```
min J = Σ_{k=0}^{N-1} [||x_k - x_ref||²_Q + ||u_k||²_R] + ||x_N - x_ref||²_P
s.t.  x_(k+1) = Ax_k + Bu_k
      u_min ≤ u_k ≤ u_max
      x_min ≤ x_k ≤ x_max
      x_0 = x_current
```

- N: 预测时域（prediction horizon）
- Q: 状态权重
- R: 控制权重
- P: 终端权重

### 5.2 无约束 MPC

**解析解**（与 LQR 等价，N→∞）：
```
u_0 = -K*x_current
```

**有限时域无约束 MPC**：
将优化问题转化为 QP：
```
min (1/2)U'HU + f'U
```
其中 U = [u_0, u_1, ..., u_(N-1)]

### 5.3 有约束 MPC

**转化为 QP 问题**：
```
min (1/2)U'HU + f'(x_0)U
s.t.  A_ineq*U ≤ b_ineq(x_0)
```

**求解方法**：
- 内点法（适合大规模问题）
- 有效集法（适合小规模问题）
- 显式 MPC（离线计算，查表执行）

### 5.4 稳定性保证

**终端约束法**：
- 终端约束：x_N = 0（或 x_N ∈ X_f）
- 终端代价：V_f(x) = x'Px（P 为 LQR Riccati 解）
- 保证递归可行性和稳定性

**终端代价+终端区域法**：
- 终端区域 X_f 内使用局部控制器
- V_f 是 X_f 内的控制 Lyapunov 函数

### 5.5 MPC 设计参数

| 参数 | 影响 | 设计建议 |
|------|------|---------|
| N（预测时域） | 太小不稳定，太大计算量大 | N ≈ 上升时间/采样时间 |
| N_c（控制时域） | 减小自由度，加快计算 | N_c ≤ N，通常 N_c = 1~5 |
| Q（状态权重） | Q 大→快速响应 | Bryson 法则 |
| R（控制权重） | R 大→节能 | 根据控制量限制调整 |
| 采样时间 T_s | 太大失真，太大计算量大 | T_s ≤ 闭环上升时间/10 |

### 5.6 MPC 变体

**参考跟踪 MPC**：
- 引入参考轨迹 x_ref
- 可以设定柔化因子 α: x_desired = α*x_prev + (1-α)*x_ref

**输出 MPC**：
- 只惩罚输出 y = Cx，不惩罚全部状态

**Tube MPC**（鲁棒 MPC）：
- 名义轨迹 + 不确定性管
- 保证鲁棒约束满足

**非线性 MPC (NMPC)**：
- 系统模型为非线性：x_(k+1) = f(x_k, u_k)
- 求解非线性规划（NLP）

### 5.7 MPC 的 MATLAB 实现

```matlab
% 使用 MPC Toolbox
mpcobj = mpc(sys, Ts);
mpcobj.PredictionHorizon = N;
mpcobj.ControlHorizon = Nc;
mpcobj.Weights.OutputVariables = 1;
mpcobj.Weights.ManipulatedVariables = 0.1;

% 约束设置
mpcobj.MV.Min = -10;
mpcobj.MV.Max = 10;

% 仿真
sim(mpcobj, N_steps, x0);
```

## 6. 状态估计进阶

### 6.1 扩展卡尔曼滤波 (EKF)

**非线性系统**：
```
x_(k+1) = f(x_k, u_k) + w_k
y_k = h(x_k) + v_k
```

**线性化**：
```
F_k = ∂f/∂x |_{x̂_k}
H_k = ∂h/∂x |_{x̂_(k+1|k)}
```

**EKF 公式**（与 KF 形式相同，但 Jacobian 依赖工作点）：
```
预测：x̂_(k+1|k) = f(x̂_(k|k), u_k)
      P_(k+1|k) = F_k*P_(k|k)*F_k' + Q_n
更新：K_k = P_(k+1|k)*H_k'*(H_k*P_(k+1|k)*H_k' + R_n)^(-1)
      x̂_(k+1|k+1) = x̂_(k+1|k) + K_k*(y_k - h(x̂_(k+1|k)))
```

### 6.2 无迹卡尔曼滤波 (UKF)

**Sigma 点生成**：
```
χ_0 = x̂
χ_i = x̂ + (√((n+λ)P))_i,  i = 1,...,n
χ_(i+n) = x̂ - (√((n+λ)P))_i
```

**优势**：不需要计算 Jacobian，精度高于 EKF

### 6.3 粒子滤波

**核心思想**：用一组加权粒子表示后验分布

**步骤**：
1. 采样（从建议分布生成粒子）
2. 权重更新（根据似然函数）
3. 重采样（避免粒子退化）

**适用场景**：高度非线性、非高斯系统

## 7. 关键公式速查

| 公式 | 表达式 | 用途 |
|------|--------|------|
| LQR ARE | A'P+PA-PBR⁻¹B'P+Q=0 | 连续 LQR |
| LQR 增益 | K=R⁻¹B'P | 状态反馈 |
| KF 预测 | x̂=Ax̂+Bu, P=APA'+Q | 状态预测 |
| KF 更新 | K=PC'(CPC'+R)⁻¹ | 卡尔曼增益 |
| KF 协方差 | P=(I-KC)P | 误差协方差 |
| MPC 目标 | Σ(||x||²_Q+||u||²_R) | 有限时域代价 |
| Bellman | V=min{l+V∘f} | 最优性原理 |
| KKT | ∇f+Σμ∇g=0, μg=0 | 约束优化 |

## 8. 应用场景

| 问题类型 | 推荐方法 | 关键参数 |
|---------|---------|---------|
| 线性系统调节 | LQR | Q, R |
| 有约束线性系统 | MPC | N, Nc, Q, R |
| 状态估计（线性） | 卡尔曼滤波 | Qn, Rn |
| 状态估计（非线性） | EKF / UKF | 模型精度 |
| 非线性最优控制 | NMPC | 模型、约束 |
| 随机最优控制 | LQG | 分离定理 |
| 跟踪控制 | 参考跟踪 MPC | 参考轨迹设计 |
