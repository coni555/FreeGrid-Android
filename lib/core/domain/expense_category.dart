class ExpenseCategorySuggestion {
  const ExpenseCategorySuggestion({
    required this.canonical,
    required this.known,
  });

  final String canonical;
  final bool known;
}

/// The only category vocabulary stored by FreeGrid.
///
/// Manual bookkeeping and JSON import both resolve through this source so
/// History never contains a category that the user cannot select later.
class ExpenseCategory {
  static const canonical = [
    '早餐',
    '午餐',
    '晚餐',
    '购物',
    '交通',
    '娱乐',
    '成长投资',
    '医疗',
    '其他',
  ];

  static const fallback = '其他';

  static const aliases = <String, String>{
    'transport': '交通',
    'transportation': '交通',
    'shopping': '购物',
    'shop': '购物',
    'entertainment': '娱乐',
    'medical': '医疗',
    'health': '医疗',
    'other': '其他',
    'others': '其他',
    'misc': '其他',
    'growth': '成长投资',
    'investment': '成长投资',
    '数码': '购物',
  };

  static ExpenseCategorySuggestion suggest(String raw) {
    final trimmed = raw.trim();
    if (canonical.contains(trimmed)) {
      return ExpenseCategorySuggestion(canonical: trimmed, known: true);
    }

    final mapped = aliases[trimmed] ?? aliases[trimmed.toLowerCase()];
    if (mapped != null) {
      return ExpenseCategorySuggestion(canonical: mapped, known: true);
    }

    return const ExpenseCategorySuggestion(canonical: fallback, known: false);
  }
}
