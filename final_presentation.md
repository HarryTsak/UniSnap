# UniSnap - Τελική Παρουσίαση Έργου (Final Project Presentation)

Αυτός ο οδηγός αποτελεί το πλήρες σενάριο και τις διαφάνειες της τελικής παρουσίασης της εφαρμογής **UniSnap**, με **ενσωματωμένα αποσπάσματα κώδικα (code snippets)** για κάθε τεχνική διαφάνεια ώστε να συνδεθεί άμεσα η θεωρία με την τελική υλοποίηση.

---

````carousel
# Διαφάνεια 1: Τίτλος & Ταυτότητα Έργου

## **UniSnap**
### *Έξυπνη Οργάνωση & Διαχείριση Ακαδημαϊκών Σημειώσεων με AI*

![UniSnap Logo](https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop)

* **Σκοπός:** Η διευκόλυνση των φοιτητών στην άμεση φωτογράφιση, ψηφιοποίηση, οργάνωση σε φακέλους, εξαγωγή κειμένου (OCR) και αυτόματη υπενθύμιση προθεσμιών.
* **Βασικό Σύνθημα:** *Snap, Save, Study — Χωρίς Άγχος.*

<!-- slide -->
# Διαφάνεια 2: Βασικές Λειτουργίες της Εφαρμογής

Η εφαρμογή UniSnap προσφέρει μια ολοκληρωμένη και αποδοτική ροή εργασίας:

### 1. Ακαριαία Λήψη & Αποθήκευση (Instant Post-Snap Flow)
```dart
// camera_screen.dart (Lines 38-57)
void _processCameraImage(String path) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GalleryScreen(
        imagePathToSave: path,
        ocrTextToSave: "", // Instant saving, OCR is on-demand later
      ),
    ),
  );
}
```

### 2. Αυτόματο Κλείσιμο Παραθύρων (Automatic Window Dismissal)
```dart
// gallery_screen.dart (Lines 83-108)
if (widget.imagePathToSave != null) {
  setState(() {
    globalUserTopics.add({
      "course": courseName,
      "images": <Map<String, String>>[{"path": widget.imagePathToSave!, "text": widget.ocrTextToSave ?? ""}]
    });
  });
  await saveData();
  _scheduleRemindersIfNeeded(widget.ocrTextToSave ?? "", courseName);
  Navigator.pop(context); // Κλείσιμο Add Dialog
  Navigator.pop(context); // Αυτόματο κλείσιμο GalleryScreen -> Επιστροφή στην κάμερα!
}
```

<!-- slide -->
# Διαφάνεια 3: Τεχνολογίες (Technology Stack)

Η εφαρμογή αναπτύχθηκε με γνώμονα τη φορητότητα, την ταχύτητα και την ασφάλεια των δεδομένων:

### Persistence & State Management
```dart
// global_state.dart (Lines 4-6)
List<Map<String, dynamic>> globalUserTopics = [];
List<Map<String, dynamic>> globalUserNotes = []; // custom Note Collection database
```
```dart
// helpers.dart (Lines 47-60) - Load & Save JSON data locally via SharedPreferences
Future<void> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? topicsString = prefs.getString('savedTopics');
  if (topicsString != null) globalUserTopics = _parseTopics(jsonDecode(topicsString));
  
  final String? notesString = prefs.getString('savedNotes');
  if (notesString != null) globalUserNotes = List<Map<String, dynamic>>.from(jsonDecode(notesString));
}
```

<!-- slide -->
# Διαφάνεια 4: Σχεδιαστικές Επιλογές & UI/UX

Η διεπαφή χρήστη (User Interface) σχεδιάστηκε για να προσφέρει μια premium, σύγχρονη αίσθηση:

### Notepad View Inline Edit Mode
```dart
// note_view_screen.dart (Lines 180-205) - Lined warm yellow pad & inline TextField
_isEditing
    ? TextField(
        controller: _textController,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        autofocus: true,
        style: TextStyle(fontSize: 16.0, height: 1.6, color: isDark ? Colors.white : Colors.black87),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Γράψτε εδώ...",
        ),
      )
    : SelectableText(
        _currentContent,
        style: TextStyle(fontSize: 16.0, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
      ),
```

<!-- slide -->
# Διαφάνεια 5: Ενσωμάτωση Υπολογιστικής Όρασης (Computer Vision)

Το UniSnap ενσωματώνει έναν πλήρη αγωγό (pipeline) Υπολογιστικής Όρασης για την ψηφιοποίηση εγγράφων:

