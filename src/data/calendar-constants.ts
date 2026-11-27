import { MonthInfo, SeasonInfo, Event } from '../types/calendar';

export const MONTHS: MonthInfo[] = [
  // Printemps (Saison 1)
  { 
    number: 1, 
    name: { fr: 'Aviv/Nissan', en: 'Aviv/Nissan', he: 'אביב/ניסן' },
    days: 30, 
    season: 1, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#4a7c59',
      secondary: '#3a5a40',
      accent: '#a3b18a',
      background: '#f8f9fa'
    }
  },
  // ... autres mois avec la même structure
  { 
    number: 2, 
    name: { fr: 'Iyyar', en: 'Iyyar', he: 'אייר' },
    days: 30, 
    season: 1, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#4a7c59',
      secondary: '#3a5a40',
      accent: '#a3b18a',
      background: '#f8f9fa'
    }
  },
  { 
    number: 3, 
    name: { fr: 'Sivan', en: 'Sivan', he: 'סיון' },
    days: 31, 
    season: 1, 
    hasIntercalary: true,
    symbolImage: '',
    seasonalColors: {
      primary: '#4a7c59',
      secondary: '#3a5a40',
      accent: '#a3b18a',
      background: '#f8f9fa'
    }
  },
  { 
    number: 4, 
    name: { fr: 'Tammuz', en: 'Tammuz', he: 'תמוז' },
    days: 30, 
    season: 2, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#e29578',
      secondary: '#d88c7b',
      accent: '#ffddd2',
      background: '#fff1e6'
    }
  },
  { 
    number: 5, 
    name: { fr: 'Av', en: 'Av', he: 'אב' },
    days: 30, 
    season: 2, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#e29578',
      secondary: '#d88c7b',
      accent: '#ffddd2',
      background: '#fff1e6'
    }
  },
  { 
    number: 6, 
    name: { fr: 'Elul', en: 'Elul', he: 'אלול' },
    days: 31, 
    season: 2, 
    hasIntercalary: true,
    symbolImage: '',
    seasonalColors: {
      primary: '#e29578',
      secondary: '#d88c7b',
      accent: '#ffddd2',
      background: '#fff1e6'
    }
  },
  { 
    number: 7, 
    name: { fr: 'Tishrei', en: 'Tishrei', he: 'תשרי' },
    days: 30, 
    season: 3, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#457b9d',
      secondary: '#1d3557',
      accent: '#a8dadc',
      background: '#f1faee'
    }
  },
  { 
    number: 8, 
    name: { fr: 'Marcheshvan', en: 'Marcheshvan', he: 'מרחשון' },
    days: 30, 
    season: 3, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#457b9d',
      secondary: '#1d3557',
      accent: '#a8dadc',
      background: '#f1faee'
    }
  },
  { 
    number: 9, 
    name: { fr: 'Kislev', en: 'Kislev', he: 'כסלו' },
    days: 31, 
    season: 3, 
    hasIntercalary: true,
    symbolImage: '',
    seasonalColors: {
      primary: '#457b9d',
      secondary: '#1d3557',
      accent: '#a8dadc',
      background: '#f1faee'
    }
  },
  { 
    number: 10, 
    name: { fr: 'Tevet', en: 'Tevet', he: 'טבת' },
    days: 30, 
    season: 4, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#6a4c93',
      secondary: '#4a3b69',
      accent: '#c19ee0',
      background: '#f8f7ff'
    }
  },
  { 
    number: 11, 
    name: { fr: 'Shevat', en: 'Shevat', he: 'שבט' },
    days: 30, 
    season: 4, 
    hasIntercalary: false,
    symbolImage: '',
    seasonalColors: {
      primary: '#6a4c93',
      secondary: '#4a3b69',
      accent: '#c19ee0',
      background: '#f8f7ff'
    }
  },
  { 
    number: 12, 
    name: { fr: 'Adar', en: 'Adar', he: 'אדר' },
    days: 31, 
    season: 4, 
    hasIntercalary: true,
    symbolImage: '',
    seasonalColors: {
      primary: '#6a4c93',
      secondary: '#4a3b69',
      accent: '#c19ee0',
      background: '#f8f7ff'
    }
  }
];

