import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_log.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../data/repository_providers.dart';
import '../../patients/models/patient.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/prescribed_medicine.dart';
import '../models/prescription.dart';
import 'record_providers.dart';

const _uuid = Uuid();
const _unset = Object();

class EditorState {
  const EditorState({
    this.prescription,
    this.loading = false,
    this.loadError = false,
    this.saving = false,
    this.saveError,
    this.dirty = false,
    this.fieldErrors = const {},
    this.missing = false,
    this.isNewSession = false,
    this.returnedToDraft = false,
    this.notice,
  });

  final Prescription? prescription;
  final bool loading;
  final bool loadError;
  final bool saving;
  final String? saveError;
  final bool dirty;
  final Map<String, String> fieldErrors;
  final bool missing;
  final bool isNewSession;
  final bool returnedToDraft;
  final String? notice;

  EditorState copyWith({
    Object? prescription = _unset,
    bool? loading,
    bool? loadError,
    bool? saving,
    Object? saveError = _unset,
    bool? dirty,
    Map<String, String>? fieldErrors,
    bool? missing,
    bool? isNewSession,
    bool? returnedToDraft,
    Object? notice = _unset,
  }) {
    return EditorState(
      prescription: prescription == _unset
          ? this.prescription
          : prescription as Prescription?,
      loading: loading ?? this.loading,
      loadError: loadError ?? this.loadError,
      saving: saving ?? this.saving,
      saveError: saveError == _unset ? this.saveError : saveError as String?,
      dirty: dirty ?? this.dirty,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      missing: missing ?? this.missing,
      isNewSession: isNewSession ?? this.isNewSession,
      returnedToDraft: returnedToDraft ?? this.returnedToDraft,
      notice: notice == _unset ? this.notice : notice as String?,
    );
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);

class EditorNotifier extends Notifier<EditorState> {
  Timer? _autosave;
  int _generation = 0;
  Prescription? _baseline;
  bool _saving = false;
  bool _blockWrites = false;

  @override
  EditorState build() {
    ref.onDispose(() => _autosave?.cancel());
    return const EditorState();
  }

  void startNew({Patient? prefilled}) {
    _autosave?.cancel();
    _generation++;
    _blockWrites = false;
    final now = DateTime.now();
    final prescription = Prescription(
      id: _uuid.v4(),
      patient: Patient(
        id: prefilled?.id ?? _uuid.v4(),
        name: prefilled?.name ?? '',
        phone: prefilled?.phone ?? '',
        age: prefilled?.age,
        sex: prefilled?.sex,
        prescriptionDate: now,
        address: prefilled?.address,
        patientCode: prefilled?.patientCode,
        identificationNotes: prefilled?.identificationNotes,
      ),
      chiefComplaint: '',
      history: '',
      medicalHistory: '',
      investigationNotes: '',
      examinationNotes: '',
      assessment: '',
      medicines: const [],
      advice: const [],
      createdAt: now,
      updatedAt: now,
      isDraft: true,
      documentLanguage: ref.read(settingsProvider).languageCode,
      header: ref.read(profileProvider),
    );
    _baseline = prescription;
    state = EditorState(prescription: prescription, isNewSession: true);
  }

  void openFromRoute({String? id, Patient? prefilled}) {
    if (id == null) {
      if (state.isNewSession && state.prescription != null) return;
      startNew(prefilled: prefilled);
      return;
    }
    if (state.prescription?.id == id && !state.missing && !state.loadError) {
      return;
    }
    unawaited(openExisting(id));
  }

  void suspendAndForget() {
    _autosave?.cancel();
    _generation++;
    _blockWrites = true;
    _baseline = null;
    state = const EditorState();
  }

