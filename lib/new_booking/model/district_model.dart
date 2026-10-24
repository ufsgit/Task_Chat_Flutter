/// Model representing an individual district dropdown item.
class DistrictItem {
  final int id;
  final String name;

  const DistrictItem({required this.id, required this.name});

  factory DistrictItem.fromJson(Map<String, dynamic> json) {
    return DistrictItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'DistrictItem(id: $id, name: $name)';
}

/// Model representing the API response for district dropdown listing.
class DistrictDropdownResponse {
  final String type;
  final int count;
  final int? page;
  final int? limit;
  final List<DistrictItem> data;

  const DistrictDropdownResponse({
    required this.type,
    required this.count,
    this.page,
    this.limit,
    required this.data,
  });

  factory DistrictDropdownResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => DistrictItem.fromJson(item))
              .toList()
        : <DistrictItem>[];

    return DistrictDropdownResponse(
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
