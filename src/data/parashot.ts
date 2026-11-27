import { Parashah, CurrentParashah } from '@/types';

const PARASHOT: Omit<Parashah, 'id'>[] = [
  { 
    name: {
      fr: "Bereshit",
      en: "Bereshit",
      he: "בְּרֵאשִׁית"
    },
    hebrew: "בְּרֵאשִׁית",
    torah: {
      fr: "Genèse 1:1-6:8",
      en: "Genesis 1:1-6:8",
      he: "בראשית א:א-ו:ח"
    },
    haftarah: {
      fr: "Ésaïe 42:5-43:10",
      en: "Isaiah 42:5-43:10",
      he: "ישעיהו מב:ה-מג:י"
    },
    theme: {
      fr: "La Création",
      en: "The Creation",
      he: "הבריאה"
    }
  },
  { 
    name: {
      fr: "Noa'h",
      en: "Noach",
      he: "נֹחַ"
    },
    hebrew: "נֹחַ",
    torah: {
      fr: "Genèse 6:9-11:32",
      en: "Genesis 6:9-11:32",
      he: "בראשית ו:ט-יא:לב"
    },
    haftarah: {
      fr: "Ésaïe 54:1-55:5",
      en: "Isaiah 54:1-55:5",
      he: "ישעיהו נד:א-נה:ה"
    },
    theme: {
      fr: "Le Déluge et Babel",
      en: "The Flood and Babel",
      he: "המבול ומגדל בבל"
    }
  },
  { 
    name: {
      fr: "Le'h Le'ha",
      en: "Lech-Lecha",
      he: "לֶךְ־לְךָ"
    },
    hebrew: "לֶךְ־לְךָ",
    torah: {
      fr: "Genèse 12:1-17:27",
      en: "Genesis 12:1-17:27",
      he: "בראשית יב:א-יז:כז"
    },
    haftarah: {
      fr: "Ésaïe 40:27-41:16",
      en: "Isaiah 40:27-41:16",
      he: "ישעיהו מ:כז-מא:טז"
    },
    theme: {
      fr: "L'appel d'Abraham",
      en: "The Call of Abraham",
      he: "הקריאה לאברהם"
    }
  },
  // ... (autres parashot avec le même format)
  { 
    name: {
      fr: "Vezot Haberakha",
      en: "Vezot Haberachah",
      he: "וְזֹאת הַבְּרָכָה"
    },
    hebrew: "וְזֹאת הַבְּרָכָה",
    torah: {
      fr: "Deutéronome 33:1-34:12",
      en: "Deuteronomy 33:1-34:12",
      he: "דברים לג:א-לד:יב"
    },
    haftarah: {
      fr: "Josué 1:1-18",
      en: "Joshua 1:1-18",
      he: "יהושע א:א-יח"
    },
    theme: {
      fr: "Et voici la bénédiction",
      en: "And this is the blessing",
      he: "וזאת הברכה"
    }
  }
];

// Ajout des IDs aux parashot
const PARASHOT_WITH_IDS: Parashah[] = PARASHOT.map((p, index) => ({
  id: index + 1,
  ...p
}));

/**
 * Obtient la parashah de la semaine en cours selon le calendrier de Qumran
 * @returns Un objet contenant la parashah et le numéro de la semaine
 */
export function getCurrentParashah(): CurrentParashah {
  // Calcul de la semaine selon le calendrier de Qumran (364 jours)
  const now = new Date();
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const diffTime = now.getTime() - startOfYear.getTime();
  const dayOfYear = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  // Adaptation au calendrier de Qumran (52 semaines exactes)
  const qumranWeek = Math.ceil((dayOfYear % 364) / 7) || 1;
  const weekNumber = qumranWeek === 0 ? 52 : qumranWeek;
  
  // Cycle des parashot selon le calendrier de Qumran
  const parashatIndex = (weekNumber - 1) % PARASHOT_WITH_IDS.length;
  
  return {
    parashah: PARASHOT_WITH_IDS[parashatIndex],
    weekNumber
  };
}
