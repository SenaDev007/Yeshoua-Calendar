/// ⭐ Horloge Céleste ENGINE — Le temps de l’alliance de l’Éternel.
///
/// Moteur pur Dart (aucune dépendance Flutter, aucun réseau) :
///   • [SolarEngine]      — lever / coucher du soleil (algorithme NOAA),
///     calcul 100 % local, gestion des régions polaires ;
///   • [TimeEngine]       — heure réelle, fuseau, détection des ruptures
///     temporelles (changement d'heure système, redémarrage, reprise) ;
///   • [BiblicalCalendarEngine] — calendrier biblique de 364 jours,
///     règles EXACTES du backend « Mouvement Christ Libère »
///     (année commencant le mercredi le plus proche de l'équinoxe de mars,
///     12 mois de 30/31 jours, Shabbat hebdomadaire, 10 fêtes de l'Éternel) ;
///   • [BiblicalTimeEngine] — trois veilles de la nuit (tiers réels de la
///     nuit), douze heures saisonnières du jour, quatre parties du jour,
///     détermination de la période en cours ;
///   • [BiblicalCalendarAdapter] — changement de date biblique au coucher
///     du soleil réel (jamais à minuit, jamais à 18 h 00 fixes), avec
///     protection contre les doubles transitions.
library;

export 'src/models.dart';
export 'src/solar_engine.dart';
export 'src/time_engine.dart';
export 'src/biblical_calendar_engine.dart';
export 'src/biblical_calendar_adapter.dart';
export 'src/biblical_time_engine.dart';
export 'src/alarm_planner.dart';
