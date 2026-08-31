# Dungeon Cooldowns

[![Release automatique](https://github.com/faeria/DungeonCooldowns/actions/workflows/release.yml/badge.svg)](https://github.com/faeria/DungeonCooldowns/actions/workflows/release.yml)

Addon WoW Retail 12.1 affichant les principaux temps de recharge défensifs et offensifs à côté des cadres de groupe Blizzard ou EllesmereUI, uniquement dans les instances de type `party` de cinq joueurs maximum.

## Fonctionnalités

- Grille unique combinant les cooldowns défensifs et offensifs, distingués par une bordure bleue ou orange.
- Overlays indépendants ancrés aux `CompactPartyFrame`, sans modifier ni contaminer les cadres protégés de Blizzard.
- État exact du joueur local via `C_Spell.GetSpellCooldown` et `C_Spell.GetSpellCharges`.
- Filtrage du GCD : seules les véritables recharges des capacités sont dessinées sur les icônes locales.
- Détection automatique des talents et remplacements de sorts du joueur local.
- Synchronisation légère entre membres possédant l’addon lorsque WoW autorise les messages addon : liste des sorts connus et notification d’utilisation.
- Inspection de la spécialisation comme solution de secours pour déterminer les sorts potentiels.
- Interface de configuration autonome ouverte avec `/dcd`, organisée en pages Général, Apparence et Sorts suivis.
- Interface compacte : le sélecteur de sorts remplace temporairement la configuration au lieu de se superposer à elle.
- Portée configurable entre les donjons à cinq uniquement et le mode solo ou groupe de cinq joueurs.
- Personnalisation du côté, de l’alignement, des décalages, de la distance à la frame, de la taille, des espacements, de l’opacité, des bordures, du nombre d’icônes par ligne et du nombre de lignes.
- Sélection précise des cooldowns à afficher, organisée par classe et spécialisation, avec choix individuel et actions « tout sélectionner / tout masquer ».
- Aperçu réaliste directement sur les cadres Blizzard `CompactPartyFrame` / `CompactRaidFrame` ou sur les party frames EllesmereUI ; une raid frame de secours est utilisée uniquement lorsqu’aucun cadre compatible n’est disponible.
- Détection continue des cadres Blizzard créés après le chargement de l’addon, y compris les pools dynamiques de raid et de groupe.
- Aucun framework ni bibliothèque externe.

## Installation

1. Décompresser l’archive.
2. Copier le dossier `DungeonCooldowns` dans :

   `World of Warcraft/_retail_/Interface/AddOns/`

3. Relancer le jeu ou exécuter `/reload`.
4. Activer l’option Blizzard **Utiliser les cadres de raid pour le groupe**.

## Installation et mises à jour avec WowUp

1. Dans WowUp, choisir l’installation depuis une URL.
2. Utiliser l’adresse du dépôt : `https://github.com/faeria/DungeonCooldowns`.
3. WowUp récupère la dernière release GitHub et son archive `DungeonCooldowns-*.zip`.

Chaque push sur `main` déclenche automatiquement une release GitHub. Son tag reprend la version du fichier TOC et ajoute le numéro d’exécution de la pipeline, par exemple `v1.0.2.2`.

## Commandes

- `/dcd` : ouvrir l’interface autonome de configuration.
- `/dcd test` : activer ou désactiver l’aperçu sur les cadres de groupe visibles.
- `/dcd status` : afficher le contexte et le mode de suivi distant.
- `/dcd sync` : relancer et diagnostiquer la synchronisation avec les autres joueurs du groupe.
- `/dcd reset` : réinitialiser la configuration.
- `/dcd help` : afficher l’aide.

## Compatibilité des cadres

- Cadres de groupe Blizzard : détection native.
- EllesmereUI Raid Frames : intégration directe et sûre, sans scan global ni lecture de valeurs protégées.
- Les autres addons de cadres nécessitent une intégration dédiée pour rester compatibles avec les valeurs secrètes de Retail 12.1.

## Limite imposée par Retail 12.1

Retail 12.1 protège les temps de recharge, les incantations et certaines données du journal de combat des autres joueurs dans les contenus restreints, notamment les donjons et le mode défi. Un addon tiers ne peut pas contourner cette protection.

Pendant une clé Mythique+, WoW active également un verrouillage global de la messagerie addon. Sur les royaumes normaux, `C_ChatInfo.SendAddonMessage` renvoie alors `AddOnMessageLockdown` et les addons tiers ne peuvent pas diffuser les utilisations de cooldown en temps réel. Les royaumes de tournoi peuvent autoriser ces émissions ; l’API `C_Commentator.SendAddonMessage` utilisée par le diffuseur Blizzard reste réservée à ces contextes de tournoi et MDI.

En conséquence :

- le temps de recharge du joueur local est exact ;
- hors verrouillage, l’utilisation d’un sort par un autre joueur utilisant l’addon est synchronisée automatiquement, avec une durée estimée fondée sur la durée de base ;
- pendant une clé Mythique+, les sorts distants déjà découverts restent visibles mais leur état est marqué inconnu, sans faux indicateur « prêt » ;
- pour un joueur sans l’addon, la spécialisation peut être inspectée hors combat, mais ses utilisations ne peuvent pas être suivies via le journal de combat protégé ;
- les réductions de recharge liées aux talents, procs et resets ne peuvent pas être garanties à distance.

L’addon identifie ces valeurs comme **estimées** dans l’infobulle au lieu d’annoncer une précision techniquement impossible.

## Références Blizzard utilisées

- `Blizzard_UnitFrame/Shared/CompactPartyFrame.lua` pour les cadres de groupe.
- `Blizzard_UnitFrame/Shared/CompactUnitFrame.lua` pour les unités affichées.
- `Blizzard_CooldownBroadcaster/TrackedCooldowns.lua` pour la sélection Retail des sorts importants.
- `Blizzard_CooldownBroadcaster/Blizzard_CooldownBroadcaster.lua` pour les modèles de cooldown et de charges.
- `Blizzard_APIDocumentationGenerated` pour les signatures et restrictions des API 12.1.

Source de référence : <https://github.com/Gethe/wow-ui-source>, branche `live`, version `12.1.0.69497` lors de la création de la version 1.0.2.