### 1. Προεπεξεργασία Εικόνας σε Background Isolate
```dart
// helpers.dart (Lines 78-86)
img.Image _preprocessIsolate(img.Image source) {
  img.grayscale(source); // 1. Grayscale
  img.contrast(source, contrast: 150); // 2. Contrast boost
  // 3. Sharpen (3x3 Convolution filter)
  img.convolution(source, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1);
  return source;
}
```

### 2. On-Device Text Recognition (Google ML Kit)
```dart
// helpers.dart (Lines 114-119)
final inputImage = InputImage.fromFilePath(processedPath);
final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
final extractedText = recognizedText.text;
textRecognizer.close();
```

<!-- slide -->
# Διαφάνεια 6: Ενσωμάτωση Επεξεργασίας Φυσικής Γλώσσας (NLP)

Μετά την εξαγωγή του κειμένου, το UniSnap χρησιμοποιεί τεχνικές NLP για να βοηθήσει τον φοιτητή να μην χάσει καμία προθεσμία εργασίας:

### 1. Custom Date Extraction Engine (`date_extractor.dart`)
```dart
// date_extractor.dart (Lines 15-30) - Regex patterns supporting Greek and English months
final patterns = [
  RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b'), // DD/MM/YYYY
  RegExp(r'\b(\d{1,2})\s+(Ιανουαρίου|Φεβρουαρίου|...|Δεκεμβρίου)\s*(\d{4})?', caseSensitive: false),
  RegExp(r'\b(\d{1,2})\s+(January|February|...|December)\s*(\d{4})?', caseSensitive: false),
];
```

### 2. Αυτόματη Υπενθύμιση (Local Push Notifications)
```dart
// notification_service.dart (Lines 132-154) - Programmed exactly 1 day before deadline at 09:00 AM
await _plugin!.zonedSchedule(
  id,
  'UniSnap Υπενθύμιση: $courseName',
  'Η προθεσμία λήγει αύριο στις $dateString! ⏰',
  tz.TZDateTime.from(scheduledDate, tz.local),
  const NotificationDetails(...),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
);
```

<!-- slide -->
# Διαφάνεια 7: Εξέλιξη, Δυσκολίες & Cumulative Evaluation

### 📈 Πορεία Ανάπτυξης
Το έργο εξελίχθηκε από μια απλή ιδέα κάμερας σε έναν ολοκληρωμένο «βοηθό μελέτης».

### ⚠️ Βασικές Δυσκολίες & Λύσεις:
1. **Αρχικό UI Lag κατά το OCR:** Η επεξεργασία μεγάλων εικόνων καθυστερούσε τη ροή.
   * *Λύση:* Αποσυνδέσαμε το post-snap από το OCR. Η αποθήκευση γίνεται **ακαριαία** και το OCR εκτελείται χειροκίνητα με το πάτημα ενός κουμπιού (On-Demand OCR) όταν ο χρήστης βλέπει την εικόνα.
2. **LateInitialization Errors στις Ειδοποιήσεις:** Προβλήματα αρχικοποίησης του plugin σε emulators.
   * *Λύση:* Πλήρης θωράκιση του `NotificationService` με defensive code, try-catch blocks και dynamic null checks.

### 🎯 Βαθμός Επίτευξης Στόχων: **100%**
* Επιτεύχθηκε πλήρως η instant αποθήκευση, η οργάνωση φωτογραφιών & σημειώσεων, η σάρωση OCR, η αντιγραφή, η inline επεξεργασία σημειώσεων και η αυτόματη ειδοποίηση προθεσμιών.
````

---

## 📝 Σενάριο Παρουσίασης ανά Διαφάνεια με αναφορά στον Κώδικα (Speech Notes)

### **Διαφάνεια 1: Εισαγωγή**
> *"Καλή σας ημέρα. Σήμερα θα σας παρουσιάσω το UniSnap, μια εφαρμογή που σχεδιάστηκε με σκοπό να λύσει ένα καθημερινό πρόβλημα κάθε φοιτητή: την οργάνωση του χαοτικού υλικού των διαλέξεων. Το UniSnap δεν είναι απλώς μια κάμερα· είναι ένας έξυπνος βοηθός μελέτης που συνδυάζει Υπολογιστική Όραση και Επεξεργασία Φυσικής Γλώσσας για να κρατάει τον φοιτητή οργανωμένο και εντός προθεσμιών."*

