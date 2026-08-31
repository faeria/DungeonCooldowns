# Notes d’implémentation

Référence analysée : `Gethe/wow-ui-source`, branche `live`, commit `027d26c3406d3de2cbd2b1f67d468fe033a1bcd4`, client `12.1.0.69497`.

## Cadres Blizzard

`Blizzard_UnitFrame/Shared/CompactPartyFrame.lua` crée `CompactPartyFrame` et expose ses cinq cadres dans `memberUnitFrames`. Chaque cadre reçoit son unité avec `CompactUnitFrame_SetUnit`. Dungeon Cooldowns crée un conteneur visuel indépendant sous `UIParent`, l’ancre au cadre correspondant uniquement hors combat, puis lit `displayedUnit` avec repli sur `unit`.

L’addon ne génère jamais les cadres de groupe, ne leur ajoute aucun enfant, ne modifie aucun attribut sécurisé et reporte les créations ou repositionnements demandés pendant `InCombatLockdown()` jusqu’à `PLAYER_REGEN_ENABLED`.

## Interface de configuration

La configuration utilise exclusivement des cadres indépendants sous `UIParent`. Elle ne s’enregistre plus dans l’API `Settings` de Blizzard et n’interagit pas avec les cadres sécurisés. La fenêtre autonome est ouverte avec `/dcd` et ses réglages sont conservés dans `DungeonCooldownsDB`.

## Temps de recharge local

Le modèle reprend les API utilisées par les composants Blizzard :

- `C_Spell.GetSpellCooldown` ;
- `C_Spell.GetSpellCharges` ;
- `Cooldown:SetCooldown`.

Lorsque les restrictions de valeurs protégées sont disponibles, les valeurs sont transmises directement au widget natif `Cooldown` sans comparaison, conversion ni sérialisation.

## Données distantes

La documentation 12.1 déclare :

- `C_Spell.GetSpellCooldown` comme `SecretWhenCooldownsRestricted` ;
- `UNIT_SPELLCAST_SUCCEEDED` comme `SecretWhenUnitSpellCastRestricted` pour une unité autre que le joueur ou son familier ;
- le journal de combat comme système restreignable via `C_CombatLog.IsCombatLogRestricted()` ;
- les messages addon comme refusant les arguments secrets.

Le diffuseur Blizzard utilise `C_Commentator.SendAddonMessage`, API réservée aux royaumes de tournoi et aux commentateurs. Dungeon Cooldowns n’essaie pas de l’appeler. Hors verrouillage, il transmet uniquement des données non protégées concernant le joueur local avec `C_ChatInfo.SendAddonMessage` : sorts connus et identifiant d’un sort que le joueur vient lui-même d’utiliser.

En rencontre, mode défi, match JcJ ou carte à communication restreinte, `C_ChatInfo.InChatMessagingLockdown()` indique que les restrictions sont actives. Sur les royaumes normaux, `C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()` confirme que les addons tiers ne peuvent pas émettre et `C_ChatInfo.SendAddonMessage()` renvoie `Enum.SendAddonMessageResult.AddOnMessageLockdown`. La nature non secrète du payload ne contourne pas ce verrouillage global du transport. Dungeon Cooldowns conserve alors les sorts distants découverts auparavant, mais marque leur état comme inconnu et reprend la synchronisation lorsque les émissions redeviennent autorisées.

`COMBAT_LOG_EVENT_UNFILTERED` est déclaré avec `HasRestrictions = true` dans `CombatLogDocumentation.lua`. Son inscription avec `Frame:RegisterEvent` est interdite aux addons tiers en Retail 12.1 ; Dungeon Cooldowns ne tente donc jamais de l’enregistrer. Les utilisations distantes sont suivies uniquement lorsque l’autre joueur utilise aussi l’addon.

## Base de sorts

La sélection initiale vient de `Blizzard_CooldownBroadcaster/TrackedCooldowns.lua`. Les contrôles et interruptions ont été retirés, puis quelques défensifs personnels majeurs ont été ajoutés pour l’usage en donjon. Les durées statiques ne servent qu’aux estimations distantes.
