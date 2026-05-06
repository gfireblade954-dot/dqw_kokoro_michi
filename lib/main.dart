import 'package:flutter/material.dart';
import 'data/kokoro_michi_data.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DQW こころ道チェッカー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB5451B)),
        useMaterial3: true,
      ),
      home: const KokoroMichiPage(),
    );
  }
}

// ──────────────────────────────────────────────
// メイン画面
// ──────────────────────────────────────────────
class KokoroMichiPage extends StatefulWidget {
  const KokoroMichiPage({super.key});

  @override
  State<KokoroMichiPage> createState() => _KokoroMichiPageState();
}

class _KokoroMichiPageState extends State<KokoroMichiPage> {
  KokoroMichiJob _selectedJob = kokoroMichiData.first;

  void _onJobChanged(KokoroMichiJob? job) {
    if (job == null) return;
    setState(() => _selectedJob = job);
  }

  KokoroMichiRoute? get _commonRoute =>
      _selectedJob.routes.where((r) => r.michiType == 'common').firstOrNull;

  // routeNo 昇順で branchA / branchB ルートを取得
  List<KokoroMichiRoute> _routesByType(String type) => _selectedJob.routes
      .where((r) => r.michiType == type)
      .toList()
    ..sort((a, b) => a.routeNo.compareTo(b.routeNo));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('DQW こころ道チェッカー'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildJobSelector(theme),
            const SizedBox(height: 12),
            if (_commonRoute != null) ...[
              _buildCommonSection(theme, _commonRoute!),
              const SizedBox(height: 12),
            ],
            _buildGridSection(theme),
          ],
        ),
      ),
    );
  }

  // ──────────── 職業選択ドロップダウン ────────────
  Widget _buildJobSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '職業',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButton<KokoroMichiJob>(
              value: _selectedJob,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: kokoroMichiData.map((job) {
                return DropdownMenuItem(
                  value: job,
                  child: Text(job.name, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: _onJobChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── 最初の道（常時表示） ────────────
  Widget _buildCommonSection(ThemeData theme, KokoroMichiRoute route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(theme, '最初の道（共通）', Icons.star_outline),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bonusList(route.bonuses, fontSize: 13),
                if (route.kokoroList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _kokoroWrap(theme, route.kokoroList),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────── 分岐2カラムグリッド ────────────
  Widget _buildGridSection(ThemeData theme) {
    final routesA = _routesByType('a');
    final routesB = _routesByType('b');
    final count = routesA.length > routesB.length
        ? routesA.length
        : routesB.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingle = constraints.maxWidth <= 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 列見出し（分岐名）
            _buildColumnHeaders(theme, isSingle),
            const SizedBox(height: 8),

            // ルート①〜⑩ をペアで並べる
            ...List.generate(count, (i) {
              final routeA = i < routesA.length ? routesA[i] : null;
              final routeB = i < routesB.length ? routesB[i] : null;
              // 奇数行は薄い背景色
              final isOdd = i.isOdd;

              if (isSingle) {
                // 360px 以下: 1カラムで A→B 順に並べる
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (routeA != null)
                        _buildRouteCard(theme, routeA, isOdd: isOdd),
                      if (routeB != null) ...[
                        const SizedBox(height: 4),
                        _buildRouteCard(theme, routeB, isOdd: isOdd),
                      ],
                    ],
                  ),
                );
              }

              // 2カラム: 同番号を横に並べる
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: routeA != null
                          ? _buildRouteCard(theme, routeA, isOdd: isOdd)
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: routeB != null
                          ? _buildRouteCard(theme, routeB, isOdd: isOdd)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // 列見出し（branchA 名 / branchB 名）
  Widget _buildColumnHeaders(ThemeData theme, bool isSingle) {
    if (isSingle) {
      return _sectionHeader(theme, 'ルート一覧', Icons.route);
    }
    return Row(
      children: [
        Expanded(
          child: _columnHeaderBadge(theme, _selectedJob.branchA, 'a'),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _columnHeaderBadge(theme, _selectedJob.branchB, 'b'),
        ),
      ],
    );
  }

  Widget _columnHeaderBadge(ThemeData theme, String label, String type) {
    final color = type == 'a'
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    final onColor = type == 'a'
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: onColor,
        ),
      ),
    );
  }

  // ──────────── ルートカード（12px 基準） ────────────
  Widget _buildRouteCard(
    ThemeData theme,
    KokoroMichiRoute route, {
    bool isOdd = false,
  }) {
    final cardColor = isOdd
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surface;

    final routeNumStr = _toMaru(route.routeNo);
    var headerText = '${route.michi}$routeNumStr  Lv.${route.minLevel}以上';
    if (route.needsDarma) headerText += '\n＆ダーマ試練';

    return Card(
      color: cardColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ルートヘッダー（バッジ風）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                headerText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 6),

            if (route.kokoroList.isNotEmpty) ...[
              _kokoroWrap(theme, route.kokoroList),
              const SizedBox(height: 6),
            ],

            _bonusList(route.bonuses, fontSize: 12),
          ],
        ),
      ),
    );
  }

  // ──────────── 共通部品 ────────────

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // bonuses[0] がスキル名（数値記号を含まない）かどうか判定
  bool _isSkillName(String s) {
    const symbols = ['＋', '+', '％', '%', '−', '-', '＊'];
    return !symbols.any((ch) => s.contains(ch));
  }

  Widget _bonusList(List<String> bonuses, {double fontSize = 13}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bonuses.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        final isSkill = _isSkillName(b);
        final textStyle = isSkill
            ? const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4ABAE4),
                fontSize: 13,
              )
            : TextStyle(fontSize: fontSize);
        return Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('・', style: TextStyle(fontSize: fontSize)),
              Expanded(child: Text(b, style: textStyle)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _kokoroWrap(ThemeData theme, List<KokoroEntry> list) {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: list.map((k) {
        final label = k.isKakusei ? '★${k.name}' : k.name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: k.isKakusei
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: k.isKakusei
                  ? theme.colorScheme.onTertiaryContainer
                  : theme.colorScheme.onSecondaryContainer,
              fontWeight: k.isKakusei ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 整数 → 丸数字
  String _toMaru(int n) {
    const maruList = ['', '①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
    if (n >= 1 && n <= 10) return maruList[n];
    return n.toString();
  }
}
