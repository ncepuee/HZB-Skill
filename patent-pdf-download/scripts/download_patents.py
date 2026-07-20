# -*- coding: utf-8 -*-
"""
批量下载专利 PDF - 从 Google Patents
======================================
使用步骤：
1. 修改下方 TARGET_DIR 为目标输出文件夹
2. 修改 PATENTS 列表为要下载的专利
3. 运行: python download_patents.py

支持的专利号格式：
- 中国申请号: ZL2022xxxxxxxx.X, CN2022xxxxxxxx.X, CN2022xxxxxxxx
- 中国公开号: CNxxxxxxxA, CNxxxxxxxB
- 美国专利:  USxxxxxxxxB2, USxxxxxxxxB1
- 欧洲专利:  EPxxxxxxx, EPxxxxxxxA1

网络要求：能访问 patents.google.com（国内可能需要代理）
"""
import os
import re
import time
import json
import requests

# ========== 配置区 ==========
TARGET_DIR = './patents'   # 下载目标文件夹

# (序号, 专利号, 简短标题)
# 专利号可以是: 申请号(ZL...)/公开号(CN...B)/US.../EP...
PATENTS = [
    # 示例（请替换为实际专利号）
    # (1, 'ZL2022XXXXXXXX.X', '专利标题一'),
    # (2, 'USXXXXXXXXB2',    'Patent title two'),
    # (3, 'EPXXXXXXX',       'European patent title'),
]
# ============================


session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
})


def sanitize_filename(name):
    """去除 Windows 非法文件名字符"""
    return re.sub(r'[<>:"/\\|?*]', '-', name)[:100]


def get_publication_number(application_no):
    """通过 Google Patents 搜索API找中国专利的公开号

    输入: CN2022XXXXXXXX.X 或 2022XXXXXXXX.X 或 ZL2022XXXXXXXX.X
    输出: CNxxxxxxxB / CNxxxxxxxA （或 None）
    """
    # 提取纯数字（丢弃前缀和校验位）
    clean = application_no.replace('ZL', '').replace('CN', '').strip()
    m = re.match(r'([0-9]+)\.?([XY0-9]?)$', clean)
    if m:
        clean = m.group(1)

    api_url = f'https://patents.google.com/xhr/query?url=q%3D{clean}&exp='
    try:
        r = session.get(api_url, timeout=30)
        if r.status_code == 200:
            data = json.loads(r.text)
            results = data.get('results', {}).get('cluster', [])
            for cluster in results:
                for item in cluster.get('result', []):
                    pnum = item.get('patent', {}).get('publication_number', '')
                    if pnum:
                        return pnum
    except Exception as e:
        print(f'    搜索API错误: {e}')
    return None


def get_pdf_from_page(publication_number):
    """从 Google Patents 详情页取 PDF 直链

    返回: PDF URL 或 None
    """
    url = f'https://patents.google.com/patent/{publication_number}'
    try:
        r = session.get(url, timeout=30)
        if r.status_code != 200:
            return None
        pdf_links = re.findall(
            r'https://patentimages\.storage\.googleapis\.com/[^"\']+\.pdf',
            r.text,
        )
        return pdf_links[0] if pdf_links else None
    except Exception as e:
        print(f'    详情页错误: {e}')
        return None


def download_pdf(pdf_url, save_path):
    """下载 PDF 到本地"""
    try:
        r = session.get(pdf_url, timeout=90)
        if r.status_code == 200 and len(r.content) > 10240:
            # 校验是 PDF
            if r.content[:4] != b'%PDF':
                return False, '返回内容不是PDF'
            with open(save_path, 'wb') as f:
                f.write(r.content)
            return True, len(r.content)
        return False, f'HTTP {r.status_code}'
    except Exception as e:
        return False, str(e)


def process_patent(num, patent_no, title, target_dir):
    """处理单个专利：查公开号 → 下详情页 → 下PDF"""
    safe_title = sanitize_filename(title)
    filename = f'{num}.{safe_title}（{patent_no}）.pdf'
    save_path = os.path.join(target_dir, filename)

    # 已下载则跳过
    if os.path.exists(save_path) and os.path.getsize(save_path) > 10240:
        print(f'✓ 已存在: {num}. {title[:40]}')
        return True

    print(f'\n[{num}] {patent_no} - {title[:50]}')

    # EP/US 直接用编号；CN 要先查公开号
    if patent_no.startswith(('EP', 'US', 'JP', 'KR', 'WO')):
        # 保留完整编号，含后缀
        candidates = [patent_no]
    else:
        # 中国专利：查公开号
        print(f'  查询公开号...')
        pub_no = get_publication_number(patent_no)
        if not pub_no:
            print(f'  ❌ 未找到公开号')
            return False
        print(f'  公开号: {pub_no}')
        # 优先 A 版（公开），再 B 版（授权）
        base = pub_no.rstrip('AB')
        candidates = [f'{base}A', f'{base}B', pub_no]

    time.sleep(1.5)

    for pnum in candidates:
        pdf_url = get_pdf_from_page(pnum)
        if pdf_url:
            print(f'  找到PDF: {pdf_url}')
            ok, info = download_pdf(pdf_url, save_path)
            if ok:
                # 用实际找到的公开号更新文件名
                new_filename = f'{num}.{safe_title}（{pnum}）.pdf'
                new_path = os.path.join(target_dir, new_filename)
                if new_path != save_path:
                    os.rename(save_path, new_path)
                print(f'  ✓ 成功: {info // 1024}KB')
                return True
            else:
                print(f'  ❌ 下载失败: {info}')
        time.sleep(1)

    print(f'  ❌ 所有候选URL都失败')
    return False


def main():
    os.makedirs(TARGET_DIR, exist_ok=True)

    if not PATENTS:
        print('请先在脚本顶部 PATENTS 列表中填入专利号')
        return

    success = 0
    failed = []
    for num, patent_no, title in PATENTS:
        if process_patent(num, patent_no, title, TARGET_DIR):
            success += 1
        else:
            failed.append((num, patent_no, title))
        time.sleep(2)

    print(f'\n\n{"=" * 60}')
    print(f'汇总: 成功 {success}/{len(PATENTS)}, 失败 {len(failed)}')
    if failed:
        print(f'\n失败清单（可从本地/CNKI/国知局查找）:')
        for num, no, title in failed:
            print(f'  {num}. {no} - {title[:50]}')
            print(f'     建议查询: https://patents.google.com/?q=%22{no}%22')


if __name__ == '__main__':
    main()
