import React from 'react';
import { useTranslation } from 'react-i18next';
import { Holiday } from '../types/holiday';

interface HolidayNotificationProps {
  holiday: Holiday;
  onClose: () => void;
}

export function HolidayNotification({ holiday, onClose }: HolidayNotificationProps) {
  const { t } = useTranslation();

  return (
    <div className="fixed bottom-4 right-4 bg-white rounded-lg shadow-lg p-4 max-w-sm w-full z-50 animate-slide-up">
      <div className="flex justify-between items-start mb-2">
        <h3 className="text-lg font-semibold text-gray-900">{t(`${holiday.id}_name`)}</h3>
        <button
          onClick={onClose}
          className="text-gray-500 hover:text-gray-700"
          aria-label={t('close')}
        >
          ×
        </button>
      </div>
      <p className="text-gray-600">{t(`${holiday.id}_description`)}</p>
      <div className="mt-4 flex justify-end">
        <button
          onClick={onClose}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
        >
          {t('close')}
        </button>
      </div>
    </div>
  );
}