  Future<void> openExisting(String id) async {
    _autosave?.cancel();
    _blockWrites = false;
    final generation = ++_generation;
    state = const EditorState(loading: true);
    try {
      final existing = await ref
          .read(prescriptionRepositoryProvider)
          .getById(id);
      if (generation != _generation) return;
      if (existing == null) {
        state = const EditorState(missing: true);
        return;
      }
      _baseline = existing;
      state = EditorState(prescription: existing);
    } catch (error) {
      AppLog.error('open-prescription', error);
      if (generation != _generation) return;
      state = const EditorState(loadError: true);
    }
  }

  void updatePatient(Patient patient) {
    _apply((current) => current.copyWith(patient: patient));
  }

  void updateClinical({
    required String chiefComplaint,
    required String history,
    required String medicalHistory,
    required String investigationNotes,
    required String examinationNotes,
    required String assessment,
  }) {
    _apply(
      (current) => current.copyWith(
        chiefComplaint: chiefComplaint,
        history: history,
        medicalHistory: medicalHistory,
        investigationNotes: investigationNotes,
        examinationNotes: examinationNotes,
        assessment: assessment,
      ),
    );
  }

  void addMedicine(PrescribedMedicine medicine) {
    _apply(
      (current) =>
          current.copyWith(medicines: [...current.medicines, medicine]),
    );
  }

  void updateMedicine(PrescribedMedicine medicine) {
    _apply(
      (current) => current.copyWith(
        medicines: [
          for (final item in current.medicines)
            if (item.id == medicine.id) medicine else item,
        ],
      ),
    );
  }

  void removeMedicine(String id) {
    _apply(
      (current) => current.copyWith(
        medicines: [
          for (final item in current.medicines)
            if (item.id != id) item,
        ],
      ),
    );
  }

  void moveMedicine(int index, int delta) {
    _apply((current) {
      final next = [...current.medicines];
      final target = index + delta;
      if (target < 0 || target >= next.length) return current;
      final item = next.removeAt(index);
      next.insert(target, item);
      return current.copyWith(medicines: next);
    });
  }

  bool addAdviceLine(String text) {
    final current = state.prescription;
    if (current == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (current.advice.contains(trimmed)) return false;
    _apply((value) => value.copyWith(advice: [...value.advice, trimmed]));
    return true;
  }

  void removeAdviceAt(int index) {
    _apply((current) {
      if (index < 0 || index >= current.advice.length) return current;
      final next = [...current.advice]..removeAt(index);
      return current.copyWith(advice: next);
    });
  }

  void moveAdvice(int index, int delta) {
    _apply((current) {
      final next = [...current.advice];
      final target = index + delta;
      if (target < 0 || target >= next.length) return current;
      final item = next.removeAt(index);
      next.insert(target, item);
      return current.copyWith(advice: next);
    });
  }

  void setNextVisit(DateTime? date) {
    _apply((current) => current.copyWith(nextVisit: date));
  }

  Future<bool> saveDraft({bool silent = false}) {
    return _save(finalize: false, silent: silent);
  }

  Future<bool> finalize() {
    return _save(finalize: true, silent: false);
  }

  Future<void> discardEdits() async {
    _autosave?.cancel();
    _generation++;
    final current = state.prescription;
    final wasNew = state.isNewSession;
    final baseline = _baseline;
    state = const EditorState();
    _baseline = null;
    if (current == null) return;
    try {
      if (wasNew) {
        await ref.read(prescriptionRepositoryProvider).delete(current.id);
      } else if (baseline != null) {
        await ref.read(prescriptionRepositoryProvider).save(baseline);
      }
      await _refreshLists();
    } catch (error) {
      AppLog.error('discard-prescription', error);
    }
  }

  Future<bool> deleteCurrent() async {
    final current = state.prescription;
    if (current == null) return false;
    _autosave?.cancel();
    _generation++;
    try {
      await ref.read(prescriptionRepositoryProvider).delete(current.id);
      state = const EditorState();
      _baseline = null;
      await _refreshLists();
      return true;
    } catch (error) {
      AppLog.error('delete-prescription', error);
      state = state.copyWith(saveError: 'failed');
      return false;
    }
  }

  Map<String, String> validate(Prescription prescription) {
    final patient = prescription.patient;
    final errors = <String, String>{};
    if (patient.name.trim().isEmpty) errors['name'] = 'name';
    if (patient.phone.trim().isEmpty) {
      errors['phone'] = 'phone';
    } else if (!isValidPhone(patient.phone)) {
      errors['phone'] = 'phone_invalid';
    }
    if (patient.age == null) {
      errors['age'] = 'age';
    } else if (patient.age! < 0 || patient.age! > 130) {
      errors['age'] = 'age_invalid';
    }
    if (patient.sex == null || patient.sex!.isEmpty) errors['sex'] = 'sex';
    return errors;
  }

  void _apply(Prescription Function(Prescription current) change) {
    final current = state.prescription;
    if (current == null) return;
    var next = change(current);
    var returned = state.returnedToDraft;
    if (!current.isDraft && next.bodyKey() != current.bodyKey()) {
      next = next.copyWith(isDraft: true);
      returned = true;
    }
    final dirty =
        _baseline == null ||
        next.bodyKey() != _baseline!.bodyKey() ||
        next.isDraft != _baseline!.isDraft;
    state = state.copyWith(
      prescription: next,
      dirty: dirty,
      returnedToDraft: returned,
      saveError: null,
      fieldErrors: const {},
      notice: null,
    );
    if (dirty && next.hasContent) _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      if (state.dirty) unawaited(saveDraft(silent: true));
    });
  }

