import React from 'react';
import { useTranslation } from 'react-i18next';
import { QumranDate } from '../types/calendar';
import { QumranCalculator } from '../utils/qumran-calculator';
import { MONTHS, SEASONS, DAYS_OF_WEEK } from '../data/calendar-constants';
import type { Language } from '../data/translations';
import { Clock, Star, Sun, CalendarDays, Calendar } from 'lucide-react';
import { getHolidayForDate } from '../data/holidays';

interface DateInfoProps {
  date: QumranDate;
}

// Fonction pour obtenir la description d'une fête en fonction de son ID
const getHolidayDescription = (holidayId: string): string => {
  const descriptions: Record<string, string> = {
    'pessah': 'La Pâque commémore la sortie d\'Égypte des Israélites et est célébrée par un repas rituel appelé le Seder.',
    'pains-sans-levain': 'La Fête des Pains sans Levain dure 7 jours et commémore la hâte avec laquelle les Israélites ont quitté l\'Égypte.',
    'pessah-sheni': 'La Seconde Pâque offre une seconde chance d\'observer la Pâque à ceux qui étaient impurs ou en voyage lors de la première date.',
    'premices': 'Fête des Prémices, où les premiers fruits de la récolte d\'orge étaient apportés au Temple.',
    'shavuot': 'Fête des Semaines ou Pentecôte, commémorant le don de la Torah au mont Sinaï et marquant la fin de la récolte du blé.',
    'trompettes': 'Fête des Trompettes, marquant le début de l\'année civile juive et un temps de préparation spirituelle.',
    'yom-kippurim': 'Jour des Expiations, jour le plus saint de l\'année juive, marqué par le jeûne et la prière.',
    'sukkot': 'Fête des Cabanes, commémorant les 40 années passées dans le désert après l\'Exode d\'Égypte.',
    'shemini-atzeret': 'Huitième jour de clôture, marquant la fin du cycle des fêtes d\'automne.',
    'bikkurim-yayin': 'Prémices du vin, marquant le début de l\'offrande des prémices du vin au Temple.',
    'bikkurim-shemen': 'Prémices de l\'huile, marquant le début de l\'offrande des prémices de l\'huile d\'olive au Temple.',
    'hanoucca': 'Fête des Lumières, commémorant la réinauguration du Second Temple de Jérusalem.',
    'pourim': 'Fête des Sorts, célébrant la délivrance des Juifs de Perse du complot d\'Haman.',
    'tu-bishvat': 'Nouvel An des Arbres, marquant le début de la saison de plantation en Israël.',
    'lag-baomer': '33ème jour du décompte du Omer, marquant la fin d\'une épidémie parmi les disciples de Rabbi Akiva.',
    'tu-bav': 'Fête de l\'amour, marquant plusieurs événements joyeux dans l\'histoire juive.',
    'jeune-4eme-mois': 'Jeûne du 4ème mois, commémorant la brèche des murs de Jérusalem avant la destruction du Temple.',
    'tisha-bav': 'Neuf Av, jour de deuil commémorant la destruction des Premier et Deuxième Temples de Jérusalem.',
    'jeune-gedalia': 'Jeûne de Guedalia, commémorant l\'assassinat du gouverneur juif de Judée.',
    'jeune-10eme-mois': 'Jeûne du 10ème mois, commémorant le début du siège de Jérusalem par Nabuchodonosor.',
    'yom-hashoah': 'Jour du Souvenir de la Shoah, en mémoire des six millions de Juifs victimes de l\'Holocauste.',
    'yom-hazikaron': 'Jour du Souvenir des Soldats, en mémoire des soldats tombés pour la défense d\'Israël.',
    'yom-haatzmaout': 'Fête de l\'Indépendance d\'Israël, célébrant la déclaration d\'indépendance en 1948.',
    'yom-yerushalayim': 'Jour de Jérusalem, commémorant la réunification de Jérusalem en 1967.',
    'tekufah-nissan': 'Équinoxe de printemps, marquant le début de la saison du printemps.',
    'tekufah-tamouz': 'Solstice d\'été, jour le plus long de l\'année dans l\'hémisphère nord.',
    'tekufah-tishri': 'Équinoxe d\'automne, marquant le début de la saison d\'automne.',
    'tekufah-tevet': 'Solstice d\'hiver, jour le plus court de l\'année dans l\'hémisphère nord.'
  };
  
  return descriptions[holidayId] || 'Fête importante du calendrier biblique.';
};

