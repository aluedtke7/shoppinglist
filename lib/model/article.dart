class Article {
  String id = '';
  String shop = '';
  String article = '';
  int amount = 0;
  bool active = false;
  bool bought = false;

  Article({
    this.id = '',
    this.shop = '',
    this.article = '',
    this.amount = 0,
    this.active = false,
    this.bought = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        shop: json['shop'],
        article: json['article'],
        amount: json['amount'],
        active: json['active'],
        bought: json['bought'],
      );
}
