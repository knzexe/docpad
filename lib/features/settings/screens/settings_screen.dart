import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/clinic_branding.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/cloud/clinic_sync_service.dart';
import '../../../data/repository_providers.dart';
import '../../medicine/providers/medicine_library_provider.dart';
import '../../prescription/providers/editor_provider.dart';
import '../../prescription/providers/record_providers.dart';
import '../models/doctor_profile.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _registration;
  late final TextEditingController _clinic;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  late final TextEditingController _header;
  late final TextEditingController _eraseConfirm;
  late final TextEditingController _cloudEmail;
  late final TextEditingController _cloudPassword;
  String? _logo;
  String? _message;
  String? _cloudMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _name = TextEditingController(text: profile.name);
    _designation = TextEditingController(text: profile.designation);
    _registration = TextEditingController(text: profile.registrationNumber);
    _clinic = TextEditingController(text: profile.clinicName);
    _address = TextEditingController(text: profile.clinicAddress);
    _contact = TextEditingController(text: profile.contact);
    _header = TextEditingController(text: profile.headerExtra);
    _eraseConfirm = TextEditingController();
    _cloudEmail = TextEditingController();
    _cloudPassword = TextEditingController();
    _logo = profile.logoBase64;
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _registration.dispose();
    _clinic.dispose();
    _address.dispose();
    _contact.dispose();
    _header.dispose();
    _eraseConfirm.dispose();
    _cloudEmail.dispose();
    _cloudPassword.dispose();
    super.dispose();
  }

  DoctorProfile _profile() {
    return DoctorProfile(
      name: _name.text.trim(),
      designation: _designation.text.trim(),
      registrationNumber: _registration.text.trim(),
      clinicName: _clinic.text.trim(),
      clinicAddress: _address.text.trim(),
      contact: _contact.text.trim(),
      headerExtra: _header.text.trim(),
      logoBase64: _logo,
    );
  }

  Future<void> _saveProfile() async {
    final strings = ref.read(stringsProvider);
    await ref.read(profileProvider.notifier).save(_profile());
    if (!mounted) return;
    setState(() => _message = strings.profileSaved);
  }

  Future<void> _signInToClinic() async {
    final service = ref.read(clinicSyncServiceProvider);
    final strings = ref.read(stringsProvider);
    setState(() => _cloudMessage = null);
    try {
      await service.signIn(
        email: _cloudEmail.text,
        password: _cloudPassword.text,
      );
      if (mounted) {
        _cloudPassword.clear();
        setState(() => _cloudMessage = strings.cloudSignInComplete);
      }
    } catch (error) {
      if (mounted) setState(() => _cloudMessage = error.toString());
    }
  }

  Future<void> _createClinicAccount() async {
    final service = ref.read(clinicSyncServiceProvider);
    final strings = ref.read(stringsProvider);
    setState(() => _cloudMessage = null);
    try {
      final signedIn = await service.signUp(
        email: _cloudEmail.text,
        password: _cloudPassword.text,
      );
      if (!mounted) return;
      _cloudPassword.clear();
      setState(() {
        _cloudMessage = signedIn
            ? strings.cloudSignInComplete
            : strings.cloudAccountCreated;
      });
    } catch (error) {
      if (mounted) setState(() => _cloudMessage = error.toString());
    }
  }

  Future<void> _signOutFromClinic() async {
    final service = ref.read(clinicSyncServiceProvider);
    setState(() => _cloudMessage = null);
    try {
      await service.signOut();
    } catch (error) {
      if (mounted) setState(() => _cloudMessage = error.toString());
    }
  }

  Future<void> _syncClinicNow() async {
    final service = ref.read(clinicSyncServiceProvider);
    setState(() => _cloudMessage = null);
    try {
      await service.syncNow();
    } catch (error) {
      if (mounted) setState(() => _cloudMessage = error.toString());
    }
  }

  String _cloudStatusText(
    ClinicSyncStatus status,
    ClinicSyncService service,
    AppStrings strings,
  ) {
    if (service.configurationError != null) {
      return strings.cloudConfigurationIssue;
    }
    return switch (status.phase) {
      ClinicSyncPhase.disabled => strings.cloudNotConfigured,
      ClinicSyncPhase.signedOut => strings.cloudSignedOut,
      ClinicSyncPhase.connecting => strings.cloudConnecting,
      ClinicSyncPhase.syncing => strings.cloudSyncing,
      ClinicSyncPhase.synced => strings.cloudSynced,
      ClinicSyncPhase.needsMembership => strings.cloudNeedsMembership,
      ClinicSyncPhase.differentClinic => strings.cloudDifferentClinic,
      ClinicSyncPhase.error => strings.cloudSyncFailed,
    };
  }

  Future<void> _pickLogo() async {
    final strings = ref.read(stringsProvider);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 1024 * 1024) {
        setState(() => _message = strings.logoTooLarge);
        return;
      }
      setState(() {
        _logo = base64Encode(bytes);
        _message = null;
      });
    } catch (_) {
      if (mounted) setState(() => _message = strings.logoFailed);
    }
  }

  Future<void> _confirmErase() async {
    final strings = ref.read(stringsProvider);
    if (_eraseConfirm.text.trim() != 'DELETE') return;
    ref.read(editorProvider.notifier).suspendAndForget();
    try {
      await ref.read(prescriptionRepositoryProvider).clear();
      await ref.read(patientRepositoryProvider).clear();
      await ref.read(adviceRepositoryProvider).clear();
      await ref.read(medicineRepositoryProvider).clear();
      ref.invalidate(medicineLibraryProvider);
      await clearLegacyTrCredentials();
      await ref.read(profileProvider.notifier).clear();
      await ref.read(prescriptionListProvider.notifier).refresh();
      await ref.read(patientListProvider.notifier).refresh();
      await ref.read(adviceListProvider.notifier).refresh();
      if (!mounted) return;
      final clinicProfile = DoctorProfile.clinicDefault;
      setState(() {
        _name.text = clinicProfile.name;
        _designation.text = clinicProfile.designation;
        _registration.text = clinicProfile.registrationNumber;
        _clinic.text = clinicProfile.clinicName;
        _address.text = clinicProfile.clinicAddress;
        _contact.text = clinicProfile.contact;
        _header.text = clinicProfile.headerExtra;
        _logo = null;
        _eraseConfirm.clear();
        _message = strings.eraseSuccess;
      });
    } catch (_) {
      if (mounted) setState(() => _message = strings.eraseFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final syncService = ref.read(clinicSyncServiceProvider);
    final syncStatus =
        ref.watch(clinicSyncStatusProvider).asData?.value ??
        syncService.status;
    final signedInEmail = syncService.currentEmail;
    return AppPage(
      maxWidth: AppLayout.settingsMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: strings.settings, subtitle: strings.disclaimer),
          if (_message != null) ...[
            const SizedBox(height: 12),
            InfoBanner(message: _message!),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: strings.doctorProfile,
            child: Column(
              children: [
                AppTextField(controller: _name, label: strings.doctorName),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _designation,
                  label: strings.designation,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _registration,
                  label: strings.registrationNumber,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _clinic, label: strings.clinicName),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _address,
                  label: strings.clinicAddress,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(controller: _contact, label: strings.contact),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _header,
                  label: strings.headerExtra,
                  hint: strings.headerHint,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    strings.logo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _logo == null
                      ? Image.asset(
                          ClinicBranding.logoAsset,
                          height: 72,
                          errorBuilder: (_, _, _) => Text(strings.logoFailed),
                        )
                      : Image.memory(
                          base64Decode(_logo!),
                          height: 56,
                          errorBuilder: (_, _, _) => Text(strings.logoFailed),
                        ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _pickLogo,
                      child: Text(strings.chooseLogo),
                    ),
                    if (_logo != null)
                      TextButton(
                        onPressed: () => setState(() => _logo = null),
                        child: Text(strings.removeLogo),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _saveProfile,
                    child: Text(strings.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.language,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ],
              selected: {settings.languageCode},
              onSelectionChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(languageCode: value.first));
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.cloudSync,
            subtitle: strings.cloudSyncDescription,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cloudSyncWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _cloudStatusText(syncStatus, syncService, strings),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (syncStatus.pendingChanges > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    strings.cloudPendingChanges(syncStatus.pendingChanges),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_cloudMessage != null) ...[
                  const SizedBox(height: 12),
                  InfoBanner(message: _cloudMessage!),
                ],
                if (syncService.isConfigured && signedInEmail == null) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _cloudEmail,
                    label: strings.emailAddress,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _cloudPassword,
                    label: strings.password,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed:
                            _cloudEmail.text.trim().isNotEmpty &&
                                _cloudPassword.text.isNotEmpty
                            ? _signInToClinic
                            : null,
                        child: Text(strings.signIn),
                      ),
                      OutlinedButton(
                        onPressed:
                            _cloudEmail.text.trim().isNotEmpty &&
                                _cloudPassword.text.length >= 6
                            ? _createClinicAccount
                            : null,
                        child: Text(strings.createAccount),
                      ),
                    ],
                  ),
                ] else if (signedInEmail != null) ...[
                  const SizedBox(height: 12),
                  Text(signedInEmail),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _syncClinicNow,
                        child: Text(strings.syncNow),
                      ),
                      TextButton(
                        onPressed: _signOutFromClinic,
                        child: Text(strings.signOut),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.dataManagement,
            subtitle: strings.localStorageNotice,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.eraseBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _eraseConfirm,
                  label: strings.typeDelete,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _eraseConfirm.text.trim() == 'DELETE'
                      ? _confirmErase
                      : null,
                  child: Text(strings.eraseAll),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
