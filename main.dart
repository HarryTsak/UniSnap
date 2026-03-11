import 'package:flutter/material.dart';

// --- ΑΥΤΗ ΕΙΝΑΙ Η ΠΑΓΚΟΣΜΙΑ ΜΝΗΜΗ ΤΗΣ ΕΦΑΡΜΟΓΗΣ ΜΑΣ ---
List<Map<String, dynamic>> globalUserTopics = [];

void main() {
  runApp(const UniSnapApp());
}

class UniSnapApp extends StatelessWidget {
  const UniSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ΕΔΩ Η ΑΛΛΑΓΗ: Το δικό σου HEX χρώμα #9E9797
      backgroundColor: const Color(0xFF9E9797),
      body: SafeArea(
        child: Stack(
          children: [
            // -----------------------------------------
            // 1. Το Τεράστιο Κουμπί της Κάμερας (Κέντρο)
            // -----------------------------------------
            Center(
              child: InkWell(
                onTap: () {
                  print("📸 Κλικ! Άνοιγμα Κάμερας...");
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 160,
                    color: Color(0xFF2D2D2D), // Σκούρο γκρι εικονίδιο
                  ),
                ),
              ),
            ),

            // -----------------------------------------
            // 2. Το Αιωρούμενο Μενού (Πάνω Αριστερά)
            // -----------------------------------------
            Positioned(
              top: 30,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.cyan, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(25, 8, 123, 211),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.menu_open, color: Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  offset: const Offset(60, 0),
                  onSelected: (value) {
                    if (value == 'gallery') {
                      print("📂 Πάμε στο Gallery!");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GalleryScreen(),
                        ),
                      );
                    } else if (value == 'settings') {
                      print("⚙️ Πάμε στις Ρυθμίσεις!");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'gallery',
                      child: Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 12),
                          Text("Η Συλλογή μου"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: Colors.black54),
                          SizedBox(width: 12),
                          Text("Ρυθμίσεις"),
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
}

// -------------------------------------------------------------
// ΟΘΟΝΗ ΡΥΘΜΙΣΕΩΝ (Settings Screen)
// -------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Μεταβλητές για να "δουλεύουν" οι διακόπτες (οπτικά)
  bool autoReminder = true;
  bool autoDelete = false;
  bool darkMode = false;
  String selectedLanguage = 'Αυτόματο';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Το ίδιο background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // Κουμπί επιστροφής
        ),
        title: const Text(
          'Ρυθμίσεις',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ΕΝΟΤΗΤΑ 1: ΕΞΥΠΝΗ ΑΝΑΓΝΩΡΙΣΗ (OCR)
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
            child: Text(
              "ΕΞΥΠΝΗ ΑΝΑΓΝΩΡΙΣΗ",
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blueGrey),
                  title: const Text("Γλώσσα Κειμένου"),
                  subtitle: Text(selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Εδώ θα άνοιγε ένα μενού επιλογής, προς το παρόν το αλλάζουμε απλά
                    setState(() {
                      selectedLanguage = selectedLanguage == 'Αυτόματο'
                          ? 'Ελληνικά'
                          : 'Αυτόματο';
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: Colors.cyan,
                  secondary: const Icon(
                    Icons.event_available,
                    color: Colors.blueGrey,
                  ),
                  title: const Text("Αυτόματη Υπενθύμιση"),
                  subtitle: const Text("1 ημέρα πριν την προθεσμία"),
                  value: autoReminder,
                  onChanged: (value) => setState(() => autoReminder = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ΕΝΟΤΗΤΑ 2: ΣΥΣΤΗΜΑ & ΧΩΡΟΣ
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              "ΣΥΣΤΗΜΑ",
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Colors.cyan,
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                    color: Colors.blueGrey,
                  ),
                  title: const Text("Σκοτεινή Εμφάνιση"),
                  value: darkMode,
                  onChanged: (value) => setState(() => darkMode = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: Colors.redAccent,
                  secondary: const Icon(
                    Icons.delete_sweep,
                    color: Colors.redAccent,
                  ),
                  title: const Text("Καθαρισμός Χώρου"),
                  subtitle: const Text("Διαγραφή Snaps > 6 μήνες"),
                  value: autoDelete,
                  onChanged: (value) => setState(() => autoDelete = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// ΟΘΟΝΗ ΣΥΛΛΟΓΗΣ (Gallery Screen)
// -------------------------------------------------------------
// -------------------------------------------------------------
// ΟΘΟΝΗ ΣΥΛΛΟΓΗΣ (Gallery Screen - Topics)
// -------------------------------------------------------------
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Λίστα με τα μαθήματα (ξεκινάει άδεια!)
  // EXO VALEI MIA STATIC VARIABLE GIA NA APOTHIKEUONTAI

  // Controller για να διαβάζουμε τι γράφει ο χρήστης στο πεδίο κειμένου
  final TextEditingController _topicController = TextEditingController();

  // Συνάρτηση που πετάει το Pop-up (Dialog) για να γράψεις νέο μάθημα
  void _showAddTopicDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Νέο Μάθημα"),
          content: TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              hintText: "π.χ. Βάσεις Δεδομένων",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.cyan, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _topicController.clear();
                Navigator.pop(context); // Κλείσιμο χωρίς αποθήκευση
              },
              child: const Text(
                "Ακύρωση",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_topicController.text.isNotEmpty) {
                  // Αποθήκευση του νέου μαθήματος στη λίστα!
                  setState(() {
                    globalUserTopics.add({
                      "course": _topicController.text,
                      "snaps": 0, // Ξεκινάει με 0 φωτογραφίες
                    });
                  });
                  _topicController.clear();
                  Navigator.pop(context); // Κλείσιμο Pop-up
                }
              },
              child: const Text(
                "Δημιουργία",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Οι Φάκελοί μου',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),

      // Η ΜΑΓΕΙΑ: Ελέγχουμε αν η λίστα είναι άδεια.
      // Αν ναι, δείχνουμε το Empty State. Αν όχι, δείχνουμε το Grid!
      body: globalUserTopics.isEmpty ? _buildEmptyState() : _buildTopicsGrid(),

      // Μικρό αιωρούμενο κουμπί κάτω δεξιά (εμφανίζεται μόνο αν έχεις ήδη φτιάξει 1 μάθημα τουλάχιστον)
      floatingActionButton: globalUserTopics.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddTopicDialog,
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.create_new_folder, color: Colors.white),
            )
          : null,
    );
  }

  // -------------------------------------------------------------
  // UI 1: EMPTY STATE (Όταν δεν υπάρχουν μαθήματα)
  // -------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              size: 100,
              color: Color(0xFF9E9797), // Το σκούρο γκρι σου
            ),
            const SizedBox(height: 20),
            const Text(
              "Δεν έχεις προσθέσει κανένα μάθημα.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Φτιάξε φακέλους για να οργανώνεις τα snaps σου (π.χ. Διαφάνειες, Ανακοινώσεις).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            // Το Τεράστιο Κουμπί στο κέντρο!
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: _showAddTopicDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Δημιουργία Μαθήματος",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // UI 2: GRID (Όταν υπάρχουν μαθήματα)
  // -------------------------------------------------------------
  Widget _buildTopicsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0, // Τετράγωνοι φάκελοι
        ),
        itemCount: globalUserTopics.length,
        itemBuilder: (context, index) {
          final topic = globalUserTopics[index];
          return InkWell(
            onTap: () {
              print("Άνοιγμα φακέλου: ${topic['course']}");
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(15, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_shared_outlined,
                    size: 48,
                    color: Colors.cyan,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      topic['course'], // Το όνομα που έγραψε ο χρήστης!
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${topic['snaps']} Snaps",
                    style: const TextStyle(
                      color: Color(0xFF9E9797),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
