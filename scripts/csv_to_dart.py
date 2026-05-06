#!/usr/bin/env python3
# csv_to_dart.py - kokoro.csv から Dart データファイルを自動生成するスクリプト

import csv
import re
from collections import defaultdict

INPUT_PATH  = '/home/fireubuntu/projects/side/dqw_kokoro_michi/scripts/kokoro.csv'
OUTPUT_PATH = '/home/fireubuntu/projects/side/dqw_kokoro_michi/lib/data/kokoro_michi_data.dart'

# 職業名 → ID
JOB_ID_MAP = {
    'ゴッドハンド':   'god_hand',
    '大魔道士':       'dai_majutsushi',
    '大神官':         'dai_shinkan',
    'ニンジャ':       'ninja',
    '魔剣士':         'maken_shi',
    '守り人':         'mamoribito',
    'ドラゴン':       'dragon',
    '天地雷鳴士':     'tenjiraimeishi',
    '魔人':           'majin',
    '時渡りの剣士':   'tokiwatari',
}

# 出力順
JOB_ORDER = [
    'ゴッドハンド', '大魔道士', '大神官', 'ニンジャ', '魔剣士',
    '守り人', 'ドラゴン', '天地雷鳴士', '魔人', '時渡りの剣士',
]

# 各職業の分岐名 (branchA, branchB)
BRANCH_MAP = {
    'god_hand':       ('武道',     '守護道'),
    'dai_majutsushi': ('魔力道',   '理力道'),
    'dai_shinkan':    ('祈道',     '舞道'),
    'ninja':          ('風道',     '波道'),
    'maken_shi':      ('魔道',     '刃道'),
    'mamoribito':     ('まもり道', 'ささえ道'),
    'dragon':         ('竜道',     '人道'),
    'tenjiraimeishi': ('天道',     '地道'),
    'majin':          ('超人道',   '超魔道'),
    'tokiwatari':     ('巡行道',   '遡行道'),
}

# michi_type 判定用セット（正規化後の道名で完全一致）
BRANCH_A_SET = {'武道', '魔力道', '祈道', '風道', '魔道', 'まもり道', '竜道', '天道', '超人道', '巡行道'}
BRANCH_B_SET = {'守護道', '理力道', '舞道', '波道', '刃道', 'ささえ道', '人道', '地道', '超魔道', '遡行道'}

# 丸数字 → 整数
MARU_NUM = {'①': 1, '②': 2, '③': 3, '④': 4, '⑤': 5,
            '⑥': 6, '⑦': 7, '⑧': 8, '⑨': 9, '⑩': 10}


def normalize_route(raw: str) -> str:
    """守り人のルート名を統一形式に変換する"""
    s = raw.replace('まもり/加護道', 'まもり道')
    s = s.replace('ささえ/祝福道',  'ささえ道')
    return s


def parse_route(raw: str):
    """ルート名を解析して dict を返す。解析失敗時は (None, 警告メッセージ) を返す。"""
    route = normalize_route(raw.strip())

    # 最初の道
    if '最初の道' in route:
        lv = re.search(r'Lv\.(\d+)以上', route)
        return {
            'michi':       '最初の道',
            'michi_type':  'common',
            'route_no':    0,
            'min_level':   int(lv.group(1)) if lv else 1,
            'needs_darma': False,
        }, None

    # ルートNo（丸数字）
    route_no = 0
    for ch, n in MARU_NUM.items():
        if ch in route:
            route_no = n
            break

    # 道名を「ルートN」の直前まで切り出す
    m = re.match(r'^(.+?)ルート[①②③④⑤⑥⑦⑧⑨⑩]', route)
    if not m:
        return None, f'ルートNo が見つからない: 「{raw}」'
    michi = m.group(1).strip()

    # michi_type を道名セットで判定（完全一致）
    if michi in BRANCH_A_SET:
        michi_type = 'a'
    elif michi in BRANCH_B_SET:
        michi_type = 'b'
    else:
        return None, f'道名不明: 「{michi}」(元: 「{raw}」)'

    lv = re.search(r'Lv\.(\d+)以上', route)
    return {
        'michi':       michi,
        'michi_type':  michi_type,
        'route_no':    route_no,
        'min_level':   int(lv.group(1)) if lv else 1,
        'needs_darma': 'ダーマ試練' in route,
    }, None


def parse_kokoro(raw: str):
    """こころ名を解析して (name, isKakusei) を返す。無効な場合は None を返す。"""
    s = raw.strip()
    if not s or s == 'なし':
        return None

    # 覚醒判定（半角・全角括弧）
    is_kakusei = bool(re.search(r'[（(]覚醒[）)]$', s))
    name = re.sub(r'[（(]覚醒[）)]$', '', s).strip()

    if not name:
        return None
    return {'name': name, 'isKakusei': is_kakusei}


def dart_str(s: str) -> str:
    """Dart シングルクォート文字列用にエスケープする"""
    return s.replace('\\', '\\\\').replace("'", "\\'")


def dart_bool(b: bool) -> str:
    return 'true' if b else 'false'


