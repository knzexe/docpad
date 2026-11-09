# DocPad

DocPad is a doctor-facing prescription documentation app for Windows, macOS, Linux, Android, and iOS. It records what the doctor types: patient details, clinical notes, manually entered medicine instructions, and advice. It does not diagnose, choose medicines, calculate doses, or generate treatment decisions.

Before any real clinical use, the deployment needs clinical, privacy, security, and regulatory review. Local storage on one device is not a backed-up medical record system.

## My Medicine Library

Medicine records are entered and managed by the doctor in DocPad's encrypted
local Hive database. Search matches the saved brand and generic names and works
without a network connection. DocPad does not call MedEx, DGHS, or any other
external medicine service, and it never generates clinical information or dose
instructions.

## Run DocPad

Flutter 3.47 or newer (Dart 3.13).

```bash
flutter pub get
flutter run
```

## What you can do

1. Open the dashboard.
2. Start a prescription.
3. Enter patient information and clinical notes.
4. Open My Medicine Library and add manually entered medicine records.
5. Type dose, frequency, duration, route, timing, instructions, and quantity yourself.
6. Add several medicines, edit them, reorder them, and remove them after confirmation.
7. Save advice templates and add advice to the prescription.
8. Preview the document. It stays marked draft until you finalize it.
9. Save the draft on this device, leave, and open it again.
10. Export a PDF or print it. The success message appears only after the save or print call finishes.

## Data on the device

Prescriptions, patients, advice templates, medicines, and the doctor profile are JSON in encrypted Hive boxes. The AES key is created once and kept in the platform secure store (`docpad.hive_key`). If that store cannot be opened, DocPad stops on a startup screen and does not open a new empty database or replace the key.

Settings such as theme and language use SharedPreferences.

Erase local clinical data from Settings by typing `DELETE`. That removes prescriptions, patients, advice, medicines, and the profile. Theme and language stay.

The app does not log patient names, phone numbers, or clinical notes. PDF file names use the prescription id, not the patient name.

## Fonts and language

The interface uses bundled Inter, with Noto Sans and Noto Sans Bengali as fallbacks, so drafts and PDFs work offline. PDF text uses the Noto fonts so English and Bangla can share a page. The interface language is English or Bangla, chosen in Settings.

Icons use the Lucide font shipped with the `lucide_icons` package. The package’s icon class subclasses `IconData`, which current Flutter marks final, so DocPad constructs `IconData` directly and does not import that class.

## Tests

```bash
flutter analyze
flutter test
```

`flutter test` covers model serialization, catalog response parsing, editor state, PDF bytes, and the widget workflow. Tests use an in-memory catalog. They do not call a live medicine API.

The same draft flow is also in `integration_test/prescription_flow_test.dart`:

```bash
flutter test -d windows integration_test
```

## Layout

- Desktop (1100px and wider): extended sidebar, two-column prescription editor.
- Tablet: collapsed rail.
- Phone (under 720px): bottom navigation and a single scrolling editor.

## Limitations

- Hive encryption protects the local database key in the platform secure store. It is not a substitute for device lock, backups, or a clinic record system.
- The Latin Noto subset used for PDF body text covers common English punctuation. Bangla uses Noto Sans Bengali.
- Printing depends on the platform print dialog. Cancelling it is reported as cancelled, not as success.
