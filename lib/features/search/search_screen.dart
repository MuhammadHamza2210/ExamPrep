import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../data/app_data.dart';

enum _ResultKind { university, course, topic }

class _Result {
  final _ResultKind kind;
  final String title;
  final String subtitle;
  final String route;
  const _Result(this.kind, this.title, this.subtitle, this.route);
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Result> _search(AppData data, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return [];
    final results = <_Result>[];

    for (final u in data.universities) {
      if (u.name.toLowerCase().contains(query) ||
          u.shortName.toLowerCase().contains(query) ||
          u.city.toLowerCase().contains(query)) {
        results.add(_Result(
            _ResultKind.university, u.shortName, u.city, '/university/${u.id}'));
      }
    }
    for (final c in data.courses) {
      if (c.name.toLowerCase().contains(query) ||
          c.code.toLowerCase().contains(query)) {
        final uni = data.university(c.universityId);
        results.add(_Result(_ResultKind.course, c.name,
            '${c.code} · ${uni?.shortName ?? ''}', '/course/${c.id}'));
      }
    }
    for (final t in data.topics) {
      if (t.name.toLowerCase().contains(query)) {
        final course = data.course(t.courseId);
        results.add(_Result(_ResultKind.topic, t.name,
            'Topic · ${course?.code ?? ''}', '/course/${t.courseId}'));
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final results = _search(data, _query);

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search,
                            size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: false,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'Courses, topics, universities…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(LucideIcons.x,
                                size: 18, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? const EmptyState(
                      icon: LucideIcons.search,
                      title: 'Search everything',
                      message:
                          'Find courses, high-priority topics and universities across Pakistan.',
                    )
                  : results.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.searchX,
                          title: 'No matches',
                          message: 'Try a different course code or topic.',
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 132),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              _ResultTile(result: results[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _Result result;
  const _ResultTile({required this.result});

  (IconData, Color) get _visual => switch (result.kind) {
        _ResultKind.university => (LucideIcons.building2, AppColors.primary),
        _ResultKind.course => (LucideIcons.bookOpen, AppColors.accent),
        _ResultKind.topic => (LucideIcons.trendingUp, const Color(0xFFF59E0B)),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(result.route),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(result.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
