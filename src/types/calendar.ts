export type MonthNumber = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12;
export type SeasonNumber = 1 | 2 | 3 | 4;

export interface QumranDate {
  year: number;
  season: SeasonNumber; // 1-4
  month: MonthNumber; // 1-12
  day: number; // 1-31
  dayOfWeek: number; // 0-6 (0 = dimanche)
  dayOfYear: number; // 1-364
  weekOfYear: number; // 1-52
  isIntercalary: boolean;
  hebrewMonth: string;
  gregorianDate: Date;
  events: Event[];
  isShabbat: boolean;
}

export interface Event {
  id: string;
  name: {
    fr: string;
    en: string;
    he: string;
  };
  type: 'major_feast' | 'minor_feast' | 'fast' | 'seasonal' | 'qumran_specific';
  description?: {
    fr: string;
    en: string;
    he: string;
  };
  duration?: number; // en jours
  isMoveable?: boolean;
  symbolImage?: string;
}

export interface MonthInfo {
  number: number;
  name: {
    fr: string;
    en: string;
    he: string;
  };
  days: number;
  season: number;
  hasIntercalary: boolean;
  symbolImage: string;
  seasonalColors: {
    primary: string;
    secondary: string;
    accent: string;
    background: string;
  };
}

export interface SeasonInfo {
  number: number;
  name: {
    fr: string;
    en: string;
    he: string;
  };
  months: number[];
  startDay: number;
  endDay: number;
  colors: {
    primary: string;
    secondary: string;
    accent: string;
    background: string;
    gradient: string;
  };
  symbolImage: string;
}

export type Language = 'fr' | 'en' | 'he';