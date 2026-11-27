import React from 'react';
import { QumranDate } from '../types/calendar';
import { useTranslation } from 'react-i18next';
import { DAYS_OF_WEEK } from '../data/calendar-constants';
import { QumranCalculator } from '../utils/qumran-calculator';
import { getHolidaysForDate } from '../utils/holiday-utils';
import type { Language } from '../data/translations';

interface CalendarGridProps {
  currentDate: QumranDate;
  selectedDate: QumranDate;
  onDateSelect: (date: QumranDate) => void;
}

export function CalendarGrid({
  currentDate,
  selectedDate,
  onDateSelect
}: CalendarGridProps) {
  const { t, i18n } = useTranslation();
  const currentLang = i18n.language as Language;
  const calculator = QumranCalculator.getInstance();

  // Générer les jours du mois
  const days = Array.from({ length: 30 }, (_, i) => {
    const day = i + 1;
    const date = { ...currentDate, day };
    const holidays = getHolidaysForDate(date);
    const isToday = calculator.isToday(date);
    const isSelected = selectedDate.day === day && selectedDate.month === currentDate.month && selectedDate.year === currentDate.year;
    const isSabbath = calculator.isSabbath(date.dayOfWeek);

    return {
      date,
      holidays,
      isToday,
      isSelected,
      isSabbath
    };
  });

  return (
    <div className="p-4">
      {/* En-têtes des jours de la semaine */}
      <div className="grid grid-cols-7 gap-1 mb-2">
        {DAYS_OF_WEEK.map((day, index) => (
          <div
            key={index}
            className="text-center text-sm font-medium text-gray-600 py-2"
          >
            {day.name[currentLang]}
          </div>
        ))}
      </div>

      {/* Grille des jours */}
      <div className="grid grid-cols-7 gap-1">
        {days.map(({ date, holidays, isToday, isSelected, isSabbath }) => (
          <button
            key={date.day}
            onClick={() => onDateSelect(date)}
            className={`
              relative p-2 rounded-lg text-center transition-colors
              ${isSelected ? 'bg-blue-600 text-white' : 'hover:bg-blue-100'}
              ${isToday ? 'ring-2 ring-blue-500' : ''}
              ${isSabbath ? 'bg-blue-50' : ''}
            `}
          >
            <span className="text-sm">{date.day}</span>
            {holidays.length > 0 && (
              <div className="absolute bottom-1 left-1/2 transform -translate-x-1/2 flex space-x-1">
                {holidays.map(holiday => (
                  <div key={holiday.id} className="w-1 h-1 rounded-full bg-red-500"></div>
                ))}
              </div>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}