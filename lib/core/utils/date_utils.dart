int getWeekNumber(DateTime date) {
  // Ajustar la fecha para que el lunes sea el primer día de la semana
  // y la semana 1 sea la que contiene el 4 de enero.
  DateTime jan4 = DateTime(date.year, 1, 4);
  int yearStartWeekday = jan4.weekday;

  DateTime week1Start;
  // En ISO 8601, la semana 1 es la primera semana con al menos 4 días en el nuevo año.
  // O, equivalentemente, la semana que contiene el primer jueves del año.
  // Si el 4 de enero está en la semana 1, su número de día de la semana determinará el inicio de la semana 1.
  if (yearStartWeekday <= DateTime.thursday) {
    week1Start = jan4.subtract(Duration(days: yearStartWeekday - DateTime.monday));
  } else {
    week1Start = jan4.add(Duration(days: DateTime.monday - yearStartWeekday + 7));
  }

  // Si la fecha actual es anterior al inicio de la semana 1, pertenece al año anterior.
  if (date.isBefore(week1Start)) {
    // Recalcular para el año anterior
    return getWeekNumber(DateTime(date.year - 1, 12, 31));
  }

  // Calcular el número de días desde el inicio de la semana 1 hasta la fecha actual
  int diffDays = date.difference(week1Start).inDays;

  // El número de semana es (días / 7) + 1
  return (diffDays / 7).floor() + 1;
} 