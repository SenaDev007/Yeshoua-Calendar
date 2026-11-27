import { motion } from 'framer-motion';
import { useEffect, useState, useRef } from 'react';
import { getPlatform, getImagePath, getSoundPath, createFallbackImage } from '../utils';

interface LogoProps {
  className?: string;
  animateOnHover?: boolean;
}

export function Logo({ className = '', animateOnHover = true }: LogoProps) {
  const [isHovered, setIsHovered] = useState(false);
  const [isLoaded, setIsLoaded] = useState(false);
  const [useFallback, setUseFallback] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Animation variants pour le conteneur
  const containerVariants = {
    initial: { scale: 1 },
    hover: { 
      scale: 1.05,
      transition: { 
        type: 'spring', 
        stiffness: 400, 
        damping: 10 
      } 
    }
  };

  // Animation pour l'effet de lueur
  const glowVariants = {
    initial: { 
      opacity: 0.6,
      scale: 1,
    },
    hover: {
      opacity: [0.6, 0.9, 0.6],
      scale: [1, 1.1, 1],
      transition: {
        duration: 2,
        repeat: Infinity,
        ease: 'easeInOut',
      }
    },
    pulse: {
      opacity: [0.6, 0.9, 0.6],
      scale: [1, 1.05, 1],
      transition: {
        duration: 3,
        repeat: Infinity,
        ease: 'easeInOut',
      }
    }
  };

  // Effet de pulsation douce au chargement
  useEffect(() => {
    if (!isLoaded) {
      const timer = setTimeout(() => {
        setIsLoaded(true);
        // Jouer la sonnerie d'horloge seulement sur le web et avec interaction utilisateur
        if (audioRef.current && !getPlatform().isAndroid && document.hasFocus()) {
          const playPromise = audioRef.current.play();
          
          if (playPromise !== undefined) {
            playPromise.catch(error => {
              console.log('Erreur lors de la lecture de la sonnerie:', error);
            });
          }
        }
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [isLoaded]);

  // Gestionnaire d'erreur pour le chargement de l'image
  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    const target = e.target as HTMLImageElement;
    if (!useFallback) {
      target.onerror = null;
      setUseFallback(true);
      target.src = createFallbackImage({ color: '#ffce03', bgColor: '#4F46E5', size: 24 });
    }
  };

  // SVG de secours stylisé
  const FallbackLogo = () => (
    <motion.svg
      className="w-full h-full"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      initial="initial"
      animate={isHovered && animateOnHover ? 'hover' : 'initial'}
      variants={containerVariants}
    >
      <motion.circle 
        cx="12" 
        cy="12" 
        r="10" 
        fill="#4F46E5"
        initial={{ opacity: 0.1 }}
        animate={{ 
          opacity: isHovered ? 0.2 : 0.1,
          transition: { duration: 0.3 }
        }}
      />
      <motion.path 
        d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm-1 15h2v2h-2v-2zm0-13h2v10h-2V4zm1 4a2 2 0 110-4 2 2 0 010 4z"
        fill="#8B5CF6"
        initial={{ pathLength: 0, opacity: 0 }}
        animate={{ 
          pathLength: 1, 
          opacity: 1,
          transition: { 
            duration: 1,
            ease: 'easeInOut'
          }
        }}
      />
    </motion.svg>
  );

  return (
    <>
      {/* Audio conditionnel basé sur la plateforme */}
  <audio ref={audioRef} src={getSoundPath('clock-chime.mp3')} preload="auto" />
    <motion.div 
      className={`relative ${className}`}
      onMouseEnter={() => animateOnHover && setIsHovered(true)}
      onMouseLeave={() => animateOnHover && setIsHovered(false)}
      initial="initial"
      animate={isHovered && animateOnHover ? 'hover' : isLoaded ? 'pulse' : 'initial'}
      variants={containerVariants}
    >
      {/* Effet de lueur */}
      {!useFallback && (
        <motion.div 
          className="absolute inset-0 bg-amber-300/20 rounded-full blur-md"
          variants={glowVariants}
          initial="initial"
          animate={isHovered && animateOnHover ? 'hover' : isLoaded ? 'pulse' : 'initial'}
        />
      )}
      
      {/* Logo principal */}
      {useFallback ? (
        <FallbackLogo />
      ) : (
        <motion.img 
          src={getImagePath('logo-calendrier-yhwh.png')} 
          alt="Logo Calendrier de YHWH Elohim"
          className="w-full h-full object-contain relative z-10"
          onError={handleImageError}
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ 
            opacity: 1, 
            scale: 1,
            transition: { 
              duration: 0.5,
              ease: 'easeOut'
            }
          }}
          whileHover={animateOnHover ? {
            rotate: [0, -5, 5, -5, 0],
            transition: { 
              duration: 0.8,
              repeat: 1
            }
          } : {}}
        />
      )}
    </motion.div>
    </>
  );
}
