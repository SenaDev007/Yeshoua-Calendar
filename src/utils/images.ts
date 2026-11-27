/**
 * Utilitaires pour la gestion des ressources images
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
 * Charge un ensemble d'images en parallèle
 * @param imageNames Tableau des noms d'images à charger
 * @returns Une promesse qui se résout lorsque toutes les images sont chargées
 */
export function preloadImages(imageNames: string[]): Promise<HTMLImageElement[]> {
  const promises = imageNames.map(name => preloadImage(getImagePath(name)));
  return Promise.all(promises);
}

/**
 * Crée une image de secours (fallback) en SVG
 * Utile en cas d'échec de chargement d'une image
 * @param options Options de l'image de secours (couleur, taille...)
 * @returns Une chaîne URL de données en base64 de l'image SVG
 */
export function createFallbackImage(options: { 
  color?: string;
  bgColor?: string;
  size?: number;
} = {}): string {
  const {
    color = '#ffce03',
    bgColor = '#4F46E5',
    size = 24
  } = options;
  
  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24">
    <circle cx="12" cy="12" r="10" fill="${bgColor}" opacity="0.1"/>
    <path fill="${color}" d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1 15h2v2h-2v-2zm0-13h2v10h-2V4zm1 4a2 2 0 110-4 2 2 0 010 4z"/>
  </svg>`;
  
  return `data:image/svg+xml;base64,${btoa(svgContent)}`;
}
