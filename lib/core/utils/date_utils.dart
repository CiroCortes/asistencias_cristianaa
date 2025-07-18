int getWeekNumber(DateTime date) {
  // SISTEMA NO ISO: Semana 1 empieza el 1 de enero, cada semana empieza el lunes
  // Directriz del cliente: La Semana 1 del año comienza el 1 de enero
  // Cada semana comienza el lunes y termina el domingo

  // La semana 1 empieza el 1 de enero, sin importar el día de la semana
  DateTime week1Start = DateTime(date.year, 1, 1);

  // Si la fecha es anterior al 1 de enero, usar el 1 de enero del año anterior
  if (date.isBefore(week1Start)) {
    week1Start = DateTime(date.year - 1, 1, 1);
  }

  // Calcular días desde el 1 de enero
  int diffDays = date.difference(week1Start).inDays;

  // El número de semana es (días / 7) + 1
  return (diffDays / 7).floor() + 1;
}
