import React from 'react';
import { motion } from 'framer-motion';
import { QumranDate } from '../types/calendar';
import { HOLIDAYS, Holiday } from '../data/holidays';
import { getHolidaysForDate } from '../utils/holiday-utils';

interface CalendarDayProps {
  date: QumranDate;
  isCurrentMonth: boolean;
  isToday: boolean;
  isSelected: boolean;
  onSelect: (date: QumranDate) => void;
}

const CalendarDay: React.FC<CalendarDayProps> = ({
  date,
  isCurrentMonth,
  isToday,
  isSelected,
  onSelect,
}) => {
  const holidays = getHolidaysForDate(date);
  const majorHoliday = holidays.find((h: Holiday) => h.type === 'major');
  const minorHoliday = holidays.find((h: Holiday) => h.type === 'minor');

  return (
    <motion.button
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      onClick={() => onSelect(date)}
      className={`
        relative w-full h-24 p-2 rounded-lg
        ${isCurrentMonth ? 'bg-white dark:bg-gray-800' : 'bg-gray-50 dark:bg-gray-900'}
        ${isToday ? 'ring-2 ring-blue-500 dark:ring-blue-400' : ''}
        ${isSelected ? 'ring-2 ring-purple-500 dark:ring-purple-400' : ''}
        ${majorHoliday ? 'bg-red-50 dark:bg-red-900/20' : ''}
        ${minorHoliday ? 'bg-blue-50 dark:bg-blue-900/20' : ''}
        transition-all duration-200
      `}
    >
      <div className="flex flex-col h-full">
        <div className="flex items-center justify-between">
          <span className={`
            text-sm font-medium
            ${isCurrentMonth ? 'text-gray-900 dark:text-gray-100' : 'text-gray-400 dark:text-gray-500'}
            ${isToday ? 'text-blue-600 dark:text-blue-400' : ''}
            ${majorHoliday ? 'text-red-600 dark:text-red-400' : ''}
            ${minorHoliday ? 'text-blue-600 dark:text-blue-400' : ''}
          `}>
            {date.day}
          </span>
          {majorHoliday && majorHoliday.icon && (
            <div className="text-red-600 dark:text-red-400">
              {majorHoliday.icon()}
            </div>
          )}
          {minorHoliday && minorHoliday.icon && !majorHoliday && (
            <div className="text-blue-600 dark:text-blue-400">
              {minorHoliday.icon()}
            </div>
          )}
        </div>
        
        <div className="flex-1 overflow-hidden">
          {holidays.map((holiday: Holiday) => (
            <div
              key={holiday.id}
              className={`
                text-xs truncate
                ${holiday.type === 'major' ? 'text-red-600 dark:text-red-400' : 'text-blue-600 dark:text-blue-400'}
              `}
            >
              {holiday.name}
            </div>
          ))}
        </div>
      </div>
    </motion.button>
  );
};

export default CalendarDay; 