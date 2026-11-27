/**
 * Utilitaires pour la gestion des ressources audio
 * Compatible avec les environnements web et Android
 */

import { getPlatform } from './platform';

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
 * Joue un son en tenant compte des contraintes de chaque plateforme
 * @param soundName Nom du fichier son (sans le chemin)
 * @param options Options de lecture (volume, etc.)
 * @returns Une promesse qui se résout lorsque le son commence à être lu
 */
export function playSound(
  soundName: string,
  options: { volume?: number } = {}
): Promise<void> {
  const { isAndroid } = getPlatform();
  const soundPath = getSoundPath(soundName);
  
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
