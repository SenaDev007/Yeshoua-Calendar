import { QumranDate, Event, MonthNumber, SeasonNumber } from '../types/calendar';
import { MONTHS, MAJOR_FEASTS, MINOR_FEASTS } from '../data/calendar-constants';

// La constante QUMRAN_YEAR_DAYS a été supprimée car non utilisée

// Date de référence pour le calendrier de Qumran (19 mars 2025 = 1er Nissan 2025, qui est un mercredi)
const QUMRAN_REFERENCE_DATE = new Date(2025, 2, 19); // 19 mars 2025 (mois 0-based), vérifié comme un mercredi

export class QumranCalculator {
  private static instance: QumranCalculator;
  
  public static getInstance(): QumranCalculator {
    if (!QumranCalculator.instance) {
      QumranCalculator.instance = new QumranCalculator();
    }
    return QumranCalculator.instance;
  }

  // Obtenir la date de début de l'année hébraïque pour une année grégorienne donnée
  public getHebrewYearStart(gregorianYear: number): Date {
    const yearDiff = gregorianYear - QUMRAN_REFERENCE_DATE.getFullYear();
    const startDate = new Date(QUMRAN_REFERENCE_DATE);
    startDate.setFullYear(startDate.getFullYear() + yearDiff);
    return startDate;
  }

  // Obtenir le nombre de jours dans un mois Qumran (version publique)
  public getDaysInMonth(month: MonthNumber): number {
    // Chaque 3ème mois a 31 jours : Sivan(3), Elul(6), Kislev(9), Adar(12)
    return [3, 6, 9, 12].includes(month) ? 31 : 30;
  }
  
  // Obtenir le nombre de jours dans un mois (version avec type number pour la compatibilité)
  public getDaysInMonthNumber(month: number): number {
    return this.getDaysInMonth(month as MonthNumber);
  }

  // Suppression de la méthode inutilisée
  // private getDaysInMonthInternal(month: MonthNumber): number {
  //   return this.getDaysInMonth(month);
  // }

  // Convertir une date Qumran en date grégorienne
  public qumranToGregorian(month: MonthNumber, day: number, year: number): Date {
    const yearStart = this.getHebrewYearStart(year);
    let totalDays = day - 1;
    
    // Ajouter les jours des mois précédents
    for (let i = 1; i < month; i++) {
      totalDays += this.getDaysInMonth(i as MonthNumber);
    }
    
    const resultDate = new Date(yearStart);
    resultDate.setDate(yearStart.getDate() + totalDays);
    return resultDate;
  }

  // Obtenir le jour de la semaine en hébreu (0-6, où 0 = dimanche, 3 = mercredi)
  private getHebrewDay(month: MonthNumber, day: number): number {
    let totalDays = day - 1;
    
    // Ajouter les jours des mois précédents
    for (let i = 1; i < month; i++) {
      totalDays += this.getDaysInMonth(i as MonthNumber);
    }
    
    // Le 1er Nissan est toujours un mercredi (jour 3)
    return (3 + totalDays) % 7;
  }

  // Calculer une date Qumran à partir de l'année, mois et jour
  public createQumranDate(year: number, month: MonthNumber, day: number): QumranDate {
    const monthInfo = MONTHS[month - 1];
    if (!monthInfo) {
      throw new Error(`Mois invalide: ${month}`);
    }

    // Calculer le jour de l'année avec une boucle for classique pour éviter les problèmes de type
    let dayOfYear = day;
    for (let i = 1; i < month; i++) {
      dayOfYear += this.getDaysInMonth(i as MonthNumber);
    }
        
    // Saison (1-4)
    const season = Math.ceil(month / 3) as 1 | 2 | 3 | 4;

    // Obtenir le jour de la semaine (0-6, 0=dimanche, 1=lundi, ..., 6=samedi)
    const dayOfWeek = this.getHebrewDay(month, day);
    
    // Semaine de l'année (1-52)
    const weekOfYear = Math.ceil(dayOfYear / 7);
    
    // Déterminer si c'est un jour intercalaire (dernier jour des mois de 31 jours)
    const isIntercalary = [3, 6, 9, 12].includes(month) && day === 31;
    
    // Date grégorienne correspondante
    const gregorianDate = this.qumranToGregorian(month, day, year);
    
    // Événements pour cette date
    const events = this.getEventsForDate(month, day);

    return {
      year,
      season,
      month,
      day,
      dayOfWeek,
      dayOfYear,
      weekOfYear,
      isIntercalary,
      hebrewMonth: monthInfo.name.he,
      gregorianDate,
      events,
      // Ajout de propriétés pour la compatibilité avec l'UI
      isShabbat: dayOfWeek === 6 // Samedi = Shabbat
    };
  }

