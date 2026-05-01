import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shoppinglist/component/i18n_util.dart';

class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 750),
  });

  final ValueChanged<String> onChanged;
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
      decoration: InputDecoration(labelText: i18n(context).com_search_term),
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
