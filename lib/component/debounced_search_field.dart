import 'dart:async';

import 'package:flutter/material.dart';

class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    required this.hintText,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 750),
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final Duration debounce;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        prefixIcon: const Icon(Icons.search),
      ),
      autofocus: widget.autofocus,
      onChanged: (text) {
        _timer?.cancel();
        _timer = Timer(widget.debounce, () {
          widget.onChanged(text);
        });
      },
    );
  }
}
