import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import 'reminder_plan.dart';
import 'reminders.dart';

/// Settings tiles: end-of-day check and midday nudge, each with a time.
class ReminderTiles extends ConsumerWidget {
  const ReminderTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    String format(int minutes) =>
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );

    Future<bool> allowed() async {
      final messenger = ScaffoldMessenger.of(context);
      final ok =
          await ref.read(reminderSchedulerProvider)?.requestPermission() ??
          false;
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(l.remindersDenied)));
      }
      return ok;
    }

    Future<int?> pickTime(int minutes) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      return picked == null ? null : picked.hour * 60 + picked.minute;
    }

    Widget tile({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required bool enabled,
      required int minutes,
      required ReminderSettings Function(bool on) toggled,
      required ReminderSettings Function(int minutes) timed,
    }) => ListTile(
      key: key,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      // Tapping the row changes the time; the switch turns it on and off.
      onTap: () async {
        final m = await pickTime(minutes);
        if (m != null) await notifier.update(timed(m));
      },
      trailing: Switch(
        value: enabled,
        onChanged: (on) async {
          if (on && !await allowed()) return;
          await notifier.update(toggled(on));
        },
      ),
    );

    return Column(
      children: [
        tile(
          key: const ValueKey('reminder-evening'),
          icon: Icons.nights_stay_outlined,
          title: l.remindersEvening,
          subtitle: l.remindersEveningSub(format(settings.eveningMinutes)),
          enabled: settings.eveningEnabled,
          minutes: settings.eveningMinutes,
          toggled: (on) => settings.copyWith(eveningEnabled: on),
          timed: (m) => settings.copyWith(eveningMinutes: m),
        ),
        tile(
          key: const ValueKey('reminder-midday'),
          icon: Icons.wb_sunny_outlined,
          title: l.remindersMidday,
          subtitle: l.remindersMiddaySub(format(settings.middayMinutes)),
          enabled: settings.middayEnabled,
          minutes: settings.middayMinutes,
          toggled: (on) => settings.copyWith(middayEnabled: on),
          timed: (m) => settings.copyWith(middayMinutes: m),
        ),
      ],
    );
  }
}
