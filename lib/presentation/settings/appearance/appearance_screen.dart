import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/modern_widgets.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'THEME MODE',
              child: GlassmorphicContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildThemeOption(
                      context,
                      'System Default',
                      Iconsax.setting_2,
                      ThemeMode.system,
                      themeProvider,
                    ),
                    _buildDivider(isDark),
                    _buildThemeOption(
                      context,
                      'Light Mode',
                      Iconsax.sun_1,
                      ThemeMode.light,
                      themeProvider,
                    ),
                    _buildDivider(isDark),
                    _buildThemeOption(
                      context,
                      'Dark Mode',
                      Iconsax.moon,
                      ThemeMode.dark,
                      themeProvider,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'ACCENT COLOR',
              child: GlassmorphicContainer(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildColorCircle(context, AppColors.primary, true),
                    _buildColorCircle(context, Colors.blue, false),
                    _buildColorCircle(context, AppColors.emerald, false),
                    _buildColorCircle(context, Colors.amber, false),
                    _buildColorCircle(context, AppColors.rose, false),
                    _buildColorCircle(context, Colors.indigo, false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'TEXT SCALING',
              child: GlassmorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Slider(
                      value: 1.0,
                      min: 0.8,
                      max: 1.4,
                      onChanged: (v) {},
                      activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Small', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Normal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Large', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              letterSpacing: 1.2,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon,
      ThemeMode mode, ThemeProvider provider) {
    final isSelected = provider.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: isSelected ? Icon(Iconsax.tick_circle, color: primaryColor) : null,
      onTap: () => provider.setThemeMode(mode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
    );
  }

  Widget _buildColorCircle(BuildContext context, Color color, bool isSelected) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
    );
  }
}
