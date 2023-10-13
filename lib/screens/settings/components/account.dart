import 'package:fleeting_notes_flutter/screens/settings/components/click_button_with_delay.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/delete_account_widget.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/update_phone_widget.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Account extends ConsumerStatefulWidget {
  const Account({
    Key? key,
    required this.email,
    required this.onLogout,
    required this.onForceSync,
    required this.onDeleteAccount,
    required this.onEnableEncryption,
  }) : super(key: key);

  final String email;
  final VoidCallback onLogout;
  final VoidCallback onForceSync;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEnableEncryption;

  @override
  ConsumerState<Account> createState() => _AccountState();
}

class _AccountState extends ConsumerState<Account> {
  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseProvider);
    final phone = supabase.currUser?.phone ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          name: 'Email',
          description: supabase.currUser?.email ?? '',
          actions: [
            ElevatedButton(
                onPressed: widget.onLogout, child: const Text('Logout'))
          ],
        ),
        SettingsItem(
          name: 'Force Sync',
          description: 'Sync notes from the cloud to the device',
          actions: [
            ClickButtonWithDelay(
                onPressed: widget.onForceSync, buttonText: 'Force Sync')
          ],
        ),
        SettingsItem(
          name: 'End-to-end Encryption',
          description: 'Encrypt notes with end-to-end encryption',
          actions: [
            ElevatedButton(
                onPressed: widget.onEnableEncryption,
                child: Text(
                    (widget.onEnableEncryption == null) ? 'Enabled' : 'Enable'))
          ],
        ),
        SettingsItem(
          name: 'Update Phone Number',
          description: (phone.isEmpty)
              ? 'Phone number is used to create notes from calls or texts'
              : phone,
          actions: [
            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => UpdatePhoneWidget(
                        onPhoneUpdated: () => setState(() => {})),
                  );
                },
                child: const Text('Update Phone')),
          ],
        ),
        SettingsItem(
          name: 'Delete Account',
          description: 'Delete your account and all your notes',
          actions: [
            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        DeleteAccountWidget(onDelete: widget.onDeleteAccount),
                  );
                },
                child: const Text('Delete')),
          ],
        ),
      ],
    );
  }
}
