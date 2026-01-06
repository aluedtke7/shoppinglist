import 'package:flutter/material.dart';
import 'package:shoppinglist/component/i18n_util.dart';

class NoArticleWidget extends StatelessWidget {
  const NoArticleWidget({super.key, this.height = 1.5});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        i18n(context).p_active_empty,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
          height: height,
        ),
      ),
    );
  }
}
