import 'package:flutter_test/flutter_test.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/recipe.dart';

void main() {
  group('Article Model', () {
    test('fromJson should create a valid Article', () {
      final json = {
        'id': '123',
        'shop': 'Test Shop',
        'article': 'Test Article',
        'amount': 5,
        'active': true,
        'inCart': false,
      };
      final article = Article.fromJson(json);
      expect(article.id, '123');
      expect(article.shop, 'Test Shop');
      expect(article.article, 'Test Article');
      expect(article.amount, 5);
      expect(article.active, true);
      expect(article.inCart, false);
    });

    test('copyWith should update fields correctly', () {
      const article = Article(id: '1', shop: 'S1', article: 'A1');
      final updated = article.copyWith(amount: 10, inCart: true);
      expect(updated.id, '1');
      expect(updated.shop, 'S1');
      expect(updated.article, 'A1');
      expect(updated.amount, 10);
      expect(updated.inCart, true);
    });

    test('toJson should return correct map', () {
      const article = Article(id: '1', shop: 'S1', article: 'A1', amount: 2, active: true, inCart: false);
      final json = article.toJson();
      expect(json['shop'], 'S1');
      expect(json['article'], 'A1');
      expect(json['amount'], 2);
      expect(json['active'], true);
      expect(json['inCart'], false);
    });
  });

  group('Recipe Model', () {
    test('fromJson should create a valid Recipe', () {
      final json = {'id': 'r1', 'name': 'Pasta', 'notes': 'Yummy'};
      final recipe = Recipe.fromJson(json);
      expect(recipe.id, 'r1');
      expect(recipe.name, 'Pasta');
      expect(recipe.notes, 'Yummy');
    });

    test('copyWith should update fields correctly', () {
      const recipe = Recipe(id: 'r1', name: 'Pasta');
      final updated = recipe.copyWith(notes: 'Add salt');
      expect(updated.id, 'r1');
      expect(updated.name, 'Pasta');
      expect(updated.notes, 'Add salt');
    });
  });
}
