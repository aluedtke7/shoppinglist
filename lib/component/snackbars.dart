import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) async {
  final String msg;
  if (e is ClientException) {
    String? errMsg = e.originalError?.toString();
    errMsg ??= e.response.entries.firstWhere((element) => element.key == 'message').value;
    msg = 'Error\nServer ${e.url?.host}\n$errMsg';
  } else {
    msg = e.toString();
  }

  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(ctx).colorScheme.error,
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
      duration: const Duration(milliseconds: 5000),
      padding: const EdgeInsets.all(8.0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    ),
  );
}

Future<void> showInfoSnackbar(BuildContext ctx, dynamic e) async {
  final String msg = e.toString();

  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(ctx).colorScheme.primary,
      content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(ctx).cardTheme.color)),
      duration: const Duration(milliseconds: 3000),
      padding: const EdgeInsets.all(8.0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    ),
  );
}
