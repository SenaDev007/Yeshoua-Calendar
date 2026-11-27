import React from 'react';
import { SeasonNumber } from '../types/calendar';

interface SeasonalBackgroundProps {
  season: SeasonNumber;
  children: React.ReactNode;
}

const SeasonalBackground: React.FC<SeasonalBackgroundProps> = ({ season, children }) => {
  // Déterminer la classe CSS en fonction de la saison
  const getBackgroundClass = () => {
    switch (season) {
      case 1: // Printemps
        return 'bg-printemps';
      case 2: // Été
        return 'bg-ete';
      case 3: // Automne
        return 'bg-automne';
      case 4: // Hiver
        return 'bg-hiver';
      default:
        return 'bg-printemps';
    }
  };

  return (
    <div className={`min-h-screen bg-cover bg-center bg-fixed transition-all duration-1000 brightness-110 ${getBackgroundClass()}`}>
      <div className="bg-black bg-opacity-30 min-h-screen">
        {children}
      </div>
    </div>
  );
};

export { SeasonalBackground };
