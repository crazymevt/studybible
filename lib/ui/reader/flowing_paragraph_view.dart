import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/content_store.dart';

class FlowingParagraphView extends StatefulWidget {
  final List<Verse> verses;
  final Set<int> selectedVerses;
  final ValueChanged<int> onVerseTap;

  const FlowingParagraphView({
    super.key,
    required this.verses,
    required this.selectedVerses,
    required this.onVerseTap,
  });

  @override
  State<FlowingParagraphView> createState() => _FlowingParagraphViewState();
}

class _FlowingParagraphViewState extends State<FlowingParagraphView> {
  late List<TapGestureRecognizer> _recognizers;

  @override
  void initState() {
    super.initState();
    _initRecognizers();
  }

  @override
  void didUpdateWidget(FlowingParagraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      _disposeRecognizers();
      _initRecognizers();
    }
  }

  void _initRecognizers() {
    _recognizers = widget.verses.map((v) {
      return TapGestureRecognizer()..onTap = () => widget.onVerseTap(v.verse);
    }).toList();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
      child: Text.rich(
        TextSpan(
          children: widget.verses.asMap().entries.map((entry) {
            final index = entry.key;
            final verse = entry.value;
            final isSelected = widget.selectedVerses.contains(verse.verse);
            final bgColor = isSelected 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                : null;
            final recognizer = _recognizers[index];

            return TextSpan(
              children: [
                TextSpan(
                  text: '${verse.verse} ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.superscripts()],
                        backgroundColor: bgColor,
                      ),
                  recognizer: recognizer,
                ),
                TextSpan(
                  text: '${verse.textContent} ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        backgroundColor: bgColor,
                      ),
                  recognizer: recognizer,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