export function DateInfo({ date }: DateInfoProps) {
  const { t, i18n } = useTranslation();
  const currentLang = i18n.language as Language;
  const calculator = QumranCalculator.getInstance();
  const gregorianDate = calculator.toGregorianApprox(date);
  
  // Récupérer les informations sur la fête du jour
  const holiday = getHolidayForDate(date);
  const isHoliday = !!holiday;

  return (
    <div className="bg-gray-200 rounded-lg shadow-lg p-6 space-y-6">
      <div className="bg-gradient-radial-header rounded-t-lg -m-6 mb-4 p-4 text-white">
        <h3 className="text-xl font-bold flex items-center">
          <Calendar className="w-5 h-5 mr-2 text-white" />
          {t('detailed_information')}
        </h3>
        <div className="text-lg text-amber-500 font-semibold">
          {DAYS_OF_WEEK[gregorianDate.getDay()].name[currentLang]} {gregorianDate.getDate()} {MONTHS[gregorianDate.getMonth()].name[currentLang]} {gregorianDate.getFullYear()}
        </div>
      </div>

      {isHoliday && (
        <div className="bg-amber-50 border-l-4 border-amber-400 p-4 rounded-r-lg mb-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <CalendarDays className="h-5 w-5 text-amber-700" />
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-amber-800">
                {holiday.name}
              </h3>
              <div className="mt-2 text-sm text-amber-700">
                <p>
                  {getHolidayDescription(holiday.id)}
                </p>
                {holiday.duration && holiday.duration > 1 && (
                  <p className="mt-1 text-amber-600">
                    Durée: {holiday.duration} jours
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid md:grid-cols-2 gap-4">
        <div className="space-y-3">
          <div className="flex items-center">
            <Clock className="w-4 h-4 mr-2 text-gray-500" />
            <div>
              <div className="text-sm text-gray-600">{t('day_of_year')}</div>
              <div className="font-semibold">{date.dayOfYear} / 364</div>
            </div>
          </div>

          <div className="flex items-center">
            <Star className="w-4 h-4 mr-2 text-gray-500" />
            <div>
              <div className="text-sm text-gray-600">{t('week')}</div>
              <div className="font-semibold">{date.weekOfYear} / 52</div>
            </div>
          </div>

          <div className="flex items-center">
            <Sun className="w-4 h-4 mr-2 text-gray-500" />
            <div>
              <div className="text-sm text-gray-600">{t('season')}</div>
              <div className="font-semibold">{SEASONS[date.season - 1].name[currentLang]}</div>
            </div>
          </div>
        </div>

        <div className="space-y-3">
          <div>
            <div className="text-sm text-gray-600">{t('gregorian_equivalent')}</div>
            <div className="font-semibold">
              {gregorianDate.toLocaleDateString(currentLang, {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </div>
            <div className="text-xs text-gray-500">{t('approximation')}</div>
          </div>

          <div className="flex flex-wrap gap-2">
            {calculator.isSabbath(gregorianDate.getDay()) && (
              <span className="bg-amber-500 text-white px-2 py-1 rounded-full text-xs font-medium shadow-sm">
                {t('sabbath')}
              </span>
            )}
            {date.isIntercalary && (
              <span className="bg-orange-100 text-orange-800 px-2 py-1 rounded-full text-xs font-medium">
                {t('intercalary_day')}
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}