### **Διαφάνεια 2: Βασικές Λειτουργίες**
> *"Όπως βλέπουμε στο πρώτο απόσπασμα κώδικα από το `camera_screen.dart`, η λήψη της φωτογραφίας οδηγεί ακαριαία τον χρήστη στη Συλλογή (Gallery) σε Save Mode, στέλνοντας άδειο κείμενο OCR για να αποφευχθεί κάθε καθυστέρηση. Στο δεύτερο απόσπασμα από το `gallery_screen.dart`, βλέπουμε πώς υλοποιήσαμε το Automatic Window Dismissal: με το που πατηθεί η δημιουργία νέου μαθήματος και αποθηκευτεί το snap, η εφαρμογή καλεί δύο συνεχόμενα `Navigator.pop`, κλείνοντας αυτόματα το διάλογο και τη συλλογή, επιστρέφοντας τον φοιτητή κατευθείαν στην κάμερα."*

### **Διαφάνεια 3: Τεχνολογίες (Technology Stack)**
> *"Για την υλοποίηση επιλέξαμε το Flutter της Google. Στο απόσπασμα κώδικα βλέπουμε τη δομή της τοπικής μας βάσης δεδομένων: `globalUserTopics` για τις φωτογραφίες και `globalUserNotes` για τις σημειώσεις μας. Όλα αυτά γίνονται persistent στη συσκευή του φοιτητή μέσω SharedPreferences με χρήση JSON κωδικοποίησης στην `loadData()` και `saveData()`, διασφαλίζοντας ότι η εφαρμογή λειτουργεί πλήρως offline και με 100% ασφάλεια δεδομένων."*

### **Διαφάνεια 4: Σχεδιαστικές Επιλογές (UI/UX)**
> *"Σχεδιαστικά, θέλαμε η εφαρμογή να είναι ελκυστική και premium. Στον κώδικα της οθόνης `note_view_screen.dart` βλέπετε πώς υλοποιήσαμε το Notepad View: μια ζεστή κίτρινη παλέτα σε light mode που προσομοιώνει φυσικό χαρτί και έναν δυναμικό διακόπτη `_isEditing`. Όταν ο χρήστης επιλέξει επεξεργασία, το κείμενο μετατρέπεται άμεσα σε ένα borderless multiline `TextField` με custom line height 1.6 για μέγιστη αναγνωσιμότητα και άμεση inline συγγραφή σημειώσεων."*

### **Διαφάνεια 5: Ενσωμάτωση Υπολογιστικής Όρασης (Computer Vision)**
> *"Στη διαφάνεια αυτή βλέπουμε την καρδιά του Computer Vision αγωγού μας στο `helpers.dart`. Η μέθοδος `_preprocessIsolate` εκτελείται σε background isolate. Όπως φαίνεται στον κώδικα, εφαρμόζει Grayscale, Contrast boost στο 150, και Sharpening μέσω convolution matrix. Αυτή η προεπεξεργασμένη εικόνα τροφοδοτείται στη συνέχεια στο μοντέλο `TextRecognizer` του Google ML Kit για την εξαγωγή του κειμένου."*

### **Διαφάνεια 6: Ενσωμάτωση Επεξεργασίας Φυσικής Γλώσσας (NLP)**
> *"Στο επίπεδο του NLP, η εφαρμογή αναλύει το κείμενο που εξήχθη. Όπως φαίνεται στο `date_extractor.dart`, χρησιμοποιούμε regular expressions για να εντοπίσουμε ημερομηνίες σε διάφορες μορφές (αριθμητικές, ελληνικές και αγγλικές). Αν εντοπιστεί προθεσμία, το `NotificationService` προγραμματίζει αυτόματα μέσω της `zonedSchedule` μια ειδοποίηση στο κινητό του φοιτητή ακριβώς 1 ημέρα πριν από την προθεσμία στις 09:00 π.μ., ώστε να μην ξεχάσει ποτέ καμία εργασία."*

### **Διαφάνεια 7: Εξέλιξη & Αξιολόγηση**
> *"Κατά την εξέλιξη του έργου, αντιμετωπίσαμε προκλήσεις, όπως το πάγωμα της οθόνης κατά το αυτόματο OCR. Επιλέξαμε να διαχωρίσουμε τη λήψη από την ανάλυση: η αποθήκευση γίνεται πλέον ακαριαία και το OCR εκτελείται χειροκίνητα κατά απαίτηση του χρήστη (On-Demand). Αυτό απογείωσε την εμπειρία χρήσης. Όλοι οι αρχικοί στόχοι επιτεύχθηκαν στο 100%, παραδίδοντας μια σταθερή, ασφαλή και premium εφαρμογή."*
