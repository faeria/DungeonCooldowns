# Changelog

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
