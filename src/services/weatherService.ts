interface Position {
  latitude: number;
  longitude: number;
}

export interface SunriseSunsetData {
  sunrise: string;
  sunset: string;
  date: Date;
}

export const getSunriseSunset = async (position: Position): Promise<SunriseSunsetData> => {
  try {
    const { latitude, longitude } = position;
    const today = new Date();
    const startDate = today.toISOString().split('T')[0];
    
    const response = await fetch(
      `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&daily=sunrise,sunset&timezone=auto&start_date=${startDate}&end_date=${startDate}`
    );
    
    if (!response.ok) {
      throw new Error('Erreur lors de la récupération des données météo');
    }
    
    const data = await response.json();
    
    return {
      sunrise: data.daily.sunrise[0],
      sunset: data.daily.sunset[0],
      date: today
    };
  } catch (error) {
    console.error('Erreur:', error);
    // Retourner des valeurs par défaut en cas d'erreur
    const defaultTime = new Date();
    defaultTime.setHours(6, 0, 0, 0);
    return {
      sunrise: defaultTime.toISOString(),
      sunset: defaultTime.toISOString(),
      date: new Date()
    };
  }
};
