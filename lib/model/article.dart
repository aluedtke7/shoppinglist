class Article {
  final String id;
  final String shop;
  final String article;
  final int amount;
  final bool active;
  final bool inCart;

  const Article({
    this.id = '',
    this.shop = '',
    this.article = '',
    this.amount = 0,
    this.active = false,
    this.inCart = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] ?? '',
        shop: json['shop'] ?? '',
        article: json['article'] ?? '',
        amount: json['amount'] ?? 0,
        active: json['active'] ?? false,
        inCart: json['inCart'] ?? false,
      );

  Article copyWith({
    String? id,
    String? shop,
    String? article,
    int? amount,
    bool? active,
    bool? inCart,
  }) {
    return Article(
      id: id ?? this.id,
      shop: shop ?? this.shop,
      article: article ?? this.article,
      amount: amount ?? this.amount,
      active: active ?? this.active,
      inCart: inCart ?? this.inCart,
    );
  }

  Map<String, dynamic> toJson() => {
        'shop': shop,
        'article': article,
        'amount': amount,
        'active': active,
        'inCart': inCart,
      };
}
