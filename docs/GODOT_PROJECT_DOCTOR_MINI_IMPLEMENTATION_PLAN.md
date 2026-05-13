# Godot Project Doctor Mini - Implementation Plan

Πρακτικό πλάνο υλοποίησης για το Godot Project Doctor Mini, με βάση το τρέχον MVP και τα επόμενα βήματα που χρειάζονται για να γίνει σταθερό, δοκιμάσιμο και εύκολο να επεκταθεί.

## Στόχος

Το Godot Project Doctor Mini είναι ένα Godot 4 editor plugin που σαρώνει το τρέχον project και παράγει διαγνωστικό report σε Markdown και JSON.

Ο βασικός στόχος της υλοποίησης είναι:

- Ένα απλό editor dock με κουμπί `Scan Project`.
- Σάρωση αρχείων, scenes, scripts, textures και export presets.
- Εμφάνιση ευρημάτων μέσα στο Godot editor.
- Αυτόματη παραγωγή reports στον φάκελο `reports/`.
- Καθαρή αρχιτεκτονική ώστε να προστεθούν περισσότερα checks αργότερα.

## Τρέχουσα Κατάσταση

Το project έχει ήδη λειτουργικό MVP πυρήνα.

Υπάρχουν τα βασικά αρχεία:

```text
addons/project_doctor_mini/
  plugin.cfg
  project_doctor_plugin.gd
  project_doctor_dock.gd
  tools/run_project_scan.gd
  scanner/project_scanner.gd
  report/markdown_report_writer.gd
  report/json_report_writer.gd
```

Υπάρχει επίσης headless task μέσω:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

Το πλάνο από εδώ και πέρα εστιάζει σε σταθεροποίηση, καλύτερη δομή, δοκιμές και μικρό polish.

## Αρχιτεκτονική Υλοποίησης

### Editor Plugin Layer

Αρχεία:

- `addons/project_doctor_mini/plugin.cfg`
- `addons/project_doctor_mini/project_doctor_plugin.gd`
- `addons/project_doctor_mini/project_doctor_dock.gd`

Ρόλος:

- Εγγραφή του plugin στο Godot editor.
- Δημιουργία dock panel.
- Εκκίνηση scan από UI.
- Απόδοση summary και findings σε λίστα.
- Κλήση report writers μετά από κάθε scan.

### Scanner Layer

Αρχείο:

- `addons/project_doctor_mini/scanner/project_scanner.gd`

Ρόλος:

- Walk στο `res://`.
- Συλλογή αρχείων και φακέλων.
- Συλλογή references από text resources και GDScript loads.
- Εκτέλεση όλων των MVP checks.
- Επιστροφή ενός ενιαίου report dictionary.

### Report Layer

Αρχεία:

- `addons/project_doctor_mini/report/markdown_report_writer.gd`
- `addons/project_doctor_mini/report/json_report_writer.gd`

Ρόλος:

- Παραγωγή human-readable Markdown report.
- Παραγωγή machine-readable JSON report.
- Διατήρηση σταθερού schema για μελλοντικό automation.

### Headless Tooling Layer

Αρχείο:

- `addons/project_doctor_mini/tools/run_project_scan.gd`

Ρόλος:

- Εκτέλεση scanner χωρίς UI.
- Χρήση από VS Code task ή μελλοντικό CI.
- Παραγωγή των ίδιων report files με το editor dock.

## Report Schema

Το report πρέπει να κρατήσει σταθερή μορφή:

```json
{
  "tool": "Godot Project Doctor Mini",
  "generated_at": "2026-05-13T00:00:00",
  "project_root": "res://",
  "summary": {
    "errors": 0,
    "warnings": 0,
    "info": 0
  },
  "findings": []
}
```

Κάθε finding πρέπει να έχει:

```json
{
  "id": "large_texture",
  "severity": "warning",
  "title": "Large Texture",
  "path": "res://assets/textures/example.png",
  "message": "Texture is 4096x4096, above the 2048px threshold.",
  "recommendation": "Resize, compress, or use platform-specific import settings."
}
```

## Φάση 1 - MVP Stabilization

Στόχος: να επιβεβαιωθεί ότι το υπάρχον MVP δουλεύει αξιόπιστα στο editor και headless.

Εργασίες:

- Έλεγχος ότι το plugin ενεργοποιείται από `Project > Project Settings > Plugins`.
- Έλεγχος ότι εμφανίζεται το dock `Project Doctor`.
- Επιβεβαίωση ότι το `Scan Project` τρέχει χωρίς errors.
- Επιβεβαίωση ότι δημιουργούνται:
  - `reports/project-doctor-report.md`
  - `reports/project-doctor-report.json`
- Έλεγχος ότι το summary στο UI συμφωνεί με τα report files.
- Έλεγχος ότι το headless script παράγει ίδιο report shape.

Κριτήριο ολοκλήρωσης:

- Το scan τρέχει από UI και από VS Code task χωρίς crash.
- Τα generated reports ανοίγουν και διαβάζονται σωστά.

## Φάση 2 - Scanner Hardening

Στόχος: να μειωθούν false positives και edge case failures.

Εργασίες:

- Να εξαιρεθούν generated ή internal paths όπου χρειάζεται, όπως `.godot`.
- Να ελεγχθεί αν τα `.import` αρχεία πρέπει να συμμετέχουν στα references ή μόνο ως υποστηρικτικά metadata.
- Να προστεθεί ασφαλής χειρισμός όταν ένα file read επιστρέφει άδειο ή αποτυγχάνει.
- Να αποφευχθεί διπλή αναφορά του ίδιου finding όπου γίνεται.
- Να γίνει το `unused files` check πιο συντηρητικό, επειδή dynamic loads μπορεί να μην εντοπιστούν.
- Να προστεθούν constants ή settings για scan exclusions.