export const SEASONS: SeasonInfo[] = [
  { 
    number: 1, 
    name: { fr: 'Printemps', en: 'Spring', he: 'אביב' }, 
    months: [1, 2, 3], 
    startDay: 1, 
    endDay: 91,
    colors: {
      primary: '#588157',
      secondary: '#3a5a40',
      accent: '#a3b18a',
      background: '#f8f9fa',
      gradient: 'from-green-50 to-green-100'
    },
    symbolImage: ''
  },
  { 
    number: 2, 
    name: { fr: 'Été', en: 'Summer', he: 'קיץ' }, 
    months: [4, 5, 6], 
    startDay: 92, 
    endDay: 182,
    colors: {
      primary: '#e76f51',
      secondary: '#e9c46a',
      accent: '#f4a261',
      background: '#fff1e6',
      gradient: 'from-orange-50 to-amber-50'
    },
    symbolImage: ''
  },
  { 
    number: 3, 
    name: { fr: 'Automne', en: 'Autumn', he: 'סתיו' }, 
    months: [7, 8, 9], 
    startDay: 183, 
    endDay: 273,
    colors: {
      primary: '#457b9d',
      secondary: '#1d3557',
      accent: '#a8dadc',
      background: '#f1faee',
      gradient: 'from-blue-50 to-cyan-50'
    },
    symbolImage: ''
  },
  { 
    number: 4, 
    name: { fr: 'Hiver', en: 'Winter', he: 'חורף' }, 
    months: [10, 11, 12], 
    startDay: 274, 
    endDay: 364,
    colors: {
      primary: '#6a4c93',
      secondary: '#4a3b69',
      accent: '#c19ee0',
      background: '#f8f7ff',
      gradient: 'from-purple-50 to-indigo-50'
    },
    symbolImage: ''
  }
];

export const DAYS_OF_WEEK = [
  { 
    name: { 
      fr: 'Dimanche', 
      en: 'Sunday', 
      he: 'ראשון',
      translit: 'Yom Rishon' 
    },
    short: 'Dim' 
  },
  { 
    name: { 
      fr: 'Lundi', 
      en: 'Monday', 
      he: 'שני',
      translit: 'Yom Sheni' 
    },
    short: 'Lun' 
  },
  { 
    name: { 
      fr: 'Mardi', 
      en: 'Tuesday', 
      he: 'שלישי',
      translit: 'Yom Shlishi' 
    },
    short: 'Mar' 
  },
  { 
    name: { 
      fr: 'Mercredi', 
      en: 'Wednesday', 
      he: 'רביעי',
      translit: 'Yom Revi\'i' 
    },
    short: 'Mer' 
  },
  { 
    name: { 
      fr: 'Jeudi', 
      en: 'Thursday', 
      he: 'חמישי',
      translit: 'Yom Chamishi' 
    },
    short: 'Jeu' 
  },
  { 
    name: { 
      fr: 'Vendredi', 
      en: 'Friday', 
      he: 'שישי',
      translit: 'Yom Shishi' 
    },
    short: 'Ven' 
  },
  { 
    name: { 
      fr: 'Samedi', 
      en: 'Saturday', 
      he: 'שבת',
      translit: 'Shabbat' 
    },
    short: 'Sam' 
  }
];