def generate_dart(jobs_data: dict) -> str:
    lines = [
        '// lib/data/kokoro_michi_data.dart',
        '// 自動生成ファイル - csv_to_dart.py により生成',
        '',
        'class KokoroEntry {',
        '  final String name;',
        '  final bool isKakusei;',
        '  const KokoroEntry(this.name, {this.isKakusei = false});',
        '}',
        '',
        'class KokoroMichiRoute {',
        '  final String michi;',
        '  final String michiType;',
        '  final int routeNo;',
        '  final int minLevel;',
        '  final bool needsDarma;',
        '  final List<String> bonuses;',
        '  final List<KokoroEntry> kokoroList;',
        '  const KokoroMichiRoute({',
        '    required this.michi,',
        '    required this.michiType,',
        '    required this.routeNo,',
        '    required this.minLevel,',
        '    required this.needsDarma,',
        '    required this.bonuses,',
        '    required this.kokoroList,',
        '  });',
        '}',
        '',
        'class KokoroMichiJob {',
        '  final String id;',
        '  final String name;',
        '  final String branchA;',
        '  final String branchB;',
        '  final List<KokoroMichiRoute> routes;',
        '  const KokoroMichiJob({',
        '    required this.id,',
        '    required this.name,',
        '    required this.branchA,',
        '    required this.branchB,',
        '    required this.routes,',
        '  });',
        '}',
        '',
        'const List<KokoroMichiJob> kokoroMichiData = [',
    ]

    for job_name in JOB_ORDER:
        if job_name not in jobs_data:
            continue
        job_id = JOB_ID_MAP[job_name]
        branch_a, branch_b = BRANCH_MAP[job_id]
        routes = jobs_data[job_name]

        lines.append('  KokoroMichiJob(')
        lines.append(f"    id: '{job_id}',")
        lines.append(f"    name: '{dart_str(job_name)}',")
        lines.append(f"    branchA: '{dart_str(branch_a)}',")
        lines.append(f"    branchB: '{dart_str(branch_b)}',")
        lines.append('    routes: [')

        for r in routes:
            bonus_dart  = ', '.join(f"'{dart_str(b)}'" for b in r['bonuses'])
            kokoro_dart = ', '.join(
                (f"KokoroEntry('{dart_str(k['name'])}', isKakusei: true)"
                 if k['isKakusei']
                 else f"KokoroEntry('{dart_str(k['name'])}')")
                for k in r['kokoroList']
            )
            lines.append('      KokoroMichiRoute(')
            lines.append(f"        michi: '{dart_str(r['michi'])}',")
            lines.append(f"        michiType: '{r['michi_type']}',")
            lines.append(f"        routeNo: {r['route_no']},")
            lines.append(f"        minLevel: {r['min_level']},")
            lines.append(f"        needsDarma: {dart_bool(r['needs_darma'])},")
            lines.append(f'        bonuses: [{bonus_dart}],')
            lines.append(f'        kokoroList: [{kokoro_dart}],')
            lines.append('      ),')

        lines.append('    ],')
        lines.append('  ),')

    lines.append('];')
    return '\n'.join(lines)


def main():
    jobs_data: dict[str, list] = defaultdict(list)
    warnings = []
    total_kokoro = 0

    with open(INPUT_PATH, encoding='utf-8-sig', newline='') as f:
        reader = csv.reader(f)
        next(reader)  # ヘッダースキップ

        for row_idx, row in enumerate(reader, start=2):
            if len(row) < 4:
                warnings.append(f'行{row_idx}: 列数不足 ({len(row)}列)')
                continue

            job_name  = row[1].strip()
            route_raw = row[2].strip()
            bonus_raw = row[3].strip()
            kokoro_cols = row[4:]

            if not job_name:
                continue

            if job_name not in JOB_ID_MAP:
                warnings.append(f'行{row_idx}: 未知の職業「{job_name}」')
                continue

            parsed, err = parse_route(route_raw)
            if parsed is None:
                warnings.append(f'行{row_idx}: ルート解析失敗 — {err}')
                continue

            # ボーナス（改行区切り）
            parsed['bonuses'] = [b.strip() for b in bonus_raw.split('\n') if b.strip()]

            # こころ
            kokoro_list = []
            for cell in kokoro_cols:
                k = parse_kokoro(cell)
                if k:
                    kokoro_list.append(k)
                    total_kokoro += 1
            parsed['kokoroList'] = kokoro_list

            jobs_data[job_name].append(parsed)

    # Dart コード生成・書き出し
    dart_code = generate_dart(jobs_data)
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        f.write(dart_code)

    # 確認表示
    print('=== 生成完了 ===')
    print(f'出力: {OUTPUT_PATH}')
    print()
    print('--- 職業別ルート数 ---')
    for job_name in JOB_ORDER:
        routes = jobs_data.get(job_name, [])
        common = sum(1 for r in routes if r['michi_type'] == 'common')
        a      = sum(1 for r in routes if r['michi_type'] == 'a')
        b      = sum(1 for r in routes if r['michi_type'] == 'b')
        print(f'  {job_name:<12}: 合計{len(routes):>2}本  (common:{common}, a:{a}, b:{b})')

    print()
    print(f'総こころエントリ数: {total_kokoro}')

    if warnings:
        print()
        print('=== 警告 ===')
        for w in warnings:
            print(f'  ⚠ {w}')
    else:
        print('警告: なし')


if __name__ == '__main__':
    main()
