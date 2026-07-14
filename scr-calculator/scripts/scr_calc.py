#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SCR (Short Circuit Ratio) 计算器
适用于电力电子变流器并网系统，支持任意容量/电压等级。

用法:
  python scr_calc.py --Sn 3 --Ul 110 --Lg 12          # 已知电感求 SCR
  python scr_calc.py --Sn 3 --Ul 110 --SCR 1.25        # 已知 SCR 求电感
  python scr_calc.py --Sn 3 --Ul 110 --table           # 生成 SCR-Lg 对照表
  python scr_calc.py --Sn 3 --Ul 110 --Lg 12 --detail  # 详细输出含标幺值
"""

import argparse
import math
import sys


def calc_base_values(Sn_kVA: float, Ul_V: float, f_Hz: float = 50.0):
    """计算系统基准值"""
    Sn = Sn_kVA * 1000  # VA
    Znom = Ul_V ** 2 / Sn  # Ω
    Lnom_mH = Znom / (2 * math.pi * f_Hz) * 1000  # mH
    Cnom_uF = 1 / (2 * math.pi * f_Hz * Znom) * 1e6  # μF
    return {
        "Sn": Sn,
        "Ul": Ul_V,
        "Uph": Ul_V / math.sqrt(3),
        "f": f_Hz,
        "Znom": Znom,
        "Lnom_mH": Lnom_mH,
        "Cnom_uF": Cnom_uF,
    }


def calc_scr_from_Lg(Lg_mH: float, base: dict):
    """已知电网电感求 SCR"""
    Lg_H = Lg_mH / 1000
    Xg = 2 * math.pi * base["f"] * Lg_H
    SCR = base["Znom"] / Xg
    Lg_pu = Lg_mH / base["Lnom_mH"]
    return {"Xg": Xg, "SCR": SCR, "Lg_pu": Lg_pu}


def calc_Lg_from_scr(SCR: float, base: dict):
    """已知 SCR 求电网电感"""
    Xg = base["Znom"] / SCR
    Lg_mH = Xg / (2 * math.pi * base["f"]) * 1000
    Lg_pu = Lg_mH / base["Lnom_mH"]
    return {"Xg": Xg, "Lg_mH": Lg_mH, "Lg_pu": Lg_pu}


def classify_grid(SCR: float) -> str:
    """电网强度分类"""
    if SCR >= 10:
        return "强电网"
    elif SCR >= 5:
        return "中等电网"
    elif SCR >= 2:
        return "弱电网"
    elif SCR >= 1.5:
        return "较弱电网"
    else:
        return "极弱电网"


def print_base(base: dict):
    print(f"  系统基准值:")
    print(f"    额定容量 Sn = {base['Sn']/1000:.1f} kVA")
    print(f"    线电压 Ul = {base['Ul']:.1f} V")
    print(f"    相电压 Uph = {base['Uph']:.2f} V")
    print(f"    频率 f = {base['f']:.0f} Hz")
    print(f"    基准阻抗 Znom = {base['Znom']:.4f} Ω")
    print(f"    基准电感 Lnom = {base['Lnom_mH']:.4f} mH")
    print(f"    基准电容 Cnom = {base['Cnom_uF']:.2f} μF")


def print_result_scr(Lg_mH: float, result: dict, base: dict, detail: bool = False):
    SCR = result["SCR"]
    print(f"\n  结果:")
    print(f"    电网电感 Lg = {Lg_mH:.4g} mH")
    print(f"    电网电抗 Xg = {result['Xg']:.4f} Ω")
    print(f"    短路比 SCR = {SCR:.4f}")
    print(f"    电感标幺值 = {result['Lg_pu']:.4f} pu")
    print(f"    电网分类: {classify_grid(SCR)}")
    if detail:
        print(f"\n  简捷公式: Lg(mH) = {base['Lnom_mH']:.4f} / SCR")
        print(f"  验证: {base['Lnom_mH']:.4f} / {SCR:.4f} = {base['Lnom_mH']/SCR:.4f} mH ✓")


def print_result_Lg(SCR: float, result: dict, base: dict, detail: bool = False):
    Lg_mH = result["Lg_mH"]
    print(f"\n  结果:")
    print(f"    短路比 SCR = {SCR:.4f}")
    print(f"    电网电抗 Xg = {result['Xg']:.4f} Ω")
    print(f"    电网电感 Lg = {Lg_mH:.4f} mH")
    print(f"    电感标幺值 = {result['Lg_pu']:.4f} pu")
    print(f"    电网分类: {classify_grid(SCR)}")
    if detail:
        print(f"\n  简捷公式: Lg(mH) = {base['Lnom_mH']:.4f} / SCR")
        print(f"  验证: {base['Lnom_mH']:.4f} / {SCR} = {Lg_mH:.4f} mH ✓")


def print_table(base: dict, scr_list=None):
    if scr_list is None:
        scr_list = [40, 20, 10, 5, 2.5, 2, 1.5, 1.25, 1.0]
    print(f"\n  SCR-Lg 对照表 (Sn={base['Sn']/1000:.1f}kVA, Ul={base['Ul']:.0f}V, f={base['f']:.0f}Hz)")
    print(f"  {'SCR':>8} | {'Xg(Ω)':>10} | {'Lg(mH)':>10} | {'Lg(pu)':>8} | 电网强度")
    print(f"  {'-'*8} | {'-'*10} | {'-'*10} | {'-'*8} | {'-'*12}")
    for scr in scr_list:
        r = calc_Lg_from_scr(scr, base)
        print(f"  {scr:>8.2f} | {r['Xg']:>10.4f} | {r['Lg_mH']:>10.4f} | {r['Lg_pu']:>8.4f} | {classify_grid(scr)}")
    print(f"\n  简捷公式: Lg(mH) = {base['Lnom_mH']:.4f} / SCR")


def main():
    parser = argparse.ArgumentParser(
        description="SCR 短路比计算器 (电力电子并网系统)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("--Sn", type=float, default=3.0, help="额定容量 (kVA), 默认 3")
    parser.add_argument("--Ul", type=float, default=110.0, help="线电压 (V), 默认 110")
    parser.add_argument("--f", type=float, default=50.0, help="频率 (Hz), 默认 50")
    parser.add_argument("--Lg", type=float, help="电网电感 (mH), 求 SCR")
    parser.add_argument("--SCR", type=float, help="短路比, 求电网电感 Lg")
    parser.add_argument("--table", action="store_true", help="生成 SCR-Lg 对照表")
    parser.add_argument("--detail", action="store_true", help="详细输出含验证")

    args = parser.parse_args()

    base = calc_base_values(args.Sn, args.Ul, args.f)

    if args.table:
        print_base(base)
        print_table(base)
        return

    if args.Lg is not None:
        print_base(base)
        result = calc_scr_from_Lg(args.Lg, base)
        print_result_scr(args.Lg, result, base, args.detail)
        return

    if args.SCR is not None:
        print_base(base)
        result = calc_Lg_from_scr(args.SCR, base)
        print_result_Lg(args.SCR, result, base, args.detail)
        return

    # 无参数时打印帮助
    parser.print_help()
    print("\n示例:")
    print(f"  python scr_calc.py --Sn 3 --Ul 110 --Lg 12          # 12mH 对应多大 SCR?")
    print(f"  python scr_calc.py --Sn 3 --Ul 110 --SCR 1.25        # SCR=1.25 对应多大电感?")
    print(f"  python scr_calc.py --Sn 3 --Ul 110 --table           # 生成对照表")
    sys.exit(0)


if __name__ == "__main__":
    main()
