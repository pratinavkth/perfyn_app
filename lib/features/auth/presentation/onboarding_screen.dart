import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/auth/presentation/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go(LoginScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  _OnboardingPage(
                    title: 'Welcome to Perfyn',
                    subtitle: 'Your personal finance buddy. Track your expenses and income with complete privacy.',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.ocean,
                  ),
                  _OnboardingPage(
                    title: 'Achieve your Goals',
                    subtitle: 'Set up visual progress rings for savings, or lock down your spending with No-Spend Challenges.',
                    icon: Icons.track_changes_rounded,
                    iconColor: AppColors.mint,
                  ),
                  _OnboardingPage(
                    title: 'Always Available',
                    subtitle: 'Built with an offline-first architecture. Log transactions anywhere, and sync automatically.',
                    icon: Icons.offline_bolt_rounded,
                    iconColor: AppColors.coral,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.ocean
                              : AppColors.slate.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Navigation button
                  _currentPage == 2
                      ? ElevatedButton(
                          onPressed: _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Get Started'),
                        )
                      : TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