  // Obtenir les événements pour une date donnée
  private getEventsForDate(month: number, day: number): Event[] {
    const events: Event[] = [];

    // Fêtes majeures avec dates fixes
    const feastDates: { [key: string]: { month: number; day: number } } = {
      'pessah': { month: 1, day: 14 }, // 14 Aviv/Nissan
      'unleavened_bread': { month: 1, day: 15 }, // 15-21 Aviv/Nissan
      'first_fruits': { month: 1, day: 26 }, // 26 Aviv/Nissan (dimanche)
      'shavuoth': { month: 3, day: 15 }, // 15 Sivan (dimanche)
      'rosh_hashanah': { month: 7, day: 1 }, // 1er Tishrei (mercredi)
      'yom_kippur': { month: 7, day: 10 }, // 10 Tishrei (vendredi)
      'sukkot': { month: 7, day: 15 }, // 15-21 Tishrei
      'shemini_atzeret': { month: 7, day: 22 } // 22 Tishrei (mercredi)
    };

    // Fêtes mineures avec dates fixes
    const minorFeastDates: { [key: string]: { month: number; day: number } } = {
      'hanukkah': { month: 9, day: 25 }, // 25 Kislev
      'purim': { month: 12, day: 14 }, // 14 Adar
      'tu_bishvat': { month: 11, day: 15 }, // 15 Shevat
      'lag_baomer': { month: 2, day: 18 }, // 18 Iyyar
      'tisha_beav': { month: 5, day: 9 }, // 9 Av
    };

    // Vérifier les fêtes majeures
    MAJOR_FEASTS.forEach(feast => {
      const date = feastDates[feast.id];
      if (date && date.month === month && date.day === day) {
        events.push(feast);
      }
      
      // Gérer les fêtes avec durée
      if (feast.duration && date) {
        for (let i = 0; i < feast.duration; i++) {
          if (date.month === month && (date.day + i) === day) {
            events.push(feast);
            break;
          }
        }
      }
    });

    // Vérifier les fêtes mineures
    MINOR_FEASTS.forEach(feast => {
      const date = minorFeastDates[feast.id];
      if (date && date.month === month && date.day === day) {
        events.push(feast);
      }
      
      // Gérer les fêtes avec durée
      if (feast.duration && date) {
        for (let i = 0; i < feast.duration; i++) {
          if (date.month === month && (date.day + i) === day) {
            events.push(feast);
            break;
          }
        }
      }
    });

    // Yom HaBikurim - 26 Nissan
    if (month === 1 && day === 26) {
      const firstFruits = MAJOR_FEASTS.find(f => f.id === 'first_fruits');
      if (firstFruits) {
        events.push(firstFruits);
      }
    }

    return events;
  }

  // Cette méthode est maintenant remplacée par getDaysInMonthNumber ci-dessus
  // qui utilise la logique du calendrier Qumran

  // Vérifier si c'est un jour intercalaire
  public isIntercalaryDay(month: MonthNumber, day: number): boolean {
    const monthInfo = MONTHS[month - 1];
    return monthInfo ? (monthInfo.hasIntercalary && day === monthInfo.days) : false;
  }

