import 'package:flutter/material.dart';

// --- ΠΑΓΚΟΣΜΙΑ ΜΝΗΜΗ ΕΦΑΡΜΟΓΗΣ ---
// Τώρα η λίστα images αποθηκεύει Map (φωτογραφία ΚΑΙ κείμενο)
List<Map<String, dynamic>> globalUserTopics = [];
List<Map<String, dynamic>> globalUserNotes = [];
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

// Αυτόματη Υπενθύμιση — ενεργοποίηση/απενεργοποίηση
final ValueNotifier<bool> autoReminderEnabled = ValueNotifier(true);
