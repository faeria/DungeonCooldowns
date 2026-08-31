# Mythic+ addon-message lockdown — TDD evidence

## Source and journeys

The implementation plan was approved in the conversation and was not stored as a repository file.

- As a Mythic+ player, I want remote cooldowns to be shown as unknown when WoW blocks addon messages, so that a missing update is never presented as a ready cooldown.
- As an addon user, I want `/dcd sync` to report the real Blizzard restriction, so that I can distinguish a platform lockdown from a channel or installation problem.
- As a player leaving restricted content, I want synchronization to recover automatically without `/reload`.
- As an addon maintainer, I want older clients without the new helper APIs to retain the previous best-effort sending behavior.

## RED evidence

Command:

```text
npx --yes --package=fengari-node-cli fengari tests/run.lua
```

Result before production changes: **2 passed, 4 failed**.

The intended failures proved that the transport was called during lockdown, enum result 11 was not classified, `/dcd sync` claimed a test was sent, and an untrackable remote cooldown was rendered ready.

## GREEN evidence

The same command after the Core/UI fix, acceptance-edge cases, and review regressions produced: **15 passed, 0 failed**.

| # | What is guaranteed | Test target | Type | Result |
|---|---|---|---|---|
| 1 | Successful PARTY messages still work outside lockdown | `successful addon messages still use PARTY outside lockdown` | integration | PASS |
| 2 | A confirmed chat lockdown prevents the transport call | `chat lockdown blocks transport before SendAddonMessage` | unit | PASS |
| 3 | Transport result `AddOnMessageLockdown` is classified as blocked | `enum 11 returned by the transport is classified as blocked` | unit | PASS |
| 4 | `/dcd sync` reports the restriction without claiming success | `sync diagnostic reports Blizzard lockdown instead of a sent test` | integration | PASS |
| 5 | A direct enum 11 race is also explained as a Blizzard block | `sync diagnostic explains enum 11 returned after a clear preflight` | integration | PASS |
| 6 | A later successful send restores the available state | `a successful send restores communication after lockdown` | unit | PASS |
| 7 | Only recent synchronized roster peers are considered live | `remote tracking requires a recent synchronized peer` | unit | PASS |
| 8 | Diagnostics exclude peers whose heartbeat is stale | `peer diagnostics exclude stale addon peers` | unit | PASS |
| 9 | Missing optional 12.x helpers do not break sending | `missing lockdown helper APIs preserve compatible sending` | unit | PASS |
| 10 | Blocked remote cooldowns render unknown, not ready | `remote cooldown is unknown rather than ready when live tracking is blocked` | UI unit | PASS |
| 11 | Available remote cooldowns retain the existing ready state | `remote cooldown can still be ready when live tracking is available` | UI unit | PASS |
| 12 | A visible remote icon becomes unknown when its peer expires | `remote icon transitions to unknown when its peer becomes stale` | UI integration | PASS |
| 13 | Recycled local icons clear the remote unknown marker | `local icon refresh clears a recycled remote unknown marker` | UI unit | PASS |
| 14 | Unknown remote spells remain visible when ready spells are hidden | `unknown remote spells remain visible when ready spells are hidden` | UI unit | PASS |
| 15 | Hidden overlays are revisited when a peer becomes unknown | `hidden overlays are periodically reconsidered for newly unknown peers` | UI integration | PASS |

## Coverage and known gaps

The repository has no instrumented WoW Lua coverage runner, so a numeric line-coverage percentage is unavailable. The regression harness executes the changed communication decisions and remote-icon rendering against the real `Core.lua` and `UI.lua` modules with targeted WoW API mocks. Final in-client validation still requires two grouped clients because WoW does not deliver PARTY addon messages back to their sender.

No checkpoint commits were created during RED/GREEN because the enclosing fix workflow requires explicit user approval at the pre-commit gate. The RED and GREEN outputs above preserve that evidence for a later squash or commit message.