  // Vérifier si c'est un sabbat (samedi)
  public isSabbath(dayOfWeek: number): boolean {
    return dayOfWeek === 6; // Samedi = jour 6
  }

  // Obtenir la saison pour un mois donné (1-4)
  public getSeason(month: MonthNumber): SeasonNumber {
    return Math.ceil(month / 3) as SeasonNumber;
  }

  // Obtenir la saison pour un mois donné
  public getSeasonForMonth(month: number): number {
    const monthInfo = MONTHS[month - 1];
    return monthInfo ? monthInfo.season : 1;
  }

  // Obtenir la date Qumran actuelle
  public getCurrentQumranDate(): QumranDate {
    const today = new Date();
    
    // Si nous sommes avant la date de référence (19 mars 2025), utiliser la date de référence
    if (today < QUMRAN_REFERENCE_DATE) {
      return this.createQumranDate(2025, 1, 1);
    }
    
    // Calculer le nombre d'années complètes depuis la date de référence
    const yearsSinceReference = today.getFullYear() - QUMRAN_REFERENCE_DATE.getFullYear();
    
    // Créer une date de début d'année en ajoutant le nombre d'années à la date de référence
    const currentYearStart = new Date(QUMRAN_REFERENCE_DATE);
    currentYearStart.setFullYear(currentYearStart.getFullYear() + yearsSinceReference);
    
    // Calculer le nombre de jours depuis le début de l'année Qumran actuelle
    let daysSinceYearStart = Math.floor((today.getTime() - currentYearStart.getTime()) / (1000 * 60 * 60 * 24));
    
    // Si nous sommes avant le début de l'année Qumran actuelle, utiliser l'année précédente
    if (daysSinceYearStart < 0) {
      currentYearStart.setFullYear(currentYearStart.getFullYear() - 1);
      daysSinceYearStart = Math.floor((today.getTime() - currentYearStart.getTime()) / (1000 * 60 * 60 * 24));
    }
    
    // S'assurer que nous ne dépassons pas 364 jours
    const dayOfYear = Math.min(daysSinceYearStart + 1, 364);
    
    // Trouver le mois et le jour correspondants
    let month = 1 as MonthNumber;
    let day = dayOfYear;
    
    for (let i = 0; i < MONTHS.length; i++) {
      const daysInMonth = this.getDaysInMonth((i + 1) as MonthNumber);
      if (day <= daysInMonth) {
        month = (i + 1) as MonthNumber;
        break;
      }
      day -= daysInMonth;
    }
    
    // Calculer l'année Qumran (2025 + nombre d'années depuis la référence)
    const qumranYear = 2025 + yearsSinceReference;
    
    return this.createQumranDate(qumranYear, month, day);
  }

  // Conversion vers le grégorien en utilisant la date de référence du 19 mars 2025 = 1er Nissan 2025
  public toGregorianApprox(qumranDate: QumranDate): Date {
    // Créer une nouvelle date basée sur la date de référence (19 mars 2025 = 1er Nissan 2025)
    const resultDate = new Date(QUMRAN_REFERENCE_DATE);
    
    // Calculer la différence d'années par rapport à l'année de référence (2025)
    const yearDiff = qumranDate.year - 2025;
    
    // Ajuster l'année
    if (yearDiff !== 0) {
      resultDate.setFullYear(resultDate.getFullYear() + yearDiff);
    }
    
    // Ajouter les jours depuis le début de l'année Qumran (1er Nissan)
    // Moins 1 car le jour 1 est déjà inclus dans la date de référence
    resultDate.setDate(resultDate.getDate() + qumranDate.dayOfYear - 1);
    
    return resultDate;
  }

  // Vérifier si une date est aujourd'hui
  public isToday(date: QumranDate): boolean {
    const today = this.getCurrentQumranDate();
    return date.year === today.year && 
           date.month === today.month && 
           date.day === today.day;
  }
}