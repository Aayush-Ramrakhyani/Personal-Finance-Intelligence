import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/import_provider.dart';
import '../../data/import_models.dart';
import 'import_preview_screen.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(importWizardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Import Transactions',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        leading: wizardState.step != ImportStep.upload
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
                onPressed: () =>
                    ref.read(importWizardProvider.notifier).goBack(),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: wizardState.step),

          // Error banner
          if (wizardState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF5252).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF5252), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wizardState.error!,
                      style: const TextStyle(
                          color: Color(0xFFFF5252), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _buildStepContent(context, ref, wizardState),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      BuildContext context, WidgetRef ref, ImportWizardState state) {
    switch (state.step) {
      case ImportStep.upload:
        return _UploadStep(
          isLoading: state.isLoading,
          onUpload: (path, name) => ref
              .read(importWizardProvider.notifier)
              .uploadFile(path, name),
        );
      case ImportStep.mapping:
        return _MappingStep(
          detectedColumns: state.job?.detectedColumns ?? [],
          mapping: state.columnMapping,
          isLoading: state.isLoading,
          onMappingChanged: (col, field) => ref
              .read(importWizardProvider.notifier)
              .updateColumnMapping(col, field),
          onNext: () =>
              ref.read(importWizardProvider.notifier).fetchPreview(),
        );
      case ImportStep.preview:
        if (state.preview != null) {
          return ImportPreviewScreen(
            preview: state.preview!,
            excludedIds: state.excludedIds,
            onToggle: (id) =>
                ref.read(importWizardProvider.notifier).toggleExclude(id),
            onConfirm: () =>
                ref.read(importWizardProvider.notifier).goToConfirm(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      case ImportStep.confirm:
        return _ConfirmStep(
          preview: state.preview!,
          excludedCount: state.excludedIds.length,
          isLoading: state.isLoading,
          onConfirm: () =>
              ref.read(importWizardProvider.notifier).confirmImport(),
        );
      case ImportStep.progress:
        return const _ProgressStep();
      case ImportStep.result:
        return _ResultStep(
          result: state.result!,
          onDone: () {
            ref.read(importWizardProvider.notifier).reset();
            Navigator.pop(context);
          },
          onImportMore: () =>
              ref.read(importWizardProvider.notifier).reset(),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------
class _StepIndicator extends StatelessWidget {
  final ImportStep currentStep;

  const _StepIndicator({required this.currentStep});

  int get _stepIndex {
    switch (currentStep) {
      case ImportStep.upload:
        return 0;
      case ImportStep.mapping:
        return 1;
      case ImportStep.preview:
        return 2;
      case ImportStep.confirm:
        return 3;
      case ImportStep.progress:
      case ImportStep.result:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Upload', 'Map', 'Preview', 'Confirm', 'Done'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < _stepIndex
                    ? const Color(0xFF00C896)
                    : Colors.white12,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx < _stepIndex;
          final isCurrent = stepIdx == _stepIndex;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF00C896)
                      : isCurrent
                          ? const Color(0xFF00C896).withOpacity(0.2)
                          : Colors.white12,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? const Color(0xFF00C896)
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 14)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? const Color(0xFF00C896)
                                : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIdx],
                style: TextStyle(
                  color: isCompleted || isCurrent
                      ? const Color(0xFF00C896)
                      : Colors.white38,
                  fontSize: 10,
                  fontWeight: isCurrent
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Upload
// ---------------------------------------------------------------------------
class _UploadStep extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function(String path, String name) onUpload;

  const _UploadStep({required this.isLoading, required this.onUpload});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      await onUpload(
        result.files.single.path!,
        result.files.single.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload your bank statement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We support CSV exports from most Indian banks.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Drop zone
          GestureDetector(
            onTap: isLoading ? null : () => _pickFile(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F36),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLoading
                      ? const Color(0xFF00C896)
                      : const Color(0xFF00C896).withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  if (isLoading)
                    const CircularProgressIndicator(
                      color: Color(0xFF00C896),
                    )
                  else ...[
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C896)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF00C896),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to select file',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CSV files supported',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Supported formats',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ..._supportedBanks.map((bank) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C896),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      bank,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static const List<String> _supportedBanks = [
    'HDFC Bank Statement (CSV)',
    'ICICI Bank Statement (CSV)',
    'SBI Bank Statement (CSV)',
    'Axis Bank Statement (CSV)',
    'Kotak Bank Statement (CSV)',
    'Any bank CSV with date, description, amount columns',
  ];
}

// ---------------------------------------------------------------------------
// Step 2: Mapping
// ---------------------------------------------------------------------------
class _MappingStep extends StatelessWidget {
  final List<String> detectedColumns;
  final Map<String, String> mapping;
  final bool isLoading;
  final void Function(String col, String field) onMappingChanged;
  final VoidCallback onNext;

  static const List<String> _appFields = [
    'date',
    'description',
    'amount',
    'type',
    'category',
    '(skip)',
  ];

  static const Map<String, String> _fieldLabels = {
    'date': 'Date',
    'description': 'Description / Merchant',
    'amount': 'Amount',
    'type': 'Type (income/expense)',
    'category': 'Category',
    '(skip)': 'Skip this column',
  };

  const _MappingStep({
    required this.detectedColumns,
    required this.mapping,
    required this.isLoading,
    required this.onMappingChanged,
    required this.onNext,
  });

  bool get _isValid {
    final mapped = mapping.values.toSet();
    return mapped.contains('date') &&
        mapped.contains('description') &&
        mapped.contains('amount');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map your CSV columns',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us which CSV column maps to which field.',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFFC107).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFFFFC107), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Date, Description and Amount are required',
                        style: TextStyle(
                            color: Color(0xFFFFC107), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (detectedColumns.isEmpty)
                  const Center(
                    child: Text(
                      'No columns detected. Please re-upload.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  ...detectedColumns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CSV column: "$col"',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: mapping[col],
                            hint: const Text(
                              'Select field...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                            dropdownColor: const Color(0xFF252B45),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1A1F36),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00C896), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            items: _appFields.map((field) {
                              return DropdownMenuItem(
                                value: field,
                                child: Text(
                                  _fieldLabels[field] ?? field,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                onMappingChanged(col, value);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (isLoading || !_isValid) ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Preview Import',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Confirm
// ---------------------------------------------------------------------------
class _ConfirmStep extends StatelessWidget {
  final ImportPreviewModel preview;
  final int excludedCount;
  final bool isLoading;
  final VoidCallback onConfirm;

  const _ConfirmStep({
    required this.preview,
    required this.excludedCount,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final toImport =
        preview.newTransactions - excludedCount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Import',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _ConfirmStat(
              label: 'Total rows in file',
              value: '${preview.totalRows}'),
          _ConfirmStat(
              label: 'New transactions',
              value: '$toImport',
              valueColor: const Color(0xFF00C896)),
          _ConfirmStat(
              label: 'Duplicates (skipped)',
              value: '${preview.duplicates}',
              valueColor: const Color(0xFFFFC107)),
          _ConfirmStat(
              label: 'Manually excluded',
              value: '$excludedCount',
              valueColor: Colors.white54),
          _ConfirmStat(
              label: 'Errors',
              value: '${preview.errors}',
              valueColor: preview.errors > 0
                  ? const Color(0xFFFF5252)
                  : Colors.white54),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onConfirm,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                'Import $toImport transactions',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ConfirmStat(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5: Progress
// ---------------------------------------------------------------------------
class _ProgressStep extends StatelessWidget {
  const _ProgressStep();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00C896)),
          SizedBox(height: 24),
          Text(
            'Importing transactions...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait, this may take a moment.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 6: Result
// ---------------------------------------------------------------------------
class _ResultStep extends StatelessWidget {
  final ImportResultModel result;
  final VoidCallback onDone;
  final VoidCallback onImportMore;

  const _ResultStep({
    required this.result,
    required this.onDone,
    required this.onImportMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00C896),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Import Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: const TextStyle(
                color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ConfirmStat(
            label: 'Transactions imported',
            value: '${result.imported}',
            valueColor: const Color(0xFF00C896),
          ),
          _ConfirmStat(
            label: 'Skipped (duplicates)',
            value: '${result.skipped}',
            valueColor: Colors.white54,
          ),
          if (result.failed > 0)
            _ConfirmStat(
              label: 'Failed',
              value: '${result.failed}',
              valueColor: const Color(0xFFFF5252),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onImportMore,
            child: const Text(
              'Import another file',
              style: TextStyle(color: Color(0xFF00C896)),
            ),
          ),
        ],
      ),
    );
  }
}
