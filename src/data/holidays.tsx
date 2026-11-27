import { QumranDate, MonthNumber } from '../types/calendar';
import { Calendar, Clock, Star, Sun, Moon, Flame, Wheat, Wine, Leaf, Bell, Cross, Home, Heart, Crown, Gift, BookOpen } from 'lucide-react';
import { Holiday } from '../types/holiday';

// Types pour les fêtes
export type HolidayType = 'major' | 'minor' | 'period';

export interface Holiday {
  id: string;
  name: string;
  month: MonthNumber;
  day: number;
  type: HolidayType;
  duration?: number;
  icon?: () => JSX.Element;
}

// Données des fêtes
export const HOLIDAYS: Holiday[] = [
  // Fêtes majeures bibliques
  { 
    id: 'pessah', 
    name: 'Pessa\'h (Pâque)', 
    month: 1, 
    day: 14, 
    type: 'major', 
    duration: 1,
    icon: () => (
      <Flame className="w-4 h-4 text-red-600" />
    )
  },
  { 
    id: 'pains-sans-levain', 
    name: 'Hag HaMatzot (Pains Sans Levain)', 
    month: 1, 
    day: 15, 
    type: 'major', 
    duration: 7,
    icon: () => (
      <Wheat className="w-4 h-4 text-amber-600" />
    )
  },
  { 
    id: 'premices', 
    name: 'HaBikkurim (Prémices de la moisson)', 
    month: 1, 
    day: 26, 
    type: 'major',
    icon: () => (
      <Gift className="w-4 h-4 text-green-600" />
    )
  },
  { 
    id: 'shavuot', 
    name: 'Shavouot (Semaines/Pentecôte)', 
    month: 3, 
    day: 15, 
    type: 'major',
    icon: () => (
      <BookOpen className="w-4 h-4 text-blue-600" />
    )
  },
  { 
    id: 'trompettes', 
    name: 'Yom Terouah (Fête des Trompettes)', 
    month: 7, 
    day: 1, 
    type: 'major',
    icon: () => (
      <Bell className="w-4 h-4 text-purple-600" />
    )
  },
  { 
    id: 'yom-kippurim', 
    name: 'Yom Kippour (Jour des Expiations)', 
    month: 7, 
    day: 10, 
    type: 'major',
    icon: () => (
      <Cross className="w-4 h-4 text-red-700" />
    )
  },
  { 
    id: 'sukkot', 
    name: 'Soukkot (Fête des Tabernacles)', 
    month: 7, 
    day: 15, 
    type: 'major', 
    duration: 7,
    icon: () => (
      <Home className="w-4 h-4 text-orange-600" />
    )
  },
  { 
    id: 'shemini-atzeret', 
    name: 'Shemini Atzeret (8ème jour de clôture)', 
    month: 7, 
    day: 22, 
    type: 'major',
    icon: () => (
      <Crown className="w-4 h-4 text-yellow-600" />
    )
  },
  
  // Début des saisons bibliques
  { 
    id: 'aviv', 
    name: 'Début du Printemps (Aviv)', 
    month: 1, 
    day: 1, 
    type: 'minor',
    icon: () => (
      <Leaf className="w-4 h-4 text-green-500" />
    )
  },
  { 
    id: 'kayits', 
    name: 'Début de l\'Été (Kayits)', 
    month: 4, 
    day: 1, 
    type: 'minor',
    icon: () => (
      <Sun className="w-4 h-4 text-yellow-500" />
    )
  },
  { 
    id: 'stav', 
    name: 'Début de l\'Automne (Stav)', 
    month: 7, 
    day: 1, 
    type: 'minor',
    icon: () => (
      <Leaf className="w-4 h-4 text-orange-500" />
    )
  },
  { 
    id: 'horef', 
    name: 'Début de l\'Hiver (Horef)', 
    month: 10, 
    day: 1, 
    type: 'minor',
    icon: () => (
      <Moon className="w-4 h-4 text-blue-500" />
    )
  }
];

// Périodes spéciales (pour référence)
export const SPECIAL_PERIODS = [
  { name: "Compte de l'Omer", startMonth: 1, startDay: 16, duration: 49 },
  { name: 'Selichot', startMonth: 6, startDay: 25, endMonth: 7, endDay: 10 }
];

/**
 * Vérifie si une date donnée correspond à une fête
 */
export function getHolidayForDate(date: QumranDate): Holiday | null {
  if (!date) return null;
  
  return HOLIDAYS.find(holiday => {
    // Vérifie si le mois et le jour correspondent
    const isSameDay = holiday.month === date.month && holiday.day === date.day;
    
    // Vérifie si la date est dans une période de fête multi-jours
    const isInDuration = holiday.duration && holiday.duration > 1 &&
      date.month === holiday.month &&
      date.day > holiday.day &&
      date.day < holiday.day + holiday.duration;
    
    return isSameDay || isInDuration;
  }) || null;
}

/**
 * Retourne la classe CSS appropriée pour une fête
 */
export function getHolidayClass(holiday: Holiday | null): string {
  if (!holiday) return '';
  
  const baseClass = 'hover:bg-opacity-80 transition-colors';
  
  switch (holiday.type) {
    case 'major':
      return `${baseClass} bg-red-900/40`;
    case 'minor':
      return `${baseClass} bg-blue-900/40`;
    case 'period':
      return `${baseClass} bg-amber-900/40`;
    default:
      return '';
  }
}

/**
 * Vérifie si une date est dans une période spéciale (compte de l'Omer, etc.)
 */
export function isInSpecialPeriod(date: QumranDate): boolean {
  // Période du compte de l'Omer (16/1 - 5/3)
  if (date.month === 1 && date.day >= 16) return true;
  if (date.month === 2) return true;
  if (date.month === 3 && date.day <= 5) return true;
  
  // Période des fêtes d'automne (1/7 - 22/7)
  if (date.month === 7 && date.day <= 22) return true;
  
  return false;
}
