class SearchFilterState {
  final String query;
  final String? category;
  final double? priceMin;
  final double? priceMax;
  final double? minRating;
  final String sortBy;

  const SearchFilterState({
    this.query = '',
    this.category,
    this.priceMin,
    this.priceMax,
    this.minRating,
    this.sortBy = 'relevance',
  });

  SearchFilterState copyWith({
    String? query,
    String? category,
    double? priceMin,
    double? priceMax,
    double? minRating,
    String? sortBy,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'query': query,
      'sortBy': sortBy,
    };
    if (category != null) payload['category'] = category;
    if (priceMin != null) payload['priceMin'] = priceMin;
    if (priceMax != null) payload['priceMax'] = priceMax;
    if (minRating != null) payload['minRating'] = minRating;
    return payload;
  }
}
