import 'package:flutter_test/flutter_test.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/shop_group.dart';

void main() {
  group('groupByShop', () {
    test('returns empty groups for an empty list', () {
      final result = groupByShop([]);
      expect(result.open, isEmpty);
      expect(result.inCart, isEmpty);
    });

    test('groups open articles by shop in order of first appearance', () {
      const milk = Article(id: '1', shop: 'Edeka', article: 'Milch');
      const toothpaste = Article(id: '2', shop: 'dm', article: 'Zahnpasta');
      const bread = Article(id: '3', shop: 'Edeka', article: 'Brot');

      final result = groupByShop([milk, toothpaste, bread]);

      expect(result.open.map((g) => g.shop), ['Edeka', 'dm']);
      expect(result.open[0].articles, [milk, bread]);
      expect(result.open[1].articles, [toothpaste]);
    });

    test('keeps articles without shop in their own group', () {
      const salt = Article(id: '1', article: 'Salz');

      final result = groupByShop([salt]);

      expect(result.open.single.shop, '');
      expect(result.open.single.articles, [salt]);
    });

    test('separates articles in the cart regardless of shop', () {
      const milk = Article(id: '1', shop: 'Edeka', article: 'Milch');
      const cheese = Article(id: '2', shop: 'Edeka', article: 'Käse', inCart: true);

      final result = groupByShop([milk, cheese]);

      expect(result.open.single.articles, [milk]);
      expect(result.inCart, [cheese]);
    });
  });
}
