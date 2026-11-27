export type LanguageKey = 'fr' | 'en' | 'he';

export interface ParashahName {
  fr: string;
  en: string;
  he: string;
  [key: string]: string; // Pour permettre l'accès par clé dynamique
}

export interface Parashah {
  id: number;
  name: {
    fr: string;
    en: string;
    he: string;
    [key: string]: string; // Pour permettre l'accès par clé dynamique
  };
  hebrew: string;
  torah: {
    fr: string;
    en: string;
    he: string;
    [key: string]: string;
  };
  haftarah: {
    fr: string;
    en: string;
    he: string;
    [key: string]: string;
  };
  theme: {
    fr: string;
    en: string;
    he: string;
    [key: string]: string;
  };
}

export interface CurrentParashah {
  parashah: Parashah;
  weekNumber: number;
}
