/**
 * Utilitaires pour la gestion des ressources (images, sons, etc.)
 * Compatible avec les environnements web et Android
 */

import { getPlatform } from './platform';

/**
 * Retourne le chemin correct d'un fichier d'image selon la plateforme
 * @param imageName Nom du fichier image (sans le chemin)
 * @returns Chemin complet adapté à la plateforme
 */
export function getImagePath(imageName: string): string {
  const { isAndroid } = getPlatform();
  const basePath = isAndroid ? 'images/' : './images/';
  return `${basePath}${imageName}`;
}

/**
 * Retourne le chemin correct d'un fichier audio selon la plateforme
 * @param soundName Nom du fichier audio (sans le chemin)
 * @returns Chemin complet adapté à la plateforme
 */
export function getSoundPath(soundName: string): string {
  const { isAndroid } = getPlatform();
  const basePath = isAndroid ? 'sounds/' : './sounds/';
  return `${basePath}${soundName}`;
}

/**
 * Précharge une image pour éviter les scintillements lors de l'affichage
 * @param imagePath Chemin de l'image à précharger
 * @returns Une promesse résolue lorsque l'image est chargée ou rejetée en cas d'erreur
 */
export function preloadImage(imagePath: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.src = imagePath;
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error(`Failed to load image: ${imagePath}`));
  });
}

/**
 * Joue un son en tenant compte des contraintes de chaque plateforme
 * @param soundPath Chemin du fichier son
 * @param options Options de lecture (volume, etc.)
 * @returns Une promesse qui se résout lorsque le son commence à être lu
 */
export function playSound(
  soundPath: string,
  options: { volume?: number } = {}
): Promise<void> {
  const { isAndroid } = getPlatform();
  
  // Ne pas jouer de sons automatiquement sur mobile sans interaction utilisateur
  if (isAndroid) {
    console.log('Sons désactivés sur Android pour éviter les problèmes de permissions');
    return Promise.resolve();
  }
  
  return new Promise((resolve) => {
    try {
      const audio = new Audio(soundPath);
      if (options.volume !== undefined) {
        audio.volume = options.volume;
      }
      
      const playPromise = audio.play();
      if (playPromise !== undefined) {
        playPromise.then(() => resolve()).catch(error => {
          console.warn('Erreur lors de la lecture audio:', error);
          resolve(); // On résout quand même pour éviter de bloquer
        });
      } else {
        resolve();
      }
    } catch (error) {
      console.warn('Erreur lors de la création de l\'élément audio:', error);
      resolve(); // On résout quand même pour éviter de bloquer
    }
  });
}

/**
 * Crée une image de secours (fallback) en SVG
 * @param options Options de l'image de secours
 * @returns URL de données pour l'image de secours
 */
export function createFallbackImage(options: { 
  color?: string; 
  bgColor?: string; 
  size?: number 
} = {}): string {
  const { color = '#ffce03', bgColor = '#4F46E5', size = 24 } = options;
  
  const svg = `
    <svg width="${size}" height="${size}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="${bgColor}" opacity="0.1"/>
      <path fill="${color}" d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1 15h2v2h-2v-2zm0-13h2v10h-2V4zm1 4a2 2 0 110-4 2 2 0 010 4z"/>
    </svg>
  `;
  
  return `data:image/svg+xml;base64,${btoa(svg)}`;
}
