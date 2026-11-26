# Raifa Medicine & SS Health Care

This clinic app provides prescription documentation for Windows, macOS, Linux, Android, and iOS. It records what the doctor types: patient details, clinical notes, manually entered medicine instructions, and advice. It does not diagnose, choose medicines, calculate doses, or generate treatment decisions.

The clinic profile, doctor details, logo, address, and phone number are prefilled from the supplied clinic artwork and can be edited in Settings. Prescription PDFs use the clinic's logo and colors.

Before any real clinical use, the deployment needs clinical, privacy, security, and regulatory review. Local storage on one device is not a backed-up medical record system.

## My Medicine Library

Medicine records are entered and managed by the doctor in the app's encrypted
local Hive database. Search matches the saved brand and generic names and works
without a network connection. The app makes no external medicine-service
requests and never generates clinical information or dose instructions.

## Run the app

Flutter 3.47 or newer (Dart 3.13).

```bash
flutter pub get
flutter run
```

## Supabase sync across your devices

The app remains usable offline with its encrypted Hive database. When configured
and signed in, your profile, patient records, prescriptions (including visit
histories and prescribed medicine details), advice templates, and medicine
library sync through Supabase Realtime. Changes made offline are queued locally
and uploaded when a connection is available. PDFs can be generated on each
device from synced records; exported PDF files and app language preferences
remain device-local.

Before enabling cloud sync:

1. Create a Supabase project and run the SQL files in `supabase/migrations` in
   timestamp order in its SQL Editor.
2. Read the project URL and **publishable** key from the Supabase dashboard.
   Never put a database password or service-role/secret key in the app.
3. Configure the app with:

   ```bash
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
   ```

   Use the same `--dart-define` values when producing a Windows or mobile
   release. Builds without both values use local storage only.
4. Create an account in Settings. After confirming the email, sign in with the
   same account on each device. The first signed-in device creates a private
   workspace for that account automatically. Existing local records on that
   device are uploaded; other devices signed in to that account receive them.

The migrations enable Row Level Security and grant record access only to
authenticated workspace members. Each account gets its own private workspace
when it first signs in; the app has no user invitation or sharing flow. Signing
out keeps local data and any queued changes on the device. “Erase clinical
data” removes synced records on every device when connected, or queues those
deletions while offline or signed out. A queued deletion is uploaded after
signing back in to the same account. Supabase authentication sessions are
stored using the platform's secure storage.

Supabase configuration is not, by itself, a guarantee of healthcare privacy or
regulatory compliance. Review data residency, retention, access, backups,
encryption, applicable agreements, and local healthcare requirements before
using real patient records.

## App icons

Launcher icons for Android, iOS, Windows, macOS, and web are generated from
`assets/images/raifa_medicine_logo.png`. After replacing that source image, run:

```bash
dart run flutter_launcher_icons
```

## Windows installer

Install Inno Setup 6, then build the Windows release and installer:

```bash
flutter build windows --release
iscc windows/installer/docpad.iss
```

The setup executable is written to `build/windows/installer`. It installs
per-user, creates a Start menu shortcut, and offers an optional desktop
shortcut. The installer is not code-signed.

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

Prescriptions, patients, advice templates, medicines, and the doctor profile are JSON in encrypted Hive boxes. The AES key is created once and kept in the platform secure store (`docpad.hive_key`). The stable key name remains unchanged. If that store cannot be opened, the app stops on a startup screen and does not open a new empty database or replace the key.

App preferences use SharedPreferences. The app uses a fixed white/light
interface; appearance is not controlled by the device theme.

Erase local clinical data from Settings by typing `DELETE`. That removes prescriptions, patients, advice, and medicines; custom clinic details reset to the supplied defaults. The language preference stays.

The app does not log patient names, phone numbers, or clinical notes. PDF file names use the prescription id, not the patient name.

## Fonts and language

The interface uses bundled Inter, with Noto Sans and Noto Sans Bengali as fallbacks, so drafts and PDFs work offline. PDF text uses the Noto fonts so English and Bangla can share a page. The interface language is English or Bangla, chosen in Settings.

Icons use the Lucide font shipped with the `lucide_icons` package. The package’s icon class subclasses `IconData`, which current Flutter marks final, so the app constructs `IconData` directly and does not import that class.

## Tests

```bash
flutter analyze
flutter test
```

`flutter test` covers model serialization, local medicine-library search, editor state, PDF bytes, and the widget workflow. Tests use in-memory storage and do not make network requests.

The same draft flow is also in `integration_test/prescription_flow_test.dart`:

```bash
flutter test -d windows integration_test
```

## Layout

- Phone (under 720px): bottom navigation and a single-column prescription editor.
- Tablet (720px to under 1100px): compact navigation rail and compact action buttons.
- Desktop (1100px and wider): extended navigation rail.
- The prescription editor switches to two columns when its available content width reaches 900px; otherwise it stays in one column.

## Limitations

- Hive encryption protects the local database key in the platform secure store. It is not a substitute for device lock, backups, or a clinic record system.
- The Latin Noto subset used for PDF body text covers common English punctuation. Bangla uses Noto Sans Bengali.
- Printing depends on the platform print dialog. Cancelling it is reported as cancelled, not as success.
