import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repository_providers.dart';
import '../models/medicine.dart';

final medicineLibraryProvider =
    AsyncNotifierProvider<MedicineLibraryNotifier, List<Medicine>>(
      MedicineLibraryNotifier.new,
    );

class MedicineLibraryNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() =>
      ref.read(medicineRepositoryProvider).getAll();

  Future<void> save({
    String? id,
    required String brandName,
    String? genericName,
    String? strength,
    String? dosageForm,
    String? manufacturer,
    String? category,
    String? notes,
  }) async {
    final trimmedBrand = brandName.trim();
    if (trimmedBrand.isEmpty) {
      throw const FormatException('Brand name is required');
    }
    final now = DateTime.now();
    final existing = id == null
        ? null
        : state.asData?.value.where((item) => item.id == id).firstOrNull;
    final medicine = Medicine(
      id: id ?? const Uuid().v4(),
      brandName: trimmedBrand,
      genericName: _clean(genericName),
      strength: _clean(strength),
      dosageForm: _clean(dosageForm),
      manufacturer: _clean(manufacturer),
      category: _clean(category),
      notes: _clean(notes),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(medicineRepositoryProvider).upsert(medicine);
    state = AsyncData(await ref.read(medicineRepositoryProvider).getAll());
  }

  Future<void> remove(String id) async {
    await ref.read(medicineRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(medicineRepositoryProvider).getAll());
  }

  static String? _clean(String? value) {
    final result = value?.trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
