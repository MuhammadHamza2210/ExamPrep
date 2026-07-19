import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../app/theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';

class _Slide {
  final String title;
  final String description;
  final IconData icon;
  const _Slide(this.title, this.description, this.icon);
}

const _slides = [
  _Slide(
    'Find Notes Fast',
    'Browse quality notes shared by students across Pakistan — organised by university, course and chapter.',
    LucideIcons.fileText,
  ),
  _Slide(
    'Know What Matters',
    'See which topics have the highest chance of appearing, based on what really came in past papers.',
    LucideIcons.trendingUp,
  ),
  _Slide(
    'Study Smarter',
    'Short on time? Prioritise high-frequency topics first and walk into the exam prepared.',
    LucideIcons.zap,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(34),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s.icon,
                                size: 68, color: AppColors.primary),
                          )
                              .animate(key: ValueKey(index))
                              .scale(
                                  duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 44),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          )
                              .animate(key: ValueKey('t$index'))
                              .fadeIn(delay: 120.ms)
                              .slideY(begin: 0.25, end: 0),
                          const SizedBox(height: 16),
                          Text(
                            s.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          )
                              .animate(key: ValueKey('d$index'))
                              .fadeIn(delay: 220.ms)
                              .slideY(begin: 0.25, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _page == i ? 26 : 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: PrimaryButton(
                  label: _isLast ? 'Get Started' : 'Next',
                  icon: _isLast ? LucideIcons.arrowRight : null,
                  onPressed: () {
                    Haptics.select();
                    if (_isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
