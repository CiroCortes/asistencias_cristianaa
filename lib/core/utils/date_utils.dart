/// Calcula el número de semana según ISO 8601.
///
/// Reglas ISO 8601:
///   - Las semanas van de lunes a domingo.
///   - La semana 1 es la que contiene el primer jueves del año
///     (equivalente: la semana que contiene el 4 de enero).
///   - El jueves de la semana determina a qué año ISO pertenece la semana.
///
/// Ejemplo: 23 feb 2026 → semana 9.
int getWeekNumber(DateTime date) {
  // El jueves de la semana actual define el año ISO de esa semana.
  final thursday = DateTime(date.year, date.month, date.day)
      .add(Duration(days: DateTime.thursday - date.weekday));

  // La semana 1 del año ISO es la que contiene el 4 de enero.
  final jan4 = DateTime(thursday.year, 1, 4);

  // Lunes de la semana 1.
  final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));

  // Lunes de la semana que contiene 'date'.
  final currentMonday = DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - 1));

  return (currentMonday.difference(week1Monday).inDays ~/ 7) + 1;
}
