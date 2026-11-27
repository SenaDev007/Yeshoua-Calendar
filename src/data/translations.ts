// Types pour les traductions
export type Language = 'fr' | 'en' | 'he';

type TranslationKey = 
  | 'sunday' | 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday'
  | 'today' | 'year' | 'calendar_title' | 'calendar_subtitle' | 'sabbath' | 'intercalary_day'
  | 'detailed_information' | 'day_of_year' | 'week' | 'season' | 'gregorian_equivalent'
  | 'approximation' | 'events_and_feasts' | 'legend' | 'major_feasts' | 'minor_feasts' | 'fasts'
  | 'about' | 'about_description_1' | 'about_description_2'
  | 'made_by' | 'weekly_parashat' | 'torah_portion'
  | 'holiday_tomorrow' | 'holiday_in_days' | 'holiday_notification_title'
  | 'geolocation_not_supported' | 'geolocation_in_progress' | 'geolocation_error' | 'geolocation_failed'
  | 'local_time' | 'day' | 'night' | 'sunset' | 'sunrise' | 'real_time' | 'hebrew_time'
  | 'month_aviv_nissan' | 'month_iyyar' | 'month_sivan' | 'month_tammuz' | 'month_av'
  | 'month_elul' | 'month_tishri' | 'month_cheshvan' | 'month_kislev' | 'month_tevet'
  | 'month_shevat' | 'month_adar'
  | 'season_spring' | 'season_summer' | 'season_autumn' | 'season_winter'
  // Nouvelles clés pour les fêtes
  | 'pessah_name' | 'pessah_description'
  | 'pains_sans_levain_name' | 'pains_sans_levain_description'
  | 'premices_name' | 'premices_description'
  | 'shavuot_name' | 'shavuot_description'
  | 'trompettes_name' | 'trompettes_description'
  | 'yom_kippour_name' | 'yom_kippour_description'
  | 'sukkot_name' | 'sukkot_description'
  | 'shemini_atzeret_name' | 'shemini_atzeret_description'
  | 'aviv_name' | 'aviv_description'
  | 'kayits_name' | 'kayits_description'
  | 'stav_name' | 'stav_description'
  | 'horef_name' | 'horef_description';

type Translations = {
  [key in Language]: {
    [key in TranslationKey]: string;
  };
};

