import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { getSunriseSunset, type SunriseSunsetData } from '../services/weatherService';
import { QumranCalculator } from '../utils/qumran-calculator';
import { QumranDate } from '../types/calendar';

interface HebrewClockProps {
  languageSelector?: React.ReactNode;
}

interface Position {
  latitude: number;
  longitude: number;
}

export function HebrewClock({ languageSelector }: HebrewClockProps) {
  const { t } = useTranslation();
  const [currentTime, setCurrentTime] = useState<QumranDate>(QumranCalculator.getInstance().getCurrentQumranDate());
  const [position, setPosition] = useState<Position | null>(null);
  const [sunData, setSunData] = useState<SunriseSunsetData | null>(null);
  const [locationStatus, setLocationStatus] = useState<string>('');
  
  // Calculer les heures de lever/coucher du soleil avec des périodes fixes de 12h
  const { sunrise, sunset, displaySunrise, displaySunset } = useMemo(() => {
    if (sunData) {
      const sunsetTime = new Date(sunData.sunset);
      const sunriseTime = new Date(sunData.sunrise);
      
      // Créer une période de nuit de 12h à partir du coucher du soleil
      const nightEnd = new Date(sunsetTime);
      nightEnd.setHours(sunsetTime.getHours() + 12);
      
      // Créer une période de jour de 12h à partir de la fin de la nuit
      const nextSunset = new Date(nightEnd);
      nextSunset.setHours(nightEnd.getHours() + 12);
      
      return {
        // Heures réelles pour référence
        sunrise: sunriseTime,
        sunset: sunsetTime,
        // Heures d'affichage avec périodes fixes de 12h
        displaySunrise: nightEnd, // Lever du soleil = fin de la période de nuit
        displaySunset: nextSunset // Prochain coucher = fin de la période de jour
      };
    }
    
    // Valeurs par défaut si les données ne sont pas encore chargées
    const defaultSunset = new Date();
    defaultSunset.setHours(18, 0, 0, 0);
    
    const defaultSunrise = new Date(defaultSunset);
    defaultSunrise.setHours(defaultSunset.getHours() - 12);
    
    const displaySunrise = new Date(defaultSunset);
    displaySunrise.setHours(defaultSunset.getHours() + 12);
    
    const displaySunset = new Date(displaySunrise);
    displaySunset.setHours(displaySunrise.getHours() + 12);
    
    return {
      sunrise: defaultSunrise,
      sunset: defaultSunset,
      displaySunrise,
      displaySunset
    };
  }, [sunData]);

  // Obtenir la position de l'utilisateur
  const getLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setLocationStatus(t('geolocation_not_supported'));
      return;
    }

    setLocationStatus(t('geolocation_in_progress'));
    
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const newPosition = {
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude
        };
        setPosition(newPosition);
        setLocationStatus('');
        return newPosition;
      },
      (error) => {
        console.error(t('geolocation_error'), error);
        setLocationStatus(t('geolocation_failed'));
        // Utiliser Jérusalem comme position par défaut
        const defaultPosition = {
          latitude: 31.7683,
          longitude: 35.2137
        };
        setPosition(defaultPosition);
        return defaultPosition;
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    );
  }, [t]); // Ajout de t comme dépendance

  // Charger les données de lever/coucher du soleil
  useEffect(() => {
    const fetchSunData = async () => {
      if (!position) return;
      
      try {
        const data = await getSunriseSunset(position);
        setSunData(data);
      } catch (error) {
        console.error('Erreur lors du chargement des données solaires:', error);
        setLocationStatus('Erreur de chargement des données solaires');
      }
    };

    fetchSunData();
    
    // Rafraîchir les données toutes les heures
    const interval = setInterval(fetchSunData, 60 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, [position]);

  // Mettre à jour l'heure actuelle
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(QumranCalculator.getInstance().getCurrentQumranDate());
    }, 1000);
    
    // Obtenir la position au chargement
    getLocation();
    
    return () => clearInterval(timer);
  }, [getLocation]);

  // Formater l'heure en format court
  const formatTimeShort = (date: Date) => {
    return date.toLocaleTimeString('fr-FR', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: false 
    });
  };

  // Formater l'heure complète
  const formatTime = (date: Date): string => {
    return date.toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false
    });
  };

  // Calculer si c'est le jour ou la nuit en fonction des heures de lever/coucher
  const isDaytime = useMemo(() => {
    const now = currentTime.getTime();
    return now >= sunrise.getTime() && now < sunset.getTime();
  }, [currentTime, sunrise, sunset]);

  // Calculer l'heure hébraïque (1-12) avec des périodes fixes de 12 heures
  const hebrewHour = useMemo(() => {
    const now = currentTime;
    let periodStart, periodEnd;
    
    if (isDaytime) {
      // Période de jour : de sunrise à sunset (12 heures)
      periodStart = new Date(sunrise);
      periodEnd = new Date(sunrise);
      periodEnd.setHours(periodStart.getHours() + 12);
    } else {
      // Période de nuit : de sunset à sunrise du lendemain (12 heures)
      periodStart = new Date(sunset);
      periodEnd = new Date(sunset);
      periodEnd.setHours(periodStart.getHours() + 12);
    }
    
    const periodDuration = periodEnd.getTime() - periodStart.getTime();
    const elapsed = now.getTime() - periodStart.getTime();
    let hebrewHour = Math.floor((elapsed / (periodDuration / 12)) % 12) + 1;
    
    // Ajuster pour être sûr d'avoir une valeur entre 1 et 12
    hebrewHour = ((hebrewHour - 1) % 12) + 1;
    if (hebrewHour < 1) hebrewHour += 12;
    
    return hebrewHour;
  }, [currentTime, isDaytime, sunrise, sunset]);

  // Formater l'heure hébraïque
  const hebrewTimeString = useMemo(() => {
    return isDaytime 
      ? `${hebrewHour}ème heure du jour`
      : `${hebrewHour}ème heure de la nuit`;
  }, [hebrewHour, isDaytime]);

  // Calculer les plages horaires pour l'affichage avec des périodes fixes de 12h
  const { nightStart, nightEnd, dayStart, dayEnd } = useMemo(() => {
    const now = new Date();
    
    // Fonction utilitaire pour créer une période de 12h
    const create12HourPeriod = (baseDate: Date) => {
      const start = new Date(baseDate);
      const end = new Date(start);
      end.setHours(start.getHours() + 12);
      return { start, end };
    };

    if (!sunData) {
      // Si les données ne sont pas encore chargées, utiliser des valeurs par défaut
      const defaultNightStart = new Date(now);
      defaultNightStart.setHours(18, 0, 0, 0);
      
      const { start: defaultNightStart2, end: defaultNightEnd } = create12HourPeriod(defaultNightStart);
      const { start: dayStart, end: dayEnd } = create12HourPeriod(defaultNightEnd);
      
      return {
        nightStart: defaultNightStart2,
        nightEnd: defaultNightEnd,
        dayStart,
        dayEnd
      };
    }
    
    // Créer des périodes fixes de 12h basées sur les heures de lever/coucher
    const { start: nightStart, end: nightEnd } = create12HourPeriod(new Date(sunset));
    const { start: dayStart, end: dayEnd } = create12HourPeriod(nightEnd);
    
    return {
      nightStart,
      nightEnd,
      dayStart,
      dayEnd
    };
  }, [sunData, sunset]); // Dépend de sunData et sunset pour se recalculer

  return (
    <div className="flex flex-col space-y-3 px-6 py-3 bg-gradient-radial-header rounded-lg shadow-lg">
      <div className="flex flex-wrap items-center justify-between gap-4">
        {/* Heure locale et état jour/nuit */}
        <div className="flex items-center">
          <div className="flex items-center space-x-2">
            <span className="text-sm font-medium text-white">
              {formatTime(currentTime)} ({t('local_time')})
            </span>
            <span className={`px-2 py-1 text-xs rounded-full ${
              isDaytime ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'
            }`}>
              {isDaytime ? t('day') : t('night')}
            </span>
          </div>

          {/* Heures de lever/coucher */}
          <div className="flex items-center space-x-3 text-xs ml-3">
            <div className="flex items-center space-x-1">
              <span className="text-blue-400">🌙</span>
              <span className="text-white/80" title={`${t('sunset')} (${t('real_time')}: ${formatTimeShort(sunset)})`}>
                {formatTimeShort(displaySunset)}
              </span>
            </div>
            <div className="flex items-center space-x-1">
              <span className="text-yellow-500">☀️</span>
              <span className="text-white/80" title={`${t('sunrise')} (${t('real_time')}: ${formatTimeShort(sunrise)})`}>
                {formatTimeShort(displaySunrise)}
              </span>
            </div>
          </div>
        </div>

        {/* Séparateur */}
        <div className="w-px h-8 bg-gray-600/50" />

        {/* Heure hébraïque */}
        <div className="text-xs text-white/80">
          <div className="text-sm">
            <span className="text-amber-400 font-medium">{t('hebrew_time')}:</span>{' '}
            <span className="font-medium text-white">{hebrewTimeString}</span>
          </div>
        </div>

        {/* Périodes jour/nuit */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-black p-2 rounded-lg min-w-[120px] relative overflow-hidden">
            <div className="absolute -right-2 -bottom-2 text-blue-200/25 text-6xl">
              🌙
            </div>
            <div className="relative z-10">
              <div className="font-medium text-xs text-white">{t('night')} (12h)</div>
              <div className="text-xs py-0.5 text-gray-200">
                {formatTimeShort(nightStart)} - {formatTimeShort(nightEnd)}
              </div>
            </div>
          </div>
          <div className="bg-white p-2 rounded-lg min-w-[120px] relative overflow-hidden">
            <div className="absolute -right-2 -bottom-2 text-yellow-200/25 text-6xl">
              ☀️
            </div>
            <div className="relative z-10">
              <div className="font-medium text-xs text-gray-900">{t('day')} (12h)</div>
              <div className="text-xs py-0.5 text-gray-700">
                {formatTimeShort(dayStart)} - {formatTimeShort(dayEnd)}
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Statut de localisation */}
      {locationStatus && (
        <div className="text-xs text-yellow-300">
          {locationStatus} {position && `(${position.latitude.toFixed(4)}, ${position.longitude.toFixed(4)})`}
        </div>
      )}
      
      {languageSelector && (
        <div className="flex justify-end mt-2">
          {languageSelector}
        </div>
      )}
    </div>
  );
}
