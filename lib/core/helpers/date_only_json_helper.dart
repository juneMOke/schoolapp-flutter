class DateOnlyJsonHelper {
  const DateOnlyJsonHelper._();

  static DateTime fromJson(String value) => DateTime.parse(value);

  static String toJson(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
