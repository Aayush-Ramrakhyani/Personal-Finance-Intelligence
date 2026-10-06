import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_models.dart';
import '../../data/budget_provider.dart';
import '../../../../shared/widgets/category_chip.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategory;
  String _selectedPeriod = 'monthly';
  double _alertThreshold = 80.0;
  bool _isLoading = false;

  static const List<String> _periods = ['weekly', 'monthly', 'yearly'];
  static const Map<String, String> _periodLabels = {
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'yearly': 'Yearly',
  };

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = BudgetCreateRequest(
        category: _selectedCategory!,
        categoryIcon: _selectedCategory!.toLowerCase(),
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        period: _selectedPeriod,
        alertThreshold: _alertThreshold,
      );
      await ref
          .read(budgetNotifierProvider.notifier)
          .createBudget(request);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully'),
            backgroundColor: Color(0xFF00C896),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Add Budget',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 12),
              CategorySelector(
                selected: _selectedCategory,
                onSelected: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 24),

              // Amount
              _SectionLabel(label: 'Budget Amount'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: '0',
                  hintStyle:
                      const TextStyle(color: Colors.white24, fontSize: 18),
                  filled: true,
                  fillColor: const Color(0xFF1A1F36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C896), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final num = double.tryParse(v.replaceAll(',', ''));
                  if (num == null || num <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Period
              _SectionLabel(label: 'Budget Period'),
              const SizedBox(height: 12),
              Row(
                children: _periods.map((p) {
                  final isSelected = _selectedPeriod == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPeriod = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00C896).withOpacity(0.15)
                                : const Color(0xFF1A1F36),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00C896)
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            _periodLabels[p]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00C896)
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Alert threshold
              _SectionLabel(
                  label:
                      'Alert Threshold: ${_alertThreshold.toInt()}%'),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  thumbColor: const Color(0xFF00C896),
                  activeTrackColor: const Color(0xFF00C896),
                  inactiveTrackColor:
                      Colors.white.withOpacity(0.1),
                  overlayColor:
                      const Color(0xFF00C896).withOpacity(0.2),
                ),
                child: Slider(
                  value: _alertThreshold,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  onChanged: (v) =>
                      setState(() => _alertThreshold = v),
                ),
              ),
              Text(
                'You\'ll be alerted when you reach ${_alertThreshold.toInt()}% of your budget',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 40),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor:
                        const Color(0xFF00C896).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Create Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