// Traductions disponibles
export const translations: Translations = {
  fr: {
    // Footer
    'made_by': 'Réalisé par le frère AKPOVI TOHOU Sènakpon Dawes',
    
    // Jours de la semaine
    'sunday': 'Dimanche',
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    
    // Interface
    'today': 'Aujourd\'hui',
    'year': 'Année',
    'calendar_title': 'CALENDRIER DE YHWH ELOHIM',
    'calendar_subtitle': 'Yeshoua et la Torah',
    'sabbath': 'Shabbat',
    'intercalary_day': 'Jour intercalaire',
    'detailed_information': 'Informations détaillées',
    'day_of_year': 'Jour de l\'année',
    'week': 'Semaine',
    'season': 'Saison',
    'gregorian_equivalent': 'Équivalence grégorienne',
    'approximation': 'Approximation',
    'events_and_feasts': 'Événements et fêtes',
    'legend': 'Légende',
    'major_feasts': 'Fêtes majeures',
    'minor_feasts': 'Fêtes mineures',
    'fasts': 'Jeûnes',
    'about': 'À propos',
    'about_description_1': 'Le calendrier de YHWH Elohim est un calendrier solaire de 364 jours décrit dans le Livre d\'Henock, dans le Livre des Jubilés et dans les manuscrits de Qumran, qui commence toujours un mercredi et se termine un mardi. Chaque année contient exactement 52 semaines (52 × 7 = 364 jours).',
    'about_description_2': 'Les mois font 30 jours normalement, mais chaque 3ème mois (Sivan, Elul, Tevet, Adar) a 31 jours avec un jour intercalaire. Structure: 4 saisons × (30 + 30 + 31) = 4 × 91 = 364 jours.',
    'weekly_parashat': 'Parashat de la semaine',
    'torah_portion': 'Portion de la Torah',
    'month_aviv_nissan': 'Aviv/Nissan',
    'month_iyyar': 'Iyyar',
    'month_sivan': 'Sivan',
    'month_tammuz': 'Tammuz',
    'month_av': 'Av',
    'month_elul': 'Elul',
    'month_tishri': 'Tishri',
    'month_cheshvan': 'Cheshvan',
    'month_kislev': 'Kislev',
    'month_tevet': 'Tevet',
    'month_shevat': 'Shevat',
    'month_adar': 'Adar',
    'season_spring': 'Printemps',
    'season_summer': 'Été',
    'season_autumn': 'Automne',
    'season_winter': 'Hiver',
    'holiday_tomorrow': 'Demain: {holiday}',
    'holiday_in_days': 'Dans {days} jours: {holiday}',
    'holiday_notification_title': 'Fête à venir',
    
    // HebrewClock
    'geolocation_not_supported': 'Géolocalisation non supportée par votre navigateur',
    'geolocation_in_progress': 'Localisation en cours...',
    'geolocation_error': 'Erreur de géolocalisation',
    'geolocation_failed': 'Impossible de récupérer votre position',
    'local_time': 'Heure locale',
    'day': 'Jour',
    'night': 'Nuit',
    'sunset': 'Coucher',
    'sunrise': 'Lever',
    'real_time': 'Temps réel',
    'hebrew_time': 'Heure hébraïque',

    // Nouvelles traductions pour les fêtes
    'pessah_name': 'Pessa\'h (Pâque)',
    'pessah_description': 'La fête de la Pâque commémore la libération des Israélites de l\'esclavage en Égypte. C\'est le jour où l\'agneau pascal était sacrifié.',
    'pains_sans_levain_name': 'Hag HaMatzot (Pains Sans Levain)',
    'pains_sans_levain_description': 'Cette fête de 7 jours suit immédiatement Pessa\'h. Elle commémore la sortie précipitée d\'Égypte, sans temps pour faire lever le pain.',
    'premices_name': 'HaBikkurim (Prémices de la moisson)',
    'premices_description': 'Jour de l\'offrande des premiers fruits de la moisson d\'orge, symbolisant la reconnaissance envers YHWH pour ses bénédictions.',
    'shavuot_name': 'Shavouot (Semaines/Pentecôte)',
    'shavuot_description': 'Fête des Semaines, célébrée 50 jours après les Prémices. Commémore le don de la Torah et la moisson du blé.',
    'trompettes_name': 'Yom Terouah (Fête des Trompettes)',
    'trompettes_description': 'Jour saint marqué par le son des trompettes, annonçant le début de la période des fêtes d\'automne.',
    'yom_kippour_name': 'Yom Kippour (Jour des Expiations)',
    'yom_kippour_description': 'Jour le plus saint de l\'année, consacré au jeûne et à la repentance, où le grand prêtre entrait dans le Saint des Saints.',
    'sukkot_name': 'Soukkot (Fête des Tabernacles)',
    'sukkot_description': 'Fête de 7 jours commémorant le séjour des Israélites dans le désert et célébrant la récolte d\'automne.',
    'shemini_atzeret_name': 'Shemini Atzeret (8ème jour de clôture)',
    'shemini_atzeret_description': 'Jour de clôture solennel des fêtes d\'automne, marquant la fin du cycle annuel des fêtes.',
    'aviv_name': 'Début du Printemps (Aviv)',
    'aviv_description': 'Commencement de la saison du printemps, marquant le renouveau de la nature et le début de l\'année agricole.',
    'kayits_name': 'Début de l\'Été (Kayits)',
    'kayits_description': 'Début de la saison estivale, période de croissance et de maturation des cultures.',
    'stav_name': 'Début de l\'Automne (Stav)',
    'stav_description': 'Commencement de l\'automne, saison des récoltes et des fêtes d\'automne.',
    'horef_name': 'Début de l\'Hiver (Horef)',
    'horef_description': 'Début de la saison hivernale, période de repos de la terre et de préparation pour le nouveau cycle.',
  },
  en: {
    // Footer
    'made_by': 'Made by brother AKPOVI TOHOU Sènakpon Dawes',
    
    // Jours de la semaine
    'sunday': 'Sunday',
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    
    // Interface
    'today': 'Today',
    'year': 'Year',
    'calendar_title': 'YHWH ELOHIM CALENDAR',
    'calendar_subtitle': 'Yeshua and the Torah',
    'sabbath': 'Shabbat',
    'intercalary_day': 'Intercalary day',
    'detailed_information': 'Detailed Information',
    'day_of_year': 'Day of year',
    'week': 'Week',
    'season': 'Season',
    'gregorian_equivalent': 'Gregorian equivalent',
    'approximation': 'Approximation',
    'events_and_feasts': 'Events and Feasts',
    'legend': 'Legend',
    'major_feasts': 'Major Feasts',
    'minor_feasts': 'Minor Feasts',
    'fasts': 'Fasts',
    'about': 'About',
    'about_description_1': 'The YHWH Elohim calendar is a 364-day solar calendar described in the Book of Enoch, the Book of Jubilees, and the Qumran manuscripts. It is perfectly divisible by 7, creating exactly 52 weeks per year.',
    'about_description_2': 'Each year begins on a Wednesday and maintains an unchangeable structure, unlike the traditional lunar calendar.',
    'weekly_parashat': 'Weekly Parashat',
    'torah_portion': 'Torah Portion',
    'month_aviv_nissan': 'Aviv/Nissan',
    'month_iyyar': 'Iyyar',
    'month_sivan': 'Sivan',
    'month_tammuz': 'Tammuz',
    'month_av': 'Av',
    'month_elul': 'Elul',
    'month_tishri': 'Tishri',
    'month_cheshvan': 'Cheshvan',
    'month_kislev': 'Kislev',
    'month_tevet': 'Tevet',
    'month_shevat': 'Shevat',
    'month_adar': 'Adar',
    'season_spring': 'Spring',
    'season_summer': 'Summer',
    'season_autumn': 'Autumn',
    'season_winter': 'Winter',
    'holiday_tomorrow': 'Tomorrow: {holiday}',
    'holiday_in_days': 'In {days} days: {holiday}',
    'holiday_notification_title': 'Upcoming Feast',
    
    // HebrewClock
    'geolocation_not_supported': 'Geolocation is not supported by your browser',
    'geolocation_in_progress': 'Getting location...',
    'geolocation_error': 'Geolocation error',
    'geolocation_failed': 'Unable to retrieve your location',
    'local_time': 'Local time',
    'day': 'Day',
    'night': 'Night',
    'sunset': 'Sunset',
    'sunrise': 'Sunrise',
    'real_time': 'Real time',
    'hebrew_time': 'Hebrew time',

    // New translations for feasts
    'pessah_name': 'Pesach (Passover)',
    'pessah_description': 'The Feast of Passover commemorates the liberation of the Israelites from slavery in Egypt. It is the day when the Passover lamb was sacrificed.',
    'pains_sans_levain_name': 'Hag HaMatzot (Unleavened Bread)',
    'pains_sans_levain_description': 'This 7-day feast immediately follows Passover. It commemorates the hasty departure from Egypt, without time for the bread to rise.',
    'premices_name': 'HaBikkurim (First Fruits)',
    'premices_description': 'Day of offering the first fruits of the barley harvest, symbolizing gratitude to YHWH for His blessings.',
    'shavuot_name': 'Shavuot (Weeks/Pentecost)',
    'shavuot_description': 'Feast of Weeks, celebrated 50 days after First Fruits. Commemorates the giving of the Torah and the wheat harvest.',
    'trompettes_name': 'Yom Teruah (Feast of Trumpets)',
    'trompettes_description': 'Holy day marked by the sound of trumpets, announcing the beginning of the autumn feast period.',
    'yom_kippour_name': 'Yom Kippur (Day of Atonement)',
    'yom_kippour_description': 'The holiest day of the year, dedicated to fasting and repentance, when the high priest entered the Holy of Holies.',
    'sukkot_name': 'Sukkot (Feast of Tabernacles)',
    'sukkot_description': '7-day feast commemorating the Israelites\' stay in the wilderness and celebrating the autumn harvest.',
    'shemini_atzeret_name': 'Shemini Atzeret (Eighth Day of Assembly)',
    'shemini_atzeret_description': 'Solemn closing day of the autumn feasts, marking the end of the annual feast cycle.',
    'aviv_name': 'Beginning of Spring (Aviv)',
    'aviv_description': 'Start of the spring season, marking the renewal of nature and the beginning of the agricultural year.',
    'kayits_name': 'Beginning of Summer (Kayits)',
    'kayits_description': 'Start of the summer season, period of growth and crop maturation.',
    'stav_name': 'Beginning of Autumn (Stav)',
    'stav_description': 'Start of autumn, season of harvests and autumn feasts.',
    'horef_name': 'Beginning of Winter (Horef)',
    'horef_description': 'Start of the winter season, period of rest for the land and preparation for the new cycle.',
  },
  he: {
    // Footer
    'made_by': 'נערך על ידי האח AKPOVI TOHOU Sènakpon Dawes',
    
    // Jours de la semaine
    'sunday': 'יום ראשון',
    'monday': 'יום שני',
    'tuesday': 'יום שלישי',
    'wednesday': 'יום רביעי',
    'thursday': 'יום חמישי',
    'friday': 'יום שישי',
    'saturday': 'שבת',
    
    // Interface
    'today': 'היום',
    'year': 'שנה',
    'calendar_title': 'לוח השנה של יהוה אלוהים',
    'calendar_subtitle': 'ישוע והתורה',
    'sabbath': 'שבת',
    'intercalary_day': 'יום מעובר',
    'detailed_information': 'מידע מפורט',
    'day_of_year': 'יום בשנה',
    'week': 'שבוע',
    'season': 'עונה',
    'gregorian_equivalent': 'תאריך גרגוריאני מקביל',
    'approximation': 'קירוב',
    'events_and_feasts': 'אירועים וחגים',
    'legend': 'מקרא',
    'major_feasts': 'חגים עיקריים',
    'minor_feasts': 'חגים משניים',
    'fasts': 'צומות',
    'about': 'על',
    'about_description_1': 'לוח השנה של יהוה אלוהים הוא לוח שמשי בן 364 ימים המתואר בספר חנוך, בספר היובלות ובמגילות קומראן. הוא מתחלק בצורה מושלמת ל-7, ויוצר בדיוק 52 שבועות בשנה.',
    'about_description_2': 'כל שנה מתחילה ביום רביעי ושומרת על מבנה בלתי משתנה, בניגוד לוח הירחי המסורתי.',
    'weekly_parashat': 'פרשת השבוע',
    'torah_portion': 'פרשת השבוע',
    'month_aviv_nissan': 'אביב/ניסן',
    'month_iyyar': 'אייר',
    'month_sivan': 'סיון',
    'month_tammuz': 'תמוז',
    'month_av': 'אב',
    'month_elul': 'אלול',
    'month_tishri': 'תשרי',
    'month_cheshvan': 'חשוון',
    'month_kislev': 'כסלו',
    'month_tevet': 'טבת',
    'month_shevat': 'שבט',
    'month_adar': 'אדר',
    'season_spring': 'אביב',
    'season_summer': 'קיץ',
    'season_autumn': 'סתיו',
    'season_winter': 'חורף',
    'holiday_tomorrow': 'מחר: {holiday}',
    'holiday_in_days': 'בעוד {days} ימים: {holiday}',
    'holiday_notification_title': 'חג מתקרב',
    
    // HebrewClock
    'geolocation_not_supported': 'הדפדפן שלך אינו תומך במיקום גיאוגרפי',
    'geolocation_in_progress': 'מאתר את מיקומך...',
    'geolocation_error': 'שגיאה באיתור מיקום',
    'geolocation_failed': 'לא ניתן לאחזר את המיקום שלך',
    'local_time': 'שעה מקומית',
    'day': 'יום',
    'night': 'לילה',
    'sunset': 'שקיעה',
    'sunrise': 'זריחה',
    'real_time': 'זמן אמת',
    'hebrew_time': 'שעה עברית',

    // תרגומים חדשים לחגים
    'pessah_name': 'פסח',
    'pessah_description': 'חג הפסח מציין את שחרור בני ישראל מעבדות במצרים. זהו היום שבו נשחט קורבן הפסח.',
    'pains_sans_levain_name': 'חג המצות',
    'pains_sans_levain_description': 'חג בן 7 ימים המתחיל מיד לאחר פסח. הוא מציין את היציאה החפוזה ממצרים, ללא זמן להחמצת הלחם.',
    'premices_name': 'הביכורים',
    'premices_description': 'יום הקרבת ראשית קציר השעורה, המסמל את הכרת התודה ליהוה על ברכותיו.',
    'shavuot_name': 'שבועות',
    'shavuot_description': 'חג השבועות, נחגג 50 יום לאחר הביכורים. מציין את מתן התורה ואת קציר החיטה.',
    'trompettes_name': 'יום תרועה',
    'trompettes_description': 'יום קודש המסומן בקול השופרות, מבשר את תחילת תקופת חגי הסתיו.',
    'yom_kippour_name': 'יום הכיפורים',
    'yom_kippour_description': 'היום הקדוש ביותר בשנה, מוקדש לצום ולחזרה בתשובה, כאשר הכהן הגדול נכנס לקודש הקודשים.',
    'sukkot_name': 'חג הסוכות',
    'sukkot_description': 'חג בן 7 ימים המציין את שהות בני ישראל במדבר וחוגג את קציר הסתיו.',
    'shemini_atzeret_name': 'שמיני עצרת',
    'shemini_atzeret_description': 'יום סיום חגיגי של חגי הסתיו, מסמן את סוף מחזור החגים השנתי.',
    'aviv_name': 'תחילת האביב (אביב)',
    'aviv_description': 'תחילת עונת האביב, מסמן את התחדשות הטבע ואת תחילת השנה החקלאית.',
    'kayits_name': 'תחילת הקיץ (קיץ)',
    'kayits_description': 'תחילת עונת הקיץ, תקופת צמיחה והבשלת היבולים.',
    'stav_name': 'תחילת הסתיו (סתיו)',
    'stav_description': 'תחילת הסתיו, עונת הקציר וחגי הסתיו.',
    'horef_name': 'תחילת החורף (חורף)',
    'horef_description': 'תחילת עונת החורף, תקופת מנוחה לאדמה והכנה למחזור החדש.',
  }
} as const;
