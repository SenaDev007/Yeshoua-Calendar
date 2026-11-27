import React from 'react';
import { useTranslation } from 'react-i18next';
import { translations } from '../data/translations';
import '../styles/festivals.css';

interface FestivalsSectionProps {
  onClose: () => void;
}

export function FestivalsSection({ onClose }: FestivalsSectionProps) {
  const { t, i18n } = useTranslation();
  const currentLang = i18n.language as keyof typeof translations;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
            {t('events_and_feasts')}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            aria-label={t('close')}
          >
            ×
          </button>
        </div>

        <div className="space-y-8">
          {/* Fêtes du Printemps */}
          <div>
            <h3 className="text-xl font-semibold mb-4 text-gray-800 dark:text-gray-200">
              {t('season_spring')}
            </h3>
            <ul className="space-y-2 text-gray-700 dark:text-gray-300">
              <li>• <span className="font-medium">{t('pessah_name')}</span> - {t('pessah_description')}</li>
              <li>• <span className="font-medium">{t('pains_sans_levain_name')}</span> - {t('pains_sans_levain_description')}</li>
              <li>• <span className="font-medium">{t('premices_name')}</span> - {t('premices_description')}</li>
              <li>• <span className="font-medium">{t('shavuot_name')}</span> - {t('shavuot_description')}</li>
            </ul>
          </div>

          {/* Fêtes d'Automne */}
          <div>
            <h3 className="text-xl font-semibold mb-4 text-gray-800 dark:text-gray-200">
              {t('season_autumn')}
            </h3>
            <ul className="space-y-2 text-gray-700 dark:text-gray-300">
              <li>• <span className="font-medium">{t('trompettes_name')}</span> - {t('trompettes_description')}</li>
              <li>• <span className="font-medium">{t('yom_kippour_name')}</span> - {t('yom_kippour_description')}</li>
              <li>• <span className="font-medium">{t('sukkot_name')}</span> - {t('sukkot_description')}</li>
              <li>• <span className="font-medium">{t('shemini_atzeret_name')}</span> - {t('shemini_atzeret_description')}</li>
            </ul>
          </div>

          {/* Saisons */}
          <div>
            <h3 className="text-xl font-semibold mb-4 text-gray-800 dark:text-gray-200">
              {t('seasons')}
            </h3>
            <ul className="space-y-2 text-gray-700 dark:text-gray-300">
              <li>• <span className="font-medium">{t('aviv_name')}</span> - {t('aviv_description')}</li>
              <li>• <span className="font-medium">{t('kayits_name')}</span> - {t('kayits_description')}</li>
              <li>• <span className="font-medium">{t('stav_name')}</span> - {t('stav_description')}</li>
              <li>• <span className="font-medium">{t('horef_name')}</span> - {t('horef_description')}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
