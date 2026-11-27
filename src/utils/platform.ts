/**
 * Utilitaire pour détecter la plateforme d'exécution (web ou Android)
 */

interface Platform {
  isWeb: boolean;
  isAndroid: boolean;
  isMobile: boolean;
}

/**
 * Détecte si l'application s'exécute sur un appareil mobile
 * @returns {boolean} true si l'appareil est mobile
 */
function isMobileDevice(): boolean {
  if (typeof navigator === 'undefined') return false;
  
  // Définition des types pour la compatibilité avec window.opera
  interface WindowWithOpera extends Window {
    opera?: unknown;
  }
  
  const userAgent = navigator.userAgent || navigator.vendor || ((window as WindowWithOpera).opera as string || '');
  
  // Vérification mobile
  const mobileRegex = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i;
  return mobileRegex.test(userAgent.toLowerCase());
}

/**
 * Détecte si l'application s'exécute sur un appareil Android
 * En contexte capacitor, window.Capacitor sera défini
 * @returns {boolean} true si l'appareil est Android
 */
function isAndroidDevice(): boolean {
  if (typeof window === 'undefined') return false;
  
  // Définition des types pour la compatibilité avec window.Capacitor
  interface WindowWithCapacitor extends Window {
    Capacitor?: unknown;
  }

  // Vérifier si Capacitor est disponible (contexte Android)
  const hasCapacitor = !!((window as WindowWithCapacitor).Capacitor);
  
  // Vérifier si c'est un appareil Android via user agent
  const userAgent = navigator.userAgent || '';
  const isAndroidUA = /android/i.test(userAgent);
  
  return hasCapacitor || isAndroidUA;
}

/**
 * Retourne des informations sur la plateforme d'exécution actuelle
 */
export function getPlatform(): Platform {
  const isAndroid = isAndroidDevice();
  const isMobile = isMobileDevice();
  const isWeb = !isAndroid;
  
  return {
    isWeb,
    isAndroid,
    isMobile
  };
}

/**
 * Ajuste un chemin de ressource selon la plateforme
 * @param path Chemin de la ressource
 * @returns Chemin ajusté pour la plateforme
 */
export function getAssetPath(path: string): string {
  const { isAndroid } = getPlatform();
  
  // Pour Android, on retire le point au début du chemin si présent
  if (isAndroid && path.startsWith('./')) {
    return path.substring(2);
  }
  
  // Pour le web, on s'assure qu'il y a un ./ au début 
  if (!isAndroid && !path.startsWith('./') && !path.startsWith('/')) {
    return `./${path}`;
  }
  
  return path;
}
