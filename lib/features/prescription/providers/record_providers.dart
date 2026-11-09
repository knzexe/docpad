import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repository_providers.dart';
import '../../advice/models/advice_template.dart';
import '../../patients/models/patient.dart';
import '../models/prescription.dart';

final prescriptionListProvider =
    AsyncNotifierProvider<PrescriptionListNotifier, List<Prescription>>(
      PrescriptionListNotifier.new,
    );

class PrescriptionListNotifier extends AsyncNotifier<List<Prescription>> {
  @override
  Future<List<Prescription>> build() {
    return ref.read(prescriptionRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(prescriptionRepositoryProvider).getAll());
  }
}

final patientListProvider =
    AsyncNotifierProvider<PatientListNotifier, List<Patient>>(
      PatientListNotifier.new,
    );

class PatientListNotifier extends AsyncNotifier<List<Patient>> {
  @override
  Future<List<Patient>> build() {
    return ref.read(patientRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(patientRepositoryProvider).getAll());
  }

  Future<void> delete(String id) async {
    await ref.read(patientRepositoryProvider).delete(id);
    await refresh();
  }
}

final adviceListProvider =
    AsyncNotifierProvider<AdviceListNotifier, List<AdviceTemplate>>(
      AdviceListNotifier.new,
    );

class AdviceListNotifier extends AsyncNotifier<List<AdviceTemplate>> {
  @override
  Future<List<AdviceTemplate>> build() {
    return ref.read(adviceRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(adviceRepositoryProvider).getAll());
  }

  Future<void> save(AdviceTemplate template) async {
    await ref.read(adviceRepositoryProvider).save(template);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(adviceRepositoryProvider).delete(id);
    await refresh();
  }

  Future<void> reorder(int index, int delta) async {
    final current = state.asData?.value;
    if (current == null) return;
    final target = index + delta;
    if (target < 0 || target >= current.length) return;
    final next = [...current];
    final item = next.removeAt(index);
    next.insert(target, item);
    for (var i = 0; i < next.length; i++) {
      await ref
          .read(adviceRepositoryProvider)
          .save(next[i].copyWith(sortOrder: i, updatedAt: DateTime.now()));
    }
    await refresh();
  }
}
