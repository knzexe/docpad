import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/clinic_branding.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/cloud/clinic_sync_service.dart';
import '../../../data/local/encrypted_backup_service.dart';
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
  bool _backupBusy = false;

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

  Future<String?> _requestBackupPassword({required bool confirm}) async {
    final strings = ref.read(stringsProvider);
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? validationMessage;
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(confirm ? strings.createBackup : strings.restoreBackup),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confirm
                      ? strings.backupPasswordPrompt
                      : strings.restorePasswordPrompt,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: strings.backupPassword,
                  ),
                ),
                if (confirm) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmation,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: strings.confirmBackupPassword,
                    ),
                  ),
                ],
                if (validationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    validationMessage!,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (confirm &&
                      password.text.runes.length <
                          EncryptedBackupService.minimumPasswordLength) {
                    setDialogState(
                      () => validationMessage = strings.backupPasswordTooShort,
                    );
                    return;
                  }
                  if (password.text.isEmpty) {
                    setDialogState(
                      () => validationMessage = strings.backupPasswordRequired,
                    );
                    return;
                  }
                  if (confirm && password.text != confirmation.text) {
                    setDialogState(
                      () => validationMessage = strings.backupPasswordMismatch,
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, password.text);
                },
                child: Text(
                  confirm ? strings.createBackup : strings.restoreBackup,
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      password.dispose();
      confirmation.dispose();
    }
  }

  Future<bool?> _confirmBackupRestore(int recordCount) {
    final strings = ref.read(stringsProvider);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.restoreBackupTitle),
        content: Text(strings.backupRestoreConfirmation(recordCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirmRestore),
          ),
        ],
      ),
    );
  }

  String? _restoreBlockReason(ClinicSyncService service, AppStrings strings) {
    if (service.currentEmail != null) return strings.backupNeedsSignedOut;
    if (service.status.pendingChanges > 0) return strings.backupNeedsSync;
    if (service.status.phase == ClinicSyncPhase.connecting ||
        service.status.phase == ClinicSyncPhase.syncing) {
      return strings.backupNeedsSync;
    }
    return null;
  }

  Future<void> _createEncryptedBackup() async {
    final strings = ref.read(stringsProvider);
    String? password = await _requestBackupPassword(confirm: true);
    if (password == null || !mounted) return;

    setState(() {
      _backupBusy = true;
      _message = null;
    });
    try {
      final bytes = await ref
          .read(encryptedBackupServiceProvider)
          .createBackup(password);
      final location = await FilePicker.saveFile(
        fileName: 'docpad-clinic-backup.docpadbackup',
        bytes: bytes,
        mimeType: 'application/octet-stream',
        dialogTitle: strings.createBackup,
      );
      if (location != null && mounted) {
        setState(() => _message = strings.backupCreated);
      }
    } on EncryptedBackupException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on PlatformException catch (error) {
      AppLog.error('encrypted-backup-export', error);
      if (mounted) setState(() => _message = strings.backupFileAccessFailed);
    } finally {
      password = null;
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreEncryptedBackup() async {
    final strings = ref.read(stringsProvider);
    final syncService = ref.read(clinicSyncServiceProvider);
    final blocked = _restoreBlockReason(syncService, strings);
    if (blocked != null) {
      setState(() => _message = blocked);
      return;
    }

    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['docpadbackup'],
      );
    } on PlatformException catch (error) {
      AppLog.error('encrypted-backup-select', error);
      if (mounted) setState(() => _message = strings.backupFileAccessFailed);
      return;
    }
    if (file == null || !mounted) return;
    int? fileLength;
    try {
      fileLength = await file.length();
    } on PlatformException catch (error) {
      AppLog.error('encrypted-backup-file-size', error);
      if (mounted) setState(() => _message = strings.backupFileAccessFailed);
      return;
    }
    if (fileLength != null &&
        fileLength > EncryptedBackupService.maxBackupBytes) {
      setState(() => _message = strings.backupFileTooLarge);
      return;
    }

    String? password = await _requestBackupPassword(confirm: false);
    if (password == null || !mounted) return;

    setState(() {
      _backupBusy = true;
      _message = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final backup = await ref
          .read(encryptedBackupServiceProvider)
          .decryptBackup(bytes, password);
      password = null;
      if (!mounted) return;

      final confirmed = await _confirmBackupRestore(backup.recordCount);
      if (confirmed != true || !mounted) return;

      final currentBlock = _restoreBlockReason(syncService, strings);
      if (currentBlock != null) {
        setState(() => _message = currentBlock);
        return;
      }

      final editor = ref.read(editorProvider);
      if (editor.dirty && editor.prescription != null) {
        final saved = await ref.read(editorProvider.notifier).saveDraft();
        if (!saved) {
          if (mounted) {
            setState(() => _message = strings.backupDraftSaveFailed);
          }
          return;
        }
      }
      final pendingBlock = _restoreBlockReason(syncService, strings);
      if (pendingBlock != null) {
        if (mounted) setState(() => _message = pendingBlock);
        return;
      }

      ref.read(editorProvider.notifier).suspendAndForget();
      await ref.read(encryptedBackupServiceProvider).restoreLocalData(backup);
      ref.invalidate(profileProvider);
      ref.invalidate(prescriptionListProvider);
      ref.invalidate(patientListProvider);
      ref.invalidate(adviceListProvider);
      ref.invalidate(medicineLibraryProvider);
      final profile = ref.read(profileProvider);
      if (!mounted) return;
      setState(() {
        _name.text = profile.name;
        _designation.text = profile.designation;
        _registration.text = profile.registrationNumber;
        _clinic.text = profile.clinicName;
        _address.text = profile.clinicAddress;
        _contact.text = profile.contact;
        _header.text = profile.headerExtra;
        _logo = profile.logoBase64;
        _message = strings.backupRestored;
      });
    } on EncryptedBackupException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on PlatformException catch (error) {
      AppLog.error('encrypted-backup-import', error);
      if (mounted) setState(() => _message = strings.backupFileAccessFailed);
    } finally {
      password = null;
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final syncService = ref.read(clinicSyncServiceProvider);
    final syncStatus =
        ref.watch(clinicSyncStatusProvider).asData?.value ?? syncService.status;
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
                  strings.encryptedBackup,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.backupDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.backupRestoreWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('create-encrypted-backup'),
                      onPressed: _backupBusy ? null : _createEncryptedBackup,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(strings.createBackup),
                    ),
                    OutlinedButton.icon(
                      key: const Key('restore-encrypted-backup'),
                      onPressed: _backupBusy ? null : _restoreEncryptedBackup,
                      icon: const Icon(Icons.restore),
                      label: Text(strings.restoreBackup),
                    ),
                  ],
                ),
                if (_backupBusy) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.backupWorking,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
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
