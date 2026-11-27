import { QumranCalculator } from './qumran-calculator';

// Tableau des noms de jours en français
const FRENCH_DAYS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];

interface YearRange {
  startDate: string; // Format: "Mercredi 19/03/2025"
  endDate: string;   // Format: "Mardi 17/03/2026"
}

/**
 * Retourne les dates de début et de fin de l'année Qumran formatées
 * @param qumranYear - L'année du calendrier Qumran (par exemple 2025)
 * @returns Un objet avec les dates de début et de fin formatées
 */
export function getHebrewYearRange(qumranYear: number): YearRange {
  const calculator = QumranCalculator.getInstance();
  
  // Date de début : 1er Nissan de l'année
  const startDate = calculator.qumranToGregorian(1, 1, qumranYear);
  
  // Date de fin : dernier jour de l'année (364 jours plus tard)
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + 363); // 364 jours - 1 car le 1er jour est inclus
  
  // Formater les dates
  const formatDate = (date: Date): string => {
    const dayName = FRENCH_DAYS[date.getDay()];
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    return `${dayName} ${day}/${month}/${year}`;
  };
  
  return {
    startDate: formatDate(startDate),
    endDate: formatDate(endDate)
  };
}