export const MAJOR_FEASTS: Event[] = [
  {
    id: 'pessah',
    name: {
      fr: 'Pessah (Agneau pascal)',
      en: 'Passover (Pascal Lamb)',
      he: 'פסח'
    },
    type: 'major_feast',
    description: {
      fr: 'Commémoration de la sortie d\'Égypte',
      en: 'Commemoration of the Exodus from Egypt',
      he: 'זיכרון יציאת מצרים'
    }
  },
  {
    id: 'unleavened_bread',
    name: {
      fr: 'Fête des Pains sans Levain',
      en: 'Feast of Unleavened Bread',
      he: 'חג המצות'
    },
    type: 'major_feast',
    description: {
      fr: '7 jours de célébration (du 15 au 21 Nissan)',
      en: '7 days of celebration (15-21 Nissan)',
      he: 'שבעת ימי חג (ט"ו-כ"א ניסן)'
    },
    duration: 7
  },
  {
    id: 'first_fruits',
    name: {
      fr: 'Yom HaBikurim (Premier des Fruits)',
      en: 'Yom HaBikurim (First Fruits)',
      he: 'יום הביכורים'
    },
    type: 'major_feast',
    description: {
      fr: 'Jour des Prémices (26 Nissan)',
      en: 'Day of First Fruits (26 Nissan)',
      he: 'יום הביכורים (כ״ו ניסן)'
    },
    isMoveable: false
  },
  {
    id: 'shavuoth',
    name: {
      fr: 'Shavuoth (Fête des Semaines)',
      en: 'Shavuot (Feast of Weeks)',
      he: 'שבועות'
    },
    type: 'major_feast',
    description: {
      fr: 'Don de la Torah',
      en: 'Giving of the Torah',
      he: 'חג מתן תורה'
    }
  },
  {
    id: 'rosh_hashanah',
    name: {
      fr: 'Yom Terua (Jour des Trompettes)',
      en: 'Yom Teruah (Day of Trumpets)',
      he: 'יום תרועה'
    },
    type: 'major_feast',
    description: {
      fr: 'Nouvel An hébraïque',
      en: 'Jewish New Year',
      he: 'ראש השנה'
    }
  },
  {
    id: 'yom_kippur',
    name: {
      fr: 'Yom HaKipurim (Grand Pardon)',
      en: 'Yom Kippur (Day of Atonement)',
      he: 'יום הכיפורים'
    },
    type: 'major_feast',
    description: {
      fr: 'Jour du pardon et du jeûne',
      en: 'Day of Atonement and Fasting',
      he: 'יום הכפורים ותענית'
    }
  },
  {
    id: 'sukkot',
    name: {
      fr: 'Souccoth (Fête des Cabanes)',
      en: 'Sukkot (Feast of Tabernacles)',
      he: 'סוכות'
    },
    type: 'major_feast',
    description: {
      fr: '7 jours de célébration',
      en: '7 days of celebration',
      he: 'שבעת ימי החג'
    },
    duration: 7
  }
];

export const MINOR_FEASTS: Event[] = [
  {
    id: 'hanukkah',
    name: {
      fr: 'Hanouka (Fête des Lumières)',
      en: 'Hanukkah (Festival of Lights)',
      he: 'חנוכה'
    },
    type: 'minor_feast',
    description: {
      fr: '8 jours de célébration',
      en: '8 days of celebration',
      he: 'שמונת ימי חנוכה'
    },
    duration: 8
  },
  {
    id: 'purim',
    name: {
      fr: 'Pourim',
      en: 'Purim',
      he: 'פורים'
    },
    type: 'minor_feast',
    description: {
      fr: 'Célébration de la délivrance',
      en: 'Celebration of deliverance',
      he: 'חג הפורים'
    }
  },
  {
    id: 'tu_bishvat',
    name: {
      fr: 'Tu BiShvat (Nouvel An des Arbres)',
      en: 'Tu BiShvat (New Year of the Trees)',
      he: 'ט״ו בשבט'
    },
    type: 'minor_feast',
    description: {
      fr: 'Nouvel An des arbres',
      en: 'New Year of the Trees',
      he: 'ראש השנה לאילנות'
    }
  },
  {
    id: 'lag_baomer',
    name: {
      fr: 'Lag BaOmer',
      en: 'Lag BaOmer',
      he: 'ל״ג בעומר'
    },
    type: 'minor_feast',
    description: {
      fr: '33ème jour du décompte de l\'Omer',
      en: '33rd day of the Omer count',
      he: 'ל״ג בעומר'
    }
  },
  {
    id: 'tisha_beav',
    name: {
      fr: 'Tisha BeAv (Jeûne du 9 Av)',
      en: 'Tisha B\'Av (Ninth of Av)',
      he: 'תשעה באב'
    },
    type: 'fast',
    description: {
      fr: 'Jeûne de commémoration',
      en: 'Day of mourning',
      he: 'יום צום ותענית'
    }
  }
];

// Référence : L'année de Qumran commence toujours un mercredi
export const QUMRAN_YEAR_START_DAY = 3; // 0=dimanche, 3=mercredi
export const QUMRAN_YEAR_DAYS = 364;
export const QUMRAN_WEEKS_PER_YEAR = 52;