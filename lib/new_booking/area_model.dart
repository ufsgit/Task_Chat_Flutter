/// Model representing an individual dropdown item (e.g. area, district).
class AreaItem {
  final int id;
  final String name;

  const AreaItem({required this.id, required this.name});

  factory AreaItem.fromJson(Map<String, dynamic> json) {
    return AreaItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'AreaItem(id: $id, name: $name)';
}

/// Model representing the API response for dropdown listings.
class AreaDropdownResponse {
  final String type;
  final int count;
  final int? page;
  final int? limit;
  final List<AreaItem> data;

  const AreaDropdownResponse({
    required this.type,
    required this.count,
    this.page,
    this.limit,
    required this.data,
  });

  factory AreaDropdownResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => AreaItem.fromJson(item))
            .toList()
        : <AreaItem>[];

    return AreaDropdownResponse(
      type: json['type']?.toString() ?? '',
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse(json['count']?.toString() ?? '0') ?? items.length,
      page: json['page'] is int
          ? json['page'] as int
          : int.tryParse(json['page']?.toString() ?? ''),
      limit: json['limit'] is int
          ? json['limit'] as int
          : int.tryParse(json['limit']?.toString() ?? ''),
      data: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'count': count,
    if (page != null) 'page': page,
    if (limit != null) 'limit': limit,
    'data': data.map((item) => item.toJson()).toList(),
  };
}
