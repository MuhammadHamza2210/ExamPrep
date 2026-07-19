import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:examprep/core/icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/topic.dart';

Color scoreColor(double score) {
  if (score >= 0.75) return AppColors.accent;
  if (score >= 0.5) return const Color(0xFFF59E0B);
  if (score >= 0.25) return const Color(0xFF3B82F6);
  return AppColors.textSecondary;
}

/// One row in the "Important Topics" list: rank + name + animated frequency
/// bar + a "came in my exam" vote button.
class TopicTile extends StatelessWidget {
  final int rank;
  final Topic topic;
  final VoidCallback onAppeared;
  final VoidCallback onNotAppeared;

  final bool? myVote;

  const TopicTile({
    super.key,
    required this.rank,
    required this.topic,
    required this.onAppeared,
    required this.onNotAppeared,
    this.myVote,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(topic.weightedScore);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$rank',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(topic.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15)),
              ),
              Text(
                '${topic.percent.round()}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                    height: 8,
                    color: color.withValues(alpha: 0.12)),
                FractionallySizedBox(
                  widthFactor: topic.weightedScore.clamp(0.02, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
                    .animate()
                    .scaleX(
                        begin: 0,
                        end: 1,
                        alignment: Alignment.centerLeft,
                        duration: 700.ms,
                        curve: Curves.easeOutCubic),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.totalVotes == 0
                          ? 'No votes yet'
                          : 'Appeared in ${topic.timesAppeared} of ${topic.totalVotes} exams',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (myVote != null)
                      Text(
                        myVote! ? '✓ You: came in exam' : '✓ You: didn\'t appear',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _voteButton(
                icon: LucideIcons.x,
                color: AppColors.textSecondary,
                filled: myVote == false,
                onTap: onNotAppeared,
              ),
              const SizedBox(width: 8),
              _voteButton(
                icon: LucideIcons.check,
                color: AppColors.accent,
                filled: true,
                label: 'Came in exam',
                onTap: onAppeared,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voteButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
    String? label,
  }) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: label == null ? 8 : 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 15, color: filled ? Colors.white : color),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: filled ? Colors.white : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Radar chart of the top topics' likelihood; animates in from centre.
class TopicRadarChart extends StatefulWidget {
  final List<Topic> topics;
  const TopicRadarChart({super.key, required this.topics});

  @override
  State<TopicRadarChart> createState() => _TopicRadarChartState();
}

class _TopicRadarChartState extends State<TopicRadarChart> {
  bool _grown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.topics.take(6).toList();
    if (top.length < 3) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Likelihood radar',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Top topics by exam-appearance score',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.22),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: top
                        .map((t) => RadarEntry(
                            value: _grown ? (t.weightedScore * 100) : 0))
                        .toList(),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                tickCount: 4,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 1),
                tickBorderData: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.15)),
                gridBorderData: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    width: 1),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.14,
                getTitle: (index, angle) => RadarChartTitle(
                  text: _shortLabel(top[index].name),
                ),
                titleTextStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
              swapAnimationDuration: const Duration(milliseconds: 700),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  String _shortLabel(String name) =>
      name.length <= 14 ? name : '${name.substring(0, 12)}…';
}
