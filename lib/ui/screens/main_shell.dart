import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/synthwave_theme.dart';
import '../../features/health/presentation/health_screen.dart';
import '../../features/metrics/presentation/metrics_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/workouts/presentation/workouts_screen.dart';
import '../../features/settings/settings_page.dart';

/// Main navigation shell with bottom nav
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final _screens = [
    const _DashboardScreen(),
    const WorkoutsScreen(),
    const NutritionScreen(),
    const HealthScreen(),
    const MetricsScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(
              painter: SynthwaveGridPainter(),
            ),
          ),
          // Content
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: SynthwaveColors.surface,
        indicatorColor: SynthwaveColors.neonPink.withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Metrics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens - will be expanded into full features

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPEN LIFE',
              style: SynthwaveTextStyles.displayLarge(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Your health, your data, your way.',
              style: SynthwaveTextStyles.bodyMedium(context).copyWith(
                color: SynthwaveColors.neonCyan.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            
            // Quick stats cards
            _buildStatCard(
              context,
              title: 'Today\'s Workout',
              value: 'Push Day',
              subtitle: 'Chest, Shoulders, Triceps',
              icon: Icons.fitness_center,
              color: SynthwaveColors.neonPink,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Calories',
              value: '1,847 / 2,200',
              subtitle: '353 remaining',
              icon: Icons.local_fire_department,
              color: SynthwaveColors.neonOrange,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Protein',
              value: '142g / 180g',
              subtitle: '38g remaining',
              icon: Icons.set_meal,
              color: SynthwaveColors.neonCyan,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Glucose',
              value: '98 mg/dL',
              subtitle: 'Fasting - Normal range',
              icon: Icons.bloodtype,
              color: SynthwaveColors.neonPurple,
            ),
            const SizedBox(height: 32),
            
            // Coming soon section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SynthwaveColors.neonPink.withOpacity(0.2),
                    SynthwaveColors.neonPurple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SynthwaveColors.gridLine),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    color: SynthwaveColors.neonYellow,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UNDER CONSTRUCTION',
                    style: SynthwaveTextStyles.labelLarge(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This app is being built in the neon grid.\nCheck back soon for updates.',
                    textAlign: TextAlign.center,
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SynthwaveTextStyles.labelMedium(context),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: SynthwaveTextStyles.bodyLarge(context),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: SynthwaveTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionScreen extends StatelessWidget {
  const _NutritionScreen();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Nutrition',
      icon: Icons.restaurant,
      description: 'Macro tracking, meal logging, recipes, and barcode scanning.',
    );
  }
}

class _MetricsScreen extends StatelessWidget {
  const _MetricsScreen();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Body Metrics',
      icon: Icons.monitor_weight,
      description: 'Weight tracking, measurements, body fat, and progress photos.',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: SynthwaveColors.neonCyan,
              ),
              const SizedBox(height: 24),
              Text(
                title.toUpperCase(),
                style: SynthwaveTextStyles.displayMedium(context),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: SynthwaveTextStyles.bodyMedium(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
