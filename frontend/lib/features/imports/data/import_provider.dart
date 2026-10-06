import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'import_models.dart';
import 'import_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final _importDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository(ref.watch(_importDioProvider));
});

// ---------------------------------------------------------------------------
// Import wizard state
// ---------------------------------------------------------------------------

enum ImportStep { upload, mapping, preview, confirm, progress, result }

class ImportWizardState {
  final ImportStep step;
  final ImportJobModel? job;
  final Map<String, String> columnMapping;
  final ImportPreviewModel? preview;
  final Set<String> excludedIds;
  final ImportResultModel? result;
  final bool isLoading;
  final String? error;

  const ImportWizardState({
    this.step = ImportStep.upload,
    this.job,
    this.columnMapping = const {},
    this.preview,
    this.excludedIds = const {},
    this.result,
    this.isLoading = false,
    this.error,
  });

  ImportWizardState copyWith({
    ImportStep? step,
    ImportJobModel? job,
    Map<String, String>? columnMapping,
    ImportPreviewModel? preview,
    Set<String>? excludedIds,
    ImportResultModel? result,
    bool? isLoading,
    String? error,
  }) {
    return ImportWizardState(
      step: step ?? this.step,
      job: job ?? this.job,
      columnMapping: columnMapping ?? this.columnMapping,
      preview: preview ?? this.preview,
      excludedIds: excludedIds ?? this.excludedIds,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ImportWizardNotifier extends Notifier<ImportWizardState> {
  @override
  ImportWizardState build() => const ImportWizardState();

  Future<void> uploadFile(String filePath, String fileName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final job = await ref
          .read(importRepositoryProvider)
          .uploadCSV(filePath, fileName);
      state = state.copyWith(
        job: job,
        step: ImportStep.mapping,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateColumnMapping(String csvColumn, String appField) {
    final updated = Map<String, String>.from(state.columnMapping);
    updated[csvColumn] = appField;
    state = state.copyWith(columnMapping: updated);
  }

  Future<void> fetchPreview() async {
    if (state.job == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final preview = await ref
          .read(importRepositoryProvider)
          .getPreview(state.job!.id, state.columnMapping);
      state = state.copyWith(
        preview: preview,
        step: ImportStep.preview,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleExclude(String id) {
    final updated = Set<String>.from(state.excludedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(excludedIds: updated);
  }

  void goToConfirm() {
    state = state.copyWith(step: ImportStep.confirm);
  }

  Future<void> confirmImport() async {
    if (state.job == null) return;
    state = state.copyWith(
        isLoading: true, step: ImportStep.progress, error: null);
    try {
      final result = await ref
          .read(importRepositoryProvider)
          .confirmImport(state.job!.id, state.excludedIds.toList());
      state = state.copyWith(
        result: result,
        step: ImportStep.result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        step: ImportStep.confirm,
      );
    }
  }

  void reset() {
    state = const ImportWizardState();
  }

  void goBack() {
    switch (state.step) {
      case ImportStep.mapping:
        state = state.copyWith(step: ImportStep.upload);
        break;
      case ImportStep.preview:
        state = state.copyWith(step: ImportStep.mapping);
        break;
      case ImportStep.confirm:
        state = state.copyWith(step: ImportStep.preview);
        break;
      default:
        break;
    }
  }
}

final importWizardProvider =
    NotifierProvider<ImportWizardNotifier, ImportWizardState>(
        ImportWizardNotifier.new);
