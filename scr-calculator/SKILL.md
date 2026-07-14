---
name: scr-calculator
description: 短路比(SCR)计算器，用于电力电子变流器并网系统的电网强度评估。支持已知电感求SCR、已知SCR求电感、批量对照表生成。适用于GFM/VSG并网控制稳定性分析、弱电网工况设计、实验参数匹配。触发词：短路比、SCR、short circuit ratio、电网电感、弱电网、grid strength、电网强度、Lg计算、标幺值电感。
---

# SCR 短路比计算器

## 用途

计算电力电子变流器并网系统的短路比（SCR）与电网电感（Lg）的对应关系，评估电网强度。

## 核心公式

```
Znom = Ul² / Sn          # 基准阻抗 (Ω)
Lnom = Znom / (2πf)      # 基准电感 (H)，×1000 得 mH
Xg = 2πf × Lg            # 电网电抗 (Ω)
SCR = Znom / Xg           # 短路比
Lg(mH) = Lnom(mH) / SCR   # 简捷公式
```

## 使用方式

### Python 脚本（推荐）

```powershell
# 已知电感求 SCR
python scripts/scr_calc.py --Sn 3 --Ul 110 --Lg 12

# 已知 SCR 求电感
python scripts/scr_calc.py --Sn 3 --Ul 110 --SCR 1.25

# 生成对照表
python scripts/scr_calc.py --Sn 3 --Ul 110 --table

# 详细输出含验证
python scripts/scr_calc.py --Sn 3 --Ul 110 --Lg 12 --detail
```

参数说明:
- `--Sn`: 额定容量 (kVA)，默认 3
- `--Ul`: 线电压 (V)，默认 110
- `--f`: 频率 (Hz)，默认 50
- `--Lg`: 电网电感 (mH)，求 SCR
- `--SCR`: 短路比，求电感
- `--table`: 生成 SCR-Lg 对照表
- `--detail`: 详细输出含标幺值和验证

### 手动计算（当脚本不可用时）

1. 基准阻抗: Znom = Ul² / Sn
2. 基准电感: Lnom = Znom / (2πf) × 1000 (mH)
3. 简捷公式: Lg(mH) = Lnom / SCR 或 SCR = Lnom / Lg(mH)

## 电网强度分类

| SCR 范围 | 分类 |
|----------|------|
| SCR ≥ 10 | 强电网 |
| 5 ≤ SCR < 10 | 中等电网 |
| 2 ≤ SCR < 5 | 弱电网 |
| 1.5 ≤ SCR < 2 | 较弱电网 |
| SCR < 1.5 | 极弱电网 |
