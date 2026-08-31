# Changelog

## 1.3.0

- Configuration entièrement externalisée des options Blizzard dans une fenêtre autonome ouverte avec `/dcd`.
- Nouvelle interface sombre organisée en pages Général, Apparence et Sorts suivis.
- Remplacement du test limité à vingt secondes par un aperçu activable et désactivable à volonté.
- Animation continue des cooldowns simulés pendant l’aperçu.
- Application immédiate de tous les réglages visuels sur les raid frames.

## 1.2.0

- Refonte visuelle complète du sélecteur de sorts et correction des textures de checkbox étirées.
- Détection des cadres `CompactPartyFrame` et `CompactRaidFrame1…5` pour un aperçu réellement collé aux raid frames visibles.
- Ajout de l’alignement haut/centre/bas, des décalages X/Y et de la distance à la frame.
- Ajout des espacements horizontal et vertical, de l’opacité, du style et de l’épaisseur de bordure.
- Nouveau cadre de secours reprenant visuellement une raid frame lorsque aucun cadre Blizzard n’est disponible.

## 1.1.0

- Ajout d’un sélecteur de cooldowns par classe et spécialisation.
- Possibilité d’afficher ou masquer chaque sort individuellement.
- Ajout des actions de sélection globale pour chaque classe.
- Aperçu réparti sur les party frames réellement visibles, avec plusieurs profils et états de recharge.
- Conservation d’un cadre d’aperçu autonome uniquement lorsqu’aucune party frame n’est disponible.

## 1.0.2

- Suppression de l’inscription interdite à `COMBAT_LOG_EVENT_UNFILTERED`, événement protégé en Retail 12.1.
- Le suivi des utilisations distantes repose désormais explicitement sur la synchronisation entre joueurs possédant l’addon.
- Correction du message d’état et de la documentation pour refléter cette restriction Blizzard.

## 1.0.1

- Suppression de l’appel à `CompactPartyFrame_Generate`, réservé au code sécurisé de Blizzard.
- Les overlays sont désormais enfants de `UIParent` et n’altèrent plus la hiérarchie protégée des cadres de groupe.
- Suppression du hook global sur `CompactUnitFrame_UpdateAll` pour réduire toute propagation de taint.
- Ajout d’une catégorie native **Options > AddOns > Dungeon Cooldowns** avec cases à cocher, liste de position, curseurs et boutons de diagnostic.

## 1.0.0

- Première version Retail 12.1.
- Suivi défensif et offensif pour toutes les classes et spécialisations, y compris Dévoreur.
- Intégration aux cadres de groupe Blizzard.
- Synchronisation des sorts connus et de leurs utilisations.
- Compatibilité explicite avec les restrictions de valeurs protégées de Retail 12.1.
- Options et mode test intégrés.
