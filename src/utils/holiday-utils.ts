import { QumranDate } from '../types/calendar';
import { Holiday } from '../types/holiday';
import { HOLIDAYS } from '../data/holidays';

export const getHolidaysForDate = (date: QumranDate): Holiday[] => {
  return HOLIDAYS.filter(holiday => {
    // Vérifie si la fête correspond au jour et au mois
    if (holiday.month === date.month && holiday.day === date.day) {
      return true;
    }

    // Vérifie si la fête a une durée et si la date est dans cette durée
    if (holiday.duration && holiday.month === date.month) {
      const startDay = holiday.day;
      const endDay = holiday.day + holiday.duration - 1;
      return date.day >= startDay && date.day <= endDay;
    }

    return false;
  });
}; 