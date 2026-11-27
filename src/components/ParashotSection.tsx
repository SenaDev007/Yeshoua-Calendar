import React from 'react';
import { QumranDate } from '../types/calendar';
import { parashot } from '../data/parashot-data';
import '../styles/parashot.css';

interface ParashotSectionProps {
  date: QumranDate | null;
}

const ParashotSection: React.FC<ParashotSectionProps> = ({ date }) => {

  // Fonction pour formater une date en string "XX/XX/XXXX"
  const formatDate = (date: Date): string => {
    return date.toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  // Calculer la parashah actuelle selon le calendrier de Qumran
  const getCurrentParashah = () => {
    if (!date) return null;
    
    // Le calendrier de Qumran a 364 jours (52 semaines)
    // Les parashot sont réparties sur ces 52 semaines
    const weekNumber = Math.floor((date.day + (date.month - 1) * 30) / 7);
    const parashahNumber = (weekNumber % 54) + 1;

    // Trouver la parashah correspondante
    const currentParashah = parashot.find(p => p.id === parashahNumber);
    return currentParashah;
  };

  const currentParashah = getCurrentParashah();

  if (!currentParashah || !date) {
    return null;
  }

  // Calculer la date de début et de fin de la semaine
  const startDate = new Date(date.gregorianDate);
  const endDate = new Date(date.gregorianDate);
  endDate.setDate(startDate.getDate() + 6);

  return (
    <div className="parashot-section p-4 rounded-lg">
      <h2 className="text-2xl font-bold text-white mb-4">Parashah Hebdomadaire N°{currentParashah.id}</h2>
      <div className="space-y-2">
        <div className={`text-xl font-semibold ${currentParashah.name === 'Vayigash' ? 'parashah-vayigash' : ''}`}>
          {currentParashah.name === 'Vayigash' ? (
            <span className="parashah-vayigash">{currentParashah.name} ({currentParashah.hebrew})</span>
          ) : (
            <span>{currentParashah.name} ({currentParashah.hebrew})</span>
          )}
        </div>
        <div className="text-amber-200">
          <span className="parashot-keyword">Thème</span>: {currentParashah.theme}
        </div>
        <div className="text-amber-200">
          <span className="parashot-keyword">Torah</span>: {currentParashah.torah}
        </div>
        <div className="text-amber-200">
          <span className="parashot-keyword">Haftarah</span>: {currentParashah.haftarah}
        </div>
        <div className="text-sm mt-2 parashot-period">
          Semaine du {formatDate(startDate)} au {formatDate(endDate)}
        </div>
      </div>
    </div>
  );
};

export default ParashotSection;
