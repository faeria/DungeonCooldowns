# Changelog

## 1.5.0

- Fusion des cooldowns défensifs et offensifs dans une grille unique.
- Ajout du réglage du nombre d’icônes par ligne, de 1 à 10.
- Ajout du réglage du nombre de lignes, de 1 à 5.
- La bordure bleue ou orange continue d’identifier la catégorie de chaque sort.
- Migration automatique de l’ancienne limite par catégorie vers la largeur de la grille.

## 1.4.5

- Suppression du balayage du temps de recharge global sur les icônes locales.
- Utilisation de `GetSpellCooldownDuration(spellID, true)` pour filtrer le GCD côté moteur sans lire de valeur protégée.
- Les véritables temps de recharge restent affichés normalement.

## 1.4.4

- Suppression du scan global `EnumerateFrames`, incompatible avec les booléens secrets de Retail 12.1.
- Intégration directe des party frames EllesmereUI via leur table unité-bouton.
- Aucune lecture de visibilité ou d’attribut sécurisé n’est effectuée sur les cadres EllesmereUI.
- Le diagnostic `/dcd status` utilise désormais la même détection sûre que l’affichage.

## 1.4.3

- Ajout d’une découverte générique des boutons d’unité visibles via `EnumerateFrames`.
- Filtrage des cadres par token `player`, `party1…4` ou `raid1…5`, dimensions et nom de famille.
- Exclusion des cadres joueur, cible, focus, boss, nameplates et des cadres internes de l’addon.
- Le scan de secours est limité à une exécution toutes les cinq secondes.

## 1.4.2

- Le mode étendu fonctionne désormais en solo avec les raid frames forcées par le mode d’édition Blizzard.
- Résolution de l’unité d’une frame via `GetUnit`, `displayedUnit`, `unit` puis `unitToken`.
- `/dcd status` affiche maintenant le nombre de cooldowns locaux et de frames visibles détectées.

## 1.4.1

- Correction du fallback local appelé avant la déclaration de la table `known` dans `BuildLocalKnownSpells`.

## 1.4.0

- Persistance explicite de chaque choix de sort dans `spellEnabled`, avec compatibilité des configurations précédentes.
- Mise à jour immédiate des doublons d’un même sort entre spécialisations dans le sélecteur.
- Découverte continue des cadres créés tardivement par Blizzard.
- Prise en charge de `CompactPartyFrameMember1…5`, du pool de `CompactRaidFrameContainer` et du pool des party frames standards.
- Ajout d’une portée configurable : donjons à cinq uniquement ou tous les groupes de cinq.
- Repli sur la liste de spécialisation lorsque l’API du grimoire ne retourne aucun cooldown local.

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
