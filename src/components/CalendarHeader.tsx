import { ChevronLeft, ChevronRight, Home } from 'lucide-react';
import { Logo } from './Logo';
import { QumranDate } from '../types/calendar';
import { SEASONS, MONTHS, DAYS_OF_WEEK } from '../data/calendar-constants';
import { useTranslation } from 'react-i18next';
import { QumranCalculator } from '../utils';
import type { Language } from '../data/translations';

interface CalendarHeaderProps {
  currentDate: QumranDate;
  onPreviousMonth: () => void;
  onNextMonth: () => void;
  onPreviousYear: () => void;
  onNextYear: () => void;
  onToday: () => void;
}

export function CalendarHeader({
  currentDate,
  onPreviousMonth,
  onNextMonth,
  onPreviousYear,
  onNextYear,
  onToday
}: CalendarHeaderProps) {
  const { t, i18n } = useTranslation();
  const currentLang = i18n.language as Language;
  const calculator = QumranCalculator.getInstance();

  return (
    <div className="relative bg-gradient-radial-header text-white px-2 sm:px-4 md:px-8 lg:px-16 py-2 sm:py-3 rounded-t-lg shadow-lg">
      {/* Bouton Aujourd'hui */}
      <button
        onClick={onToday}
        className="absolute top-2 right-2 sm:top-3 sm:right-3 px-2 sm:px-3 py-1.5 bg-blue-700/90 hover:bg-blue-800 text-white text-xs sm:text-sm font-medium rounded-md transition-colors flex items-center"
        title={t('today')}
      >
        <Home className="w-3 h-3 sm:w-4 sm:h-4 mr-1" />
        <span className="hidden sm:inline">{t('today')}</span>
      </button>

      {/* Contenu central */}
      <div className="flex flex-col items-center">
        {/* En-tête avec logo et titre */}
        <div className="flex items-center justify-between w-full mb-2 sm:mb-3">
          <div className="flex items-center space-x-2 sm:space-x-3">
            <div className="w-12 h-12 sm:w-14 sm:h-14 lg:w-16 lg:h-16 flex-shrink-0">
              <Logo className="w-full h-full" />
            </div>
            <div className="flex flex-col">
              <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold leading-tight tracking-tight text-white group">
                <span className="inline-block transition-all duration-300 hover:text-amber-300">
                  {t('calendar_title')}
                </span>
              </h1>
              <p className="text-amber-300 text-xs sm:text-sm mt-0.5 sm:mt-1">
                {t('calendar_subtitle')}
              </p>
            </div>
          </div>
        </div>

        {/* Section de navigation et informations du mois */}
        <div className="flex items-center justify-between w-full px-4 sm:px-8">
          {/* Boutons de navigation à gauche */}
          <div className="flex items-center space-x-2">
            <button
              onClick={onPreviousYear}
              className="p-2 bg-blue-900/90 hover:bg-blue-800 rounded-lg transition-colors font-bold flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 shadow-lg"
              title={t('previous_year')}
            >
              <ChevronLeft className="w-5 h-5 sm:w-6 sm:h-6" />
            </button>
            <button
              onClick={onPreviousMonth}
              className="p-1.5 bg-blue-800/90 hover:bg-blue-700 rounded-lg transition-colors font-bold flex items-center justify-center w-8 h-8 sm:w-9 sm:h-9 shadow-lg"
              title={t('previous_month')}
            >
              <ChevronLeft className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            </button>
          </div>

          {/* Information du mois hébraïque centrée */}
          <div className="flex-1 text-center mx-4">
            <div className="text-lg sm:text-xl font-semibold text-amber-200 mb-1">
              {currentDate.month}ème Mois - {MONTHS[currentDate.month - 1].name[currentLang]}
            </div>
            <div className="text-sm sm:text-base text-white/90">
              {t('year')}: {currentDate.year} • {t('season')}: {SEASONS[currentDate.season - 1].name[currentLang]}
            </div>
            <div className="text-xs sm:text-sm text-white/80 mt-1">
              <div>{t('start')}: {DAYS_OF_WEEK[0].name[currentLang]} {calculator.toGregorianApprox({...currentDate, day: 1}).toLocaleDateString()}</div>
              <div>{t('end')}: {DAYS_OF_WEEK[6].name[currentLang]} {calculator.toGregorianApprox({...currentDate, day: MONTHS[currentDate.month - 1].days}).toLocaleDateString()}</div>
            </div>
          </div>

          {/* Boutons de navigation à droite */}
          <div className="flex items-center space-x-2">
            <button
              onClick={onNextMonth}
              className="p-1.5 bg-blue-800/90 hover:bg-blue-700 rounded-lg transition-colors font-bold flex items-center justify-center w-8 h-8 sm:w-9 sm:h-9 shadow-lg"
              title={t('next_month')}
            >
              <ChevronRight className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            </button>
            <button
              onClick={onNextYear}
              className="p-2 bg-blue-900/90 hover:bg-blue-800 rounded-lg transition-colors font-bold flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 shadow-lg"
              title={t('next_year')}
            >
              <ChevronRight className="w-5 h-5 sm:w-6 sm:h-6" />
            </button>
          </div>
        </div>

        <div className="mt-3 sm:mt-4 flex justify-center space-x-6 text-sm">
          <div className="bg-blue-900/50 px-3 py-1.5 rounded-md">
            <span className="text-amber-200">Jour de l'année:</span>
            <span className="ml-2 font-semibold text-white">{currentDate.dayOfYear}<span className="text-blue-300">/364</span></span>
          </div>
          <div className="bg-blue-900/50 px-3 py-1.5 rounded-md">
            <span className="text-amber-200">Semaine:</span>
            <span className="ml-2 font-semibold text-white">{currentDate.weekOfYear}<span className="text-blue-300">/52</span></span>
          </div>
        </div>
      </div>
    </div>
  );
}