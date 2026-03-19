import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/synthwave_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String githubUrl = 'https://github.com/synthalorian/OpenLife';
  static const String buyMeCoffeeUrl = 'https://www.buymeacoffee.com/synthalorian';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Support Section
          Text(
            'Support Development',
            style: theme.textTheme.titleMedium?.copyWith(
              color: SynthwaveColors.neonPink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Buy Me a Coffee
          _buildSettingCard(
            context: context,
            icon: Icons.coffee,
            iconColor: const Color(0xFFFF6B35),
            title: 'Buy Me a Coffee',
            subtitle: 'Support development with a donation',
            onTap: () => _launchUrl(context, buyMeCoffeeUrl),
          ),
          
          const SizedBox(height: 12),
          
          // Open Source
          _buildSettingCard(
            context: context,
            icon: Icons.code,
            iconColor: Colors.white,
            title: 'Open Source',
            subtitle: 'View source code on GitHub',
            onTap: () => _launchUrl(context, githubUrl),
          ),
          
          const SizedBox(height: 32),
          
          // About Section
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              color: SynthwaveColors.neonPink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildAboutCard(context),
          
          const SizedBox(height: 32),
          
          // App Description
          _buildAppCard(context),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: SynthwaveColors.neonPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: SynthwaveColors.neonPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAboutRow(
              context: context,
              icon: Icons.info_outline,
              label: 'Version',
              value: '1.0.0',
            ),
            const Divider(height: 24),
            _buildAboutRow(
              context: context,
              icon: Icons.code,
              label: 'Built with',
              value: 'Flutter & ❤️',
            ),
            const Divider(height: 24),
            _buildAboutRow(
              context: context,
              icon: Icons.palette,
              label: 'Theme',
              value: 'Synthwave',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, color: SynthwaveColors.neonCyan, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: SynthwaveColors.neonPink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF0080), Color(0xFF8B00FF)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Open Life',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The ultimate AI-powered life management app\n100% free and open source',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildChip(context, 'Fitness', const Color(0xFF00FF88)),
                _buildChip(context, 'Finance', const Color(0xFFFFD700)),
                _buildChip(context, 'Health', const Color(0xFF00B8FF)),
                _buildChip(context, 'AI', const Color(0xFF00FFFF)),
                _buildChip(context, 'Free', const Color(0xFF00FF88)),
                _buildChip(context, 'Open Source', const Color(0xFF8B00FF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
