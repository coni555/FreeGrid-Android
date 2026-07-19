import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/domain/expense_category.dart';

void main() {
  group('ExpenseCategory', () {
    test('canonical list stays aligned with iOS source of truth', () {
      expect(ExpenseCategory.canonical, [
        '早餐',
        '午餐',
        '晚餐',
        '购物',
        '交通',
        '娱乐',
        '成长投资',
        '医疗',
        '其他',
      ]);
    });

    test('suggests only high-confidence imported aliases', () {
      expect(ExpenseCategory.suggest('shopping').canonical, '购物');
      expect(ExpenseCategory.suggest(' Shopping ').canonical, '购物');
      expect(ExpenseCategory.suggest('数码').canonical, '购物');
      expect(ExpenseCategory.suggest('food').known, isFalse);
      expect(ExpenseCategory.suggest('food').canonical, '其他');
    });
  });
}
