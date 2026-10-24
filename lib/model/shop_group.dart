import 'package:shoppinglist/model/article.dart';

class ShopGroup {
  final String shop;
  final List<Article> articles;

  const ShopGroup(this.shop, this.articles);
}

/// Groups the articles not yet in the cart by shop, keeping their order.
/// Articles already in the cart are returned separately.
({List<ShopGroup> open, List<Article> inCart}) groupByShop(List<Article> articles) {
  final open = <String, List<Article>>{};
  final inCart = <Article>[];
  for (final article in articles) {
    if (article.inCart) {
      inCart.add(article);
    } else {
      open.putIfAbsent(article.shop, () => []).add(article);
    }
  }
  return (
    open: [for (final entry in open.entries) ShopGroup(entry.key, entry.value)],
    inCart: inCart,
  );
}
