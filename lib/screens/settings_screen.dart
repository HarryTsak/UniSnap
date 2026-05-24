import 'package:flutter/material.dart';
import '../global_state.dart';
import '../services/helpers.dart';
import '../services/notification_service.dart';

// -------------------------------------------------------------
// ΟΘΟΝΗ 3: ΡΥΘΜΙΣΕΙΣ (Settings Screen)
// -------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoDelete = false;
  String selectedLanguage = 'Αυτόματο';

  Widget _buildSmartRecognitionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueGrey),
            title: const Text("Γλώσσα Κειμένου"),
            subtitle: Text(selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                selectedLanguage = selectedLanguage == 'Αυτόματο' ? 'Ελληνικά' : 'Αυτόματο';
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            activeColor: Colors.cyan,
            secondary: const Icon(Icons.event_available, color: Colors.blueGrey),
            title: const Text("Αυτόματη Υπενθύμιση"),
            subtitle: Text(
              autoReminderEnabled.value
                  ? "1 ημέρα πριν την προθεσμία"
                  : "Απενεργοποιημένη",
            ),
            value: autoReminderEnabled.value,
            onChanged: (value) async {
              setState(() {});
              autoReminderEnabled.value = value;
              await saveAutoReminder(value);

              // If disabled, cancel all pending notifications
              if (!value) {
                await NotificationService.instance.cancelAllNotifications();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            activeColor: Colors.cyan,
            secondary: const Icon(Icons.dark_mode_outlined, color: Colors.blueGrey),
            title: const Text("Σκοτεινή Εμφάνιση"),
            value: isDarkModeNotifier.value,
            onChanged: (value) {
              setState(() {});
              isDarkModeNotifier.value = value;
              saveTheme(value);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            activeColor: Colors.redAccent,
            secondary: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            title: const Text("Καθαρισμός Χώρου"),
            subtitle: const Text("Διαγραφή Snaps > 6 μήνες"),
            value: autoDelete,
            onChanged: (value) => setState(() => autoDelete = value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Ρυθμίσεις', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
            child: Text("ΕΞΥΠΝΗ ΑΝΑΓΝΩΡΙΣΗ", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          ),
          _buildSmartRecognitionCard(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text("ΣΥΣΤΗΜΑ", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          ),
          _buildSystemCard(),
        ],
      ),
    );
  }
}
