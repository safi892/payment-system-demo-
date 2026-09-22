import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../widgets/placard_label.dart';

/// Panel preferences. Toggles are local state in this phase; the night
/// panel (dark mode) is fixed by the design and cannot be turned off.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometric = false;
  bool _dataSaver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.luminous,
        elevation: 0,
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PlacardLabel(
              'PREFERENCES',
              size: 10,
              spacing: 2,
              color: AppColors.faint,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              icon: Icons.notifications_none_rounded,
              title: AppStrings.settingsNotifications,
              body: AppStrings.settingsNotificationsBody,
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            _toggleTile(
              icon: Icons.fingerprint_rounded,
              title: AppStrings.settingsBiometric,
              body: AppStrings.settingsBiometricBody,
              value: _biometric,
              onChanged: (v) => setState(() => _biometric = v),
            ),
            _toggleTile(
              icon: Icons.dark_mode_outlined,
              title: AppStrings.settingsDark,
              body: AppStrings.settingsDarkBody,
              value: true,
              onChanged: null,
            ),
            _toggleTile(
              icon: Icons.data_saver_on_rounded,
              title: AppStrings.settingsDataSaver,
              body: AppStrings.settingsDataSaverBody,
              value: _dataSaver,
              onChanged: (v) => setState(() => _dataSaver = v),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.radium,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      AppStrings.aboutBody,
                      style: TextStyle(
                        color: AppColors.dim,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlacardLabel(
                  '${AppStrings.version}  1.0.0',
                  size: 9.5,
                  spacing: 1.6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String body,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.radium),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.luminous,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.faint,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.radium,
              activeTrackColor: AppColors.radiumSoft,
              inactiveTrackColor: AppColors.hairline,
              inactiveThumbColor: AppColors.dim,
            ),
          ],
        ),
      ),
    );
  }
}
