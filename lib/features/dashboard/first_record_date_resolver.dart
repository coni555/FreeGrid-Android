import '../../core/data/backup_codec.dart';
import '../../core/domain/freedom_math.dart';

DateTime resolveFirstRecordDate(BackupData data, DateTime fallback) {
  final declared = data.firstRecordDate ?? data.assets?.firstRecordDate;
  if (declared != null) return FreedomMath.startOfDay(declared);

  final inferred = [
    ...data.expenses.map((expense) => expense.date),
    ...data.incomes.map((income) => income.date),
    fallback,
  ]..sort((a, b) => a.compareTo(b));
  return FreedomMath.startOfDay(inferred.first);
}

DateTime resolveFirstRecordDateForMutation(
  BackupData data,
  DateTime candidate,
) {
  final current = resolveFirstRecordDate(data, candidate);
  final candidateDay = FreedomMath.startOfDay(candidate);
  return candidateDay.isBefore(current) ? candidateDay : current;
}
