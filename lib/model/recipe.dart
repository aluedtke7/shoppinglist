class Recipe {
  String id;
  String name;
  String notes;

  Recipe({this.id = '', this.name = '', this.notes = ''});

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      Recipe(id: json['id'] ?? '', name: json['name'] ?? '', notes: json['notes'] ?? '');

  Map<String, dynamic> toMap() => {'name': name, 'notes': notes};
}