Κριτήριο ολοκλήρωσης:

- Τα findings είναι χρήσιμα και όχι υπερβολικά θορυβώδη.
- Το scanner παραμένει γρήγορο σε μικρά και μεσαία projects.

## Φάση 3 - UI Polish

Στόχος: το dock να γίνει πιο άνετο για καθημερινή χρήση.

Εργασίες:

- Να προστεθεί καθαρό status message για scan start, success και failure.
- Να εμφανίζονται τα report paths μετά το scan.
- Να προστεθούν severity filters:
  - Errors
  - Warnings
  - Info
- Να προστεθεί κουμπί `Open Reports Folder`
- Να προστεθούν tooltips για βασικά UI controls.
- Να ελεγχθεί ότι οι στήλες του `Tree`
Κριτήριο ολοκλήρωσης:

- Ο χρήστης καταλαβαίνει αμέσως τι βρέθηκε και πού γράφτηκαν τα reports.

## Φάση 4 - Report Quality

Στόχος: τα reports να είναι χρήσιμα σε GitHub, review και μελλοντικό CI.

Εργασίες:

- Να ταξινομούνται τα findings ανά severity.
- Να υπάρχει σταθερή σειρά:
  - errors
  - warnings
  - info
- Να προστεθεί section `Generated By` ή `Tool Version` όταν υπάρξει version.
- Να γίνει escape ή sanitize σε Markdown values όπου χρειάζεται.
- Να προστεθεί optional `scan_duration_ms`.
- Να κρατηθεί το JSON απλό και backward-compatible.

Κριτήριο ολοκλήρωσης:

- Το Markdown report είναι ευανάγνωστο σε GitHub.
- Το JSON μπορεί να καταναλωθεί από script χωρίς ειδική επεξεργασία.

## Φάση 5 - Testing

Στόχος: να υπάρχει σταθερό manual και automated testing path.

Manual tests:

- Ενεργοποίηση plugin στο Godot editor.
- Εκτέλεση `Scan Project`.
- Έλεγχος UI summary.
- Έλεγχος Markdown report.
- Έλεγχος JSON report.
- Προσωρινή προσθήκη missing script reference και επιβεβαίωση error.
- Προσωρινή προσθήκη `_process()` σε script και επιβεβαίωση info finding.
- Προσωρινή προσθήκη large texture και επιβεβαίωση warning.
- Αφαίρεση ή απουσία `export_presets.cfg` και επιβεβαίωση warning.

Headless tests:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

VS Code tasks:

- `Godot: Validate Project Headless`
- `Godot: Scan Project Headless`

Κριτήριο ολοκλήρωσης:

- Υπάρχει επαναλήψιμος τρόπος να ελεγχθεί το plugin χωρίς χειροκίνητο άνοιγμα του dock.

## Φάση 6 - Documentation

Στόχος: το project να είναι εύκολο να το ανοίξει και να το τρέξει κάποιος τρίτος.

Εργασίες:

- Ενημέρωση `README.md` με σύντομο usage.
- Προσθήκη section για enabling plugin.
- Περιγραφή των generated reports.
- Προσθήκη troubleshooting για GDScript language server.
- Προσθήκη screenshots όταν το UI σταθεροποιηθεί.
- Περιγραφή γνωστών limitations, ειδικά για dynamic resource loads.

Κριτήριο ολοκλήρωσης:

- Κάποιος μπορεί να κάνει clone, open in Godot, enable plugin, run scan και να βρει τα reports.

## Φάση 7 - Future Expansion

Ιδέες μετά το σταθερό MVP:

- Plugin settings για thresholds.
- Baseline file για known accepted findings.
- Ignore patterns ανά check.
- Export profile readiness per platform.
- Scene dependency graph.
- Asset import settings analysis.
- GitHub Action για headless scan σε PR.
- C# helper layer για πιο βαριά parsing tasks.
- Packaged Asset Library release.

## Προτεινόμενη Σειρά Εργασίας

1. Τρέξιμο headless scan και επιβεβαίωση generated reports.
2. Manual test μέσα από Godot editor.
3. Μικρές διορθώσεις σε scanner false positives.
4. Βελτίωση UI status και report path feedback.
5. Ταξινόμηση findings στα reports.
6. Ενημέρωση README.
7. Προσθήκη screenshots και release checklist.

## Definition of Done

Το project θεωρείται έτοιμο για πρώτο σταθερό MVP όταν:

- Το plugin ενεργοποιείται και ανοίγει χωρίς errors.
- Το `Scan Project` δουλεύει από το dock.
- Το headless scan δουλεύει από VS Code task.
- Τα Markdown και JSON reports δημιουργούνται σωστά.
- Τα MVP checks επιστρέφουν findings με σταθερό schema.
- Το README εξηγεί πώς εγκαθίσταται και πώς τρέχει.
- Τα known limitations είναι γραμμένα καθαρά.

## Άμεσα Επόμενα Βήματα

Προτεινόμενο πρώτο sprint:

- Να τρέξει το headless scan.
- Να ελεγχθούν τα υπάρχοντα report outputs.
- Να διορθωθούν obvious false positives.
- Να βελτιωθεί το dock status text.
- Να προστεθεί sorting των findings ανά severity.

Αυτό θα μετατρέψει το υπάρχον MVP από proof-of-concept σε μικρό αλλά αξιόπιστο εργαλείο.