  Future<bool> _save({required bool finalize, required bool silent}) async {
    while (_saving) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    final current = state.prescription;
    if (current == null) return false;
    if (finalize) {
      final errors = validate(current);
      if (errors.isNotEmpty) {
        state = state.copyWith(fieldErrors: errors, saveError: 'invalid');
        return false;
      }
    }
    final generation = _generation;
    final wasNew = state.isNewSession;
    final baseline = _baseline;
    final savedBody = current.bodyKey();
    _saving = true;
    state = state.copyWith(saving: true, saveError: null);
    try {
      final stored = (finalize ? current.copyWith(isDraft: false) : current)
          .copyWith(
            updatedAt: DateTime.now(),
            header: ref.read(profileProvider),
            documentLanguage: ref.read(settingsProvider).languageCode,
          );
      await ref.read(prescriptionRepositoryProvider).save(stored);
      await ref.read(patientRepositoryProvider).upsert(stored.patient);
      if (generation != _generation || _blockWrites) {
        if (wasNew || _blockWrites) {
          await ref.read(prescriptionRepositoryProvider).delete(stored.id);
          if (_blockWrites) {
            await ref.read(patientRepositoryProvider).delete(stored.patient.id);
          }
        } else if (baseline != null) {
          await ref.read(prescriptionRepositoryProvider).save(baseline);
        }
        await _refreshLists();
        return false;
      }
      final latest = state.prescription;
      final unchanged = latest != null && latest.bodyKey() == savedBody;
      if (unchanged) {
        _baseline = stored;
        state = state.copyWith(
          prescription: stored,
          dirty: false,
          saving: false,
          isNewSession: false,
          fieldErrors: const {},
          notice: silent ? null : 'saved',
          returnedToDraft: stored.isDraft && state.returnedToDraft,
        );
      } else {
        state = state.copyWith(saving: false, dirty: true);
        _scheduleAutosave();
      }
      await _refreshLists();
      return true;
    } catch (error) {
      AppLog.error('save-prescription', error);
      if (generation == _generation) {
        state = state.copyWith(saving: false, saveError: 'failed');
      }
      return false;
    } finally {
      _saving = false;
    }
  }

  Future<void> _refreshLists() async {
    try {
      await ref.read(prescriptionListProvider.notifier).refresh();
      await ref.read(patientListProvider.notifier).refresh();
    } catch (error) {
      AppLog.error('refresh-lists', error);
    }
  }
}
