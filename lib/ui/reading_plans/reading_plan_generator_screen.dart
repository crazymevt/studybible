// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/reading_plan_providers.dart';
import '../../app/sync_service.dart';
import '../../app/achievement_service.dart';

class ReadingPlanGeneratorScreen extends ConsumerStatefulWidget {
  const ReadingPlanGeneratorScreen({super.key});

  @override
  ConsumerState<ReadingPlanGeneratorScreen> createState() =>
      _ReadingPlanGeneratorScreenState();
}

class _ReadingPlanGeneratorScreenState
    extends ConsumerState<ReadingPlanGeneratorScreen> {
  int _currentStep = 0;
  bool _isCustom = false;
  bool _isGenerating = false;

  // Common
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _startDate = DateTime.now();

  // Pre-curated
  String _selectedJsonAsset = 'assets/reading_plans/mcheyne.json';

  final Map<String, String> _preCuratedPlans = {
    'assets/reading_plans/mcheyne.json': "M'Cheyne Reading Plan (1 Year)",
    'assets/reading_plans/oneyearchronological.json':
        "Chronological Bible (1 Year)",
    'assets/reading_plans/esvthroughthebible.json': "Through the Bible",
    'assets/reading_plans/esveverydayinword.json': "Every Day in the Word",
    'assets/reading_plans/heartlightotandnt.json': "Heartlight OT & NT",
    'assets/reading_plans/backtothebiblechronological.json':
        "Back to the Bible Chronological",
    'assets/reading_plans/esvchroniclesandprophets.json':
        "Chronicles & Prophets",
    'assets/reading_plans/esvgospelsandepistles.json': "Gospels & Epistles",
    'assets/reading_plans/esvliterarystudybible.json': "Literary Study Bible",
    'assets/reading_plans/esvpentateuchandhistoryofisrael.json':
        "Pentateuch & History",
    'assets/reading_plans/esvpsalmsandwisdomliterature.json': "Psalms & Wisdom",
  };

  // Custom
  int _durationDays = 30;
  final List<String> _selectedBooks = [];

  final List<String> _otBooks = [
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    'Joshua',
    'Judges',
    'Ruth',
    '1 Samuel',
    '2 Samuel',
    '1 Kings',
    '2 Kings',
    '1 Chronicles',
    '2 Chronicles',
    'Ezra',
    'Nehemiah',
    'Esther',
    'Job',
    'Psalms',
    'Proverbs',
    'Ecclesiastes',
    'Song of Solomon',
    'Isaiah',
    'Jeremiah',
    'Lamentations',
    'Ezekiel',
    'Daniel',
    'Hosea',
    'Joel',
    'Amos',
    'Obadiah',
    'Jonah',
    'Micah',
    'Nahum',
    'Habakkuk',
    'Zephaniah',
    'Haggai',
    'Zechariah',
    'Malachi',
  ];

  final List<String> _ntBooks = [
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1 Corinthians',
    '2 Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1 Thessalonians',
    '2 Thessalonians',
    '1 Timothy',
    '2 Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1 Peter',
    '2 Peter',
    '1 John',
    '2 John',
    '3 John',
    'Jude',
    'Revelation',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _generate() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    if (_isCustom && _selectedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one book.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final generator = ref.read(readingPlanGeneratorProvider);
      final deviceId =
          await ref.read(deviceIdProvider.future) as String? ?? 'unknown';

      if (_isCustom) {
        await generator.generateCustomPlan(
          planTitle: _titleController.text.trim(),
          planDescription: _descController.text.trim(),
          bookNames: _selectedBooks,
          durationDays: _durationDays,
          startDate: _startDate,
          deviceId: deviceId,
        );
      } else {
        await generator.generateFromJsonAsset(
          assetPath: _selectedJsonAsset,
          planTitle: _titleController.text.trim(),
          planDescription: _descController.text.trim(),
          startDate: _startDate,
          deviceId: deviceId,
        );
      }
      ref.read(achievementServiceProvider).evaluateAchievements();

      if (mounted) {
        Navigator.of(context).pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Reading Plan')),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _generate();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              controlsBuilder: (context, details) {
                final isLast = _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: Text(isLast ? 'Generate Plan' : 'Continue'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Plan Type'),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Pre-curated Plan'),
                        subtitle: const Text(
                          'Choose from popular established reading plans',
                        ),
                        value: false,
                        groupValue: _isCustom,
                        onChanged: (val) => setState(() {
                          _isCustom = val!;
                          _titleController.text =
                              _preCuratedPlans[_selectedJsonAsset] ?? '';
                        }),
                      ),
                      RadioListTile<bool>(
                        title: const Text('Custom Plan'),
                        subtitle: const Text(
                          'Select specific books and a target duration',
                        ),
                        value: true,
                        groupValue: _isCustom,
                        onChanged: (val) => setState(() {
                          _isCustom = val!;
                          _titleController.text = 'My Custom Plan';
                        }),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Plan Details'),
                  isActive: _currentStep >= 1,
                  content: _isCustom
                      ? _buildCustomForm()
                      : _buildPreCuratedForm(),
                ),
                Step(
                  title: const Text('Schedule & Info'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Plan Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreCuratedForm() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedJsonAsset,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Plan',
        border: OutlineInputBorder(),
      ),
      items: _preCuratedPlans.entries.map((e) {
        return DropdownMenuItem(
          value: e.key,
          child: Text(e.value, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedJsonAsset = val;
            _titleController.text = _preCuratedPlans[val] ?? '';
          });
        }
      },
    );
  }

  Widget _buildCustomForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _durationDays.toString(),
          decoration: const InputDecoration(
            labelText: 'Duration (Days)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final days = int.tryParse(val);
            if (days != null && days > 0) {
              setState(() => _durationDays = days);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selected Books',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedBooks.clear();
                  _selectedBooks.addAll(_otBooks);
                  _selectedBooks.addAll(_ntBooks);
                });
              },
              child: const Text('Select All'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _selectedBooks
              .map(
                (b) => Chip(
                  label: Text(b),
                  onDeleted: () => setState(() => _selectedBooks.remove(b)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () async {
            // Show multi-select dialog for books
            await showDialog(
              context: context,
              builder: (c) {
                return StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      title: const Text('Select Books'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          children: [
                            const ListTile(
                              title: Text(
                                'Old Testament',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ..._otBooks.map(
                              (b) => CheckboxListTile(
                                title: Text(b),
                                value: _selectedBooks.contains(b),
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      _selectedBooks.add(b);
                                    } else {
                                      _selectedBooks.remove(b);
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                            const ListTile(
                              title: Text(
                                'New Testament',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ..._ntBooks.map(
                              (b) => CheckboxListTile(
                                title: Text(b),
                                value: _selectedBooks.contains(b),
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      _selectedBooks.add(b);
                                    } else {
                                      _selectedBooks.remove(b);
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Done'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: const Text('Add Books'),
        ),
      ],
    );
  }
}
