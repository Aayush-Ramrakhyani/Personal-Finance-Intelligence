import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_screen.dart';

// Simple local settings state
class AppSettings {
  final bool budgetAlerts;
  final bool weeklyInsights;
  final bool recurringReminders;
  final bool importNotifications;
  final String currency;
  final String defaultAccount;

  const AppSettings({
    this.budgetAlerts = true,
    this.weeklyInsights = true,
    this.recurringReminders = true,
    this.importNotifications = true,
    this.currency = 'INR',
    this.defaultAccount = '',
  });

  AppSettings copyWith({
    bool? budgetAlerts,
    bool? weeklyInsights,
    bool? recurringReminders,
    bool? importNotifications,
    String? currency,
    String? defaultAccount,
  }) {
    return AppSettings(
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      weeklyInsights: weeklyInsights ?? this.weeklyInsights,
      recurringReminders: recurringReminders ?? this.recurringReminders,
      importNotifications: importNotifications ?? this.importNotifications,
      currency: currency ?? this.currency,
      defaultAccount: defaultAccount ?? this.defaultAccount,
    );
  }
}

final appSettingsProvider =
    StateProvider<AppSettings>((ref) => const AppSettings());

// Stub auth provider
final userEmailProvider =
    Provider<String>((ref) => 'user@example.com');
final userNameProvider =
    Provider<String>((ref) => 'Finance User');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          _SectionCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF40C4FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  userEmail,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: Color(0xFF00C896), size: 20),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // App settings
          _SettingsSection(
            title: 'App Settings',
            children: [
              _SettingsTile(
                icon: Icons.currency_rupee_rounded,
                label: 'Currency',
                trailing: _DropdownTile(
                  value: settings.currency,
                  options: const ['INR', 'USD', 'EUR', 'GBP'],
                  onChanged: (v) => ref
                      .read(appSettingsProvider.notifier)
                      .update((s) => s.copyWith(currency: v)),
                ),
              ),
              _SettingsTile(
                icon: Icons.account_balance_rounded,
                label: 'Default Account',
                subtitle: settings.defaultAccount.isEmpty
                    ? 'Not set'
                    : settings.defaultAccount,
                onTap: () => _showAccountPicker(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notification preferences
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SwitchTile(
                icon: Icons.warning_rounded,
                iconColor: const Color(0xFFFF5252),
                label: 'Budget Alerts',
                subtitle: 'Alert when budget threshold exceeded',
                value: settings.budgetAlerts,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update((s) => s.copyWith(budgetAlerts: v)),
              ),
              _SwitchTile(
                icon: Icons.lightbulb_rounded,
                iconColor: const Color(0xFFFFC107),
                label: 'Weekly Insights',
                subtitle: 'AI-powered financial insights',
                value: settings.weeklyInsights,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update((s) => s.copyWith(weeklyInsights: v)),
              ),
              _SwitchTile(
                icon: Icons.repeat_rounded,
                iconColor: const Color(0xFF40C4FF),
                label: 'Recurring Reminders',
                subtitle: 'Remind before upcoming recurring payments',
                value: settings.recurringReminders,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update((s) => s.copyWith(recurringReminders: v)),
              ),
              _SwitchTile(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF00C896),
                label: 'Import Notifications',
                subtitle: 'Notify when CSV import completes',
                value: settings.importNotifications,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .update(
                        (s) => s.copyWith(importNotifications: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'App Version',
                subtitle: '1.0.0 (Build 1)',
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_rounded,
                label: 'Privacy Policy',
                onTap: () {},
                showArrow: true,
              ),
              _SettingsTile(
                icon: Icons.description_rounded,
                label: 'Terms of Service',
                onTap: () {},
                showArrow: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: Color(0xFFFF5252)),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFFFF5252), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAccountPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Default Account',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connect your accounts first from the\nAccounts section.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // Navigate to auth screen (handled by router in real app)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

// ---------------------------------------------------------------------------
// Settings widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF00C896), size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12),
            )
          : null,
      trailing: trailing ??
          (showArrow
              ? const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 20)
              : null),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style:
            const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00C896),
        activeTrackColor:
            const Color(0xFF00C896).withOpacity(0.3),
        inactiveThumbColor: Colors.white54,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownTile({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: const Color(0xFF252B45),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.expand_more_rounded,
          color: Colors.white54, size: 18),
      items: options.map((o) {
        return DropdownMenuItem(value: o, child: Text(o));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
