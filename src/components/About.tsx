import { useTranslation } from 'react-i18next';

interface AboutProps {
  onClose: () => void;
}

export function About({ onClose }: AboutProps) {
  const { t } = useTranslation();

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold text-gray-900">{t('about')}</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
            aria-label={t('close')}
          >
            ×
          </button>
        </div>
        <div className="space-y-4">
          <div className="text-gray-600">
            <p>{t('about_description_1')}</p>
            <p className="mt-2">{t('about_description_2')}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
