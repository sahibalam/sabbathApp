import 'dart:math' as math;

class SunCalculator {
  static const double zenith = 90.833;

  static DateTime calculateSunrise(
    DateTime date,
    double latitude,
    double longitude,
    Duration utcOffset,
  ) {
    return _calculateSunEvent(date, latitude, longitude, utcOffset, true);
  }

  static DateTime calculateSunset(
    DateTime date,
    double latitude,
    double longitude,
    Duration utcOffset,
  ) {
    return _calculateSunEvent(date, latitude, longitude, utcOffset, false);
  }

  static DateTime _calculateSunEvent(
    DateTime date,
    double latitude,
    double longitude,
    Duration utcOffset,
    bool isSunrise,
  ) {
    // Use UTC date for calculations
    final utcDate = DateTime.utc(date.year, date.month, date.day);

    // 1. Calculate the day of the year
    final dayOfYear =
        utcDate.difference(DateTime.utc(utcDate.year, 1, 1)).inDays + 1;

    // 2. Convert longitude to hour value
    final lngHour = longitude / 15;

    // 3. Calculate approximate time
    final t = dayOfYear + ((isSunrise ? 6 : 18) - lngHour) / 24;

    // 4. Calculate sun's mean anomaly
    final M = (0.9856 * t) - 3.289;

    // 5. Calculate sun's true longitude
    final L =
        M +
        (1.916 * math.sin(radians(M))) +
        (0.020 * math.sin(radians(2 * M))) +
        282.634;
    final Lnormalized = L % 360;

    // 6. Calculate sun's right ascension
    final RA = degrees(math.atan(0.91764 * math.tan(radians(Lnormalized))));
    final RAnormalized = (RA % 360 + 360) % 360;

    // 7. Right ascension needs to be in same quadrant as L
    final Lquadrant = (Lnormalized / 90).floor() * 90;
    final RAquadrant = (RAnormalized / 90).floor() * 90;
    final RAadjusted = RAnormalized + (Lquadrant - RAquadrant);

    // 8. Convert right ascension to hours
    final RAhours = RAadjusted / 15;

    // 9. Calculate sun's declination
    final sinDec = 0.39782 * math.sin(radians(Lnormalized));
    final cosDec = math.cos(math.asin(sinDec));

    // 10. Calculate sun's local hour angle
    final cosH =
        (math.cos(radians(zenith)) - (sinDec * math.sin(radians(latitude)))) /
        (cosDec * math.cos(radians(latitude)));

    // Handle no sunset/rise conditions
    if (cosH > 1 || cosH < -1) {
      return DateTime.utc(0); // Return invalid date
    }

    final H = isSunrise
        ? 360 - degrees(math.acos(cosH))
        : degrees(math.acos(cosH));
    final Hhours = H / 15;

    // 11. Calculate local mean time
    final T = Hhours + RAhours - (0.06571 * t) - 6.622;

    // 12. Adjust to UTC
    final UT = (T - lngHour) % 24;
    final UTnormalized = UT < 0 ? UT + 24 : UT;

    final hours = UTnormalized.floor();
    final minutes = ((UTnormalized - hours) * 60).round();

    // Create UTC time
    final utcTime = DateTime.utc(
      utcDate.year,
      utcDate.month,
      utcDate.day,
      hours,
      minutes,
    );

    // Convert to local time using the provided UTC offset
    return utcTime.add(utcOffset);
  }

  static double radians(double degrees) => degrees * math.pi / 180;
  static double degrees(double radians) => radians * 180 / math.pi;
}
