import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/repository_providers.dart';
import '../../medicine/providers/medicine_providers.dart';
import '../../medicine/providers/medicine_library_provider.dart';
import '../../prescription/providers/editor_provider.dart';
import '../../prescription/providers/record_providers.dart';
import '../models/doctor_profile.dart';
import '../models/tr_credentials.dart';
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
  late final TextEditingController _url;
  late final TextEditingController _trUser;
  late final TextEditingController _trPass;
  late final TextEditingController _eraseConfirm;
  String? _logo;
  String? _message;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    final settings = ref.read(settingsProvider);
    _name = TextEditingController(text: profile.name);
    _designation = TextEditingController(text: profile.designation);
    _registration = TextEditingController(text: profile.registrationNumber);
    _clinic = TextEditingController(text: profile.clinicName);
    _address = TextEditingController(text: profile.clinicAddress);
    _contact = TextEditingController(text: profile.contact);
    _header = TextEditingController(text: profile.headerExtra);
    _url = TextEditingController(text: settings.medexBaseUrl);
    _trUser = TextEditingController();
    _trPass = TextEditingController();
    _eraseConfirm = TextEditingController();
    Future<void>(() async {
      final saved = await ref.read(trCredentialsProvider.future);
      if (!mounted || _trUser.text.isNotEmpty) return;
      _trUser.text = saved.username;
    });
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
    _url.dispose();
    _trUser.dispose();
    _trPass.dispose();
    _eraseConfirm.dispose();
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

  Future<void> _pickLogo() async {
    final strings = ref.read(stringsProvider);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 512 * 1024) {
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

  Future<void> _saveUrl() async {
    final strings = ref.read(stringsProvider);
    if (!AppConfig.isValidBaseUrl(_url.text)) {
      setState(() => _message = strings.invalidUrl);
      return;
    }
    final previous = ref.read(settingsProvider).medexBaseUrl;
    final normalized = AppConfig.normalizeBaseUrl(_url.text);
    final next = ref.read(settingsProvider).copyWith(medexBaseUrl: normalized);
    await ref.read(settingsProvider.notifier).update(next);
    final current = await ref.read(trCredentialsProvider.future);
    final username = _trUser.text.trim();
    final typedPassword = _trPass.text;
    final password = typedPassword.isEmpty ? current.password : typedPassword;
    try {
      await ref
          .read(trCredentialsProvider.notifier)
          .save(TrCredentials(username: username, password: password));
    } on AppException catch (error) {
      if (mounted) setState(() => _message = error.message);
      return;
    }
    if (typedPassword.isNotEmpty) _trPass.clear();
    if (previous != normalized) {
      await ref.read(catalogCacheRepositoryProvider).clear();
    }
    if (mounted) setState(() => _message = strings.saved);
  }

  Future<void> _testConnection() async {
    final strings = ref.read(stringsProvider);
    await _saveUrl();
    if (!AppConfig.isValidBaseUrl(_url.text)) return;
    final health = await ref.read(catalogHealthProvider.notifier).refresh();
    if (!mounted || health == null) {
      if (mounted) setState(() => _message = strings.connectionFailed);
      return;
    }
    setState(() {
      _message = health.isFixture
          ? strings.fixtureConnection(health.providerName)
          : strings.liveConnection(health.providerName);
    });
  }

  Future<void> _confirmErase() async {
    final strings = ref.read(stringsProvider);
    if (_eraseConfirm.text.trim() != 'DELETE') return;
    ref.read(editorProvider.notifier).suspendAndForget();
    try {
      await ref.read(prescriptionRepositoryProvider).clear();
      await ref.read(patientRepositoryProvider).clear();
      await ref.read(adviceRepositoryProvider).clear();
      await ref.read(catalogCacheRepositoryProvider).clear();
      await ref.read(medicineRepositoryProvider).clear();
      ref.invalidate(medicineLibraryProvider);
      await ref.read(trCredentialsProvider.notifier).save(const TrCredentials());
      await ref.read(profileProvider.notifier).clear();
      await ref.read(prescriptionListProvider.notifier).refresh();
      await ref.read(patientListProvider.notifier).refresh();
      await ref.read(adviceListProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _name.clear();
        _designation.clear();
        _registration.clear();
        _clinic.clear();
        _address.clear();
        _contact.clear();
        _header.clear();
        _trUser.clear();
        _trPass.clear();
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageWidth(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settings,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _registration,
                      label: strings.registrationNumber,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _clinic,
                      label: strings.clinicName,
                    ),
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
                    if (_logo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.memory(
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
                title: strings.theme,
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(strings.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(strings.themeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(strings.themeSystem),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(themeMode: value.first));
                  },
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: strings.catalogAddress,
                subtitle: strings.catalogAddressHint,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _url,
                      label: strings.catalogAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _trUser,
                      label: strings.trUsername,
                      hint: strings.trAuthHint,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _trPass,
                      label: strings.trPassword,
                      hint: strings.trPasswordHint,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _saveUrl,
                          child: Text(strings.save),
                        ),
                        OutlinedButton(
                          onPressed: _testConnection,
                          child: Text(strings.testConnection),
                        ),
                      ],
                    ),
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
        ),
      ],
    );
  }
}
