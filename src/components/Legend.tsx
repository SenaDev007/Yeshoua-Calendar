import React from 'react';
import { useTranslation } from 'react-i18next';

export function Legend() {
  const { t } = useTranslation();

  return (
    <div className="bg-white/10 backdrop-blur-sm p-4 rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold text-white mb-3">{t('legend')}</h3>
      <div className="space-y-2">
        <div className="flex items-center">
          <div className="w-4 h-4 bg-red-500 rounded-full mr-2"></div>
          <span className="text-white">{t('major_feasts')}</span>
        </div>
        <div className="flex items-center">
          <div className="w-4 h-4 bg-blue-500 rounded-full mr-2"></div>
          <span className="text-white">{t('minor_feasts')}</span>
        </div>
        <div className="flex items-center">
          <div className="w-4 h-4 bg-green-500 rounded-full mr-2"></div>
          <span className="text-white">{t('seasons')}</span>
        </div>
      </div>
    </div>
  );
}