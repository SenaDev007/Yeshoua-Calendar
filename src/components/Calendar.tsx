import { QumranDate, MonthNumber, SeasonNumber } from '../types/calendar';
import { Holiday } from '../types/holiday';
import { QumranCalculator } from '../utils';
import { CalendarHeader } from './CalendarHeader';
import '../styles/calendar.css';

interface HolidayWithDate extends Holiday {
  date: {
    day: number;
    month: number;
  };
}

interface CalendarProps {
  currentDate: QumranDate;
  holidays: Holiday[];
  onDateClick: (date: QumranDate) => void;
  selectedDate: QumranDate | null;
  onPreviousMonth: () => void;
  onNextMonth: () => void;
  onPreviousYear: () => void;
  onNextYear: () => void;
  onToday: () => void;
}

export function Calendar({
  currentDate,
  holidays,
  onDateClick,
  selectedDate,
  onPreviousMonth,
  onNextMonth,
  onPreviousYear,
  onNextYear,
  onToday
}: CalendarProps) {
  const calculator = new QumranCalculator();

  const getDaysInMonth = (date: QumranDate): number => {
    return calculator.getDaysInMonth(date.month as MonthNumber);
  };

  const getFirstDayOfMonth = (date: QumranDate): number => {
    // Convertir la date Qumran en date grégorienne pour obtenir le jour de la semaine
    const gregDate = calculator.qumranToGregorian(date.month as MonthNumber, 1, date.year);
    // Le calendrier Qumran commence le mercredi (0 = mercredi, 1 = jeudi, etc.)
    return (gregDate.getDay() + 4) % 7; // Ajuster pour que 0 = mercredi
  };

  const isHoliday = (date: QumranDate): boolean => {
    return (holidays as HolidayWithDate[]).some(holiday => 
      holiday.date.day === date.day && 
      holiday.date.month === date.month
    );
  };

  const getHolidayName = (date: QumranDate): string | null => {
    const holiday = (holidays as HolidayWithDate[]).find(h => 
      h.date.day === date.day && 
      h.date.month === date.month
    );
    return holiday ? holiday.name : null;
  };

  const renderCalendarDays = () => {
    const daysInMonth = getDaysInMonth(currentDate);
    const firstDay = getFirstDayOfMonth(currentDate);
    const days = [];

    // Ajouter les jours vides au début
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="calendar-day empty"></div>);
    }

    // Ajouter les jours du mois
    for (let day = 1; day <= daysInMonth; day++) {
      // Créer un objet date Qumran pour le jour courant
      const date: QumranDate = {
        year: currentDate.year,
        month: currentDate.month as MonthNumber,
        day: day as 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31,
        season: 1 as SeasonNumber, // Valeur par défaut
        dayOfWeek: 0, // Sera mis à jour si nécessaire
        dayOfYear: 0, // Sera mis à jour si nécessaire
        weekOfYear: 0, // Sera mis à jour si nécessaire
        isIntercalary: false,
        hebrewMonth: '',
        gregorianDate: new Date(),
        events: [],
        isShabbat: false
      };
      const isSelected = selectedDate && 
        selectedDate.day === day && 
        selectedDate.month === currentDate.month;
      const holidayName = getHolidayName(date);

      days.push(
        <div
          key={`day-${day}`}
          className={`calendar-day ${isHoliday(date) ? 'holiday' : ''} ${isSelected ? 'selected' : ''}`}
          onClick={() => onDateClick(date)}
        >
          <span className="day-number">{day}</span>
          {holidayName && <span className="holiday-name">{holidayName}</span>}
        </div>
      );
    }

    return days;
  };

  return (
    <div className="calendar">
      <CalendarHeader
        currentDate={currentDate}
        onPreviousMonth={onPreviousMonth}
        onNextMonth={onNextMonth}
        onPreviousYear={onPreviousYear}
        onNextYear={onNextYear}
        onToday={onToday}
      />
      <div className="calendar-grid">
        {renderCalendarDays()}
      </div>
    </div>
  );
} 