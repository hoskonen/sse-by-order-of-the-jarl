# By The Order Of The Jarl — prototype

The BQ01 Headhunter turn-in hook registers a bandit head only when HeadOwner
(alias 15) resolves to the player. Hold alias 4 determines the supported Hold.
Existing diagnostics and Headhunter's original SetStage call remain intact.

The core quest saves three five-entry arrays: Int[] PendingHeads,
Float[] PromotionDates, and Int[] VisibleHeads. Index order is Whiterun,
Haafingar, Eastmarch, Rift, Reach. The first pending head sets next-day 06:00;
later heads join that batch. One game-time callback targets the earliest batch.
Whiterun promotion refreshes three placed pike/head pairs. Visible counts above
three are retained; only the three available scene slots are displayed.

## Clean-save requirement

Start a new game for this prototype version. Experimental two-batch migration
has been removed, and promotionDays was replaced by PromotionDates. Do not
reuse saves containing earlier core-script state or suspended script stacks.
The state arrays require no CK properties. Whiterun display properties must be
filled and saved in the ESP before a new-game display test.

## Whiterun display wiring

On BTOOTJ_CoreQuest, open BTOOTJ_CoreQuestScript properties and assign these
ObjectReference properties to the placed references in WhiterunExterior13:

| Property | Placed reference |
| --- | --- |
| WhiterunPike01Installed | BTOOTJ_Whiterun_Pike01_Installed |
| WhiterunPike02Installed | BTOOTJ_Whiterun_Pike02_Installed |
| WhiterunPike03Installed | BTOOTJ_Whiterun_Pike03_Installed |
| WhiterunHead01 | BTOOTJ_Whiterun_Head01 |
| WhiterunHead02 | BTOOTJ_Whiterun_Head02 |
| WhiterunHead03 | BTOOTJ_Whiterun_Head03 |

Select the placed REFRs, not the base objects. Keep Initially Disabled checked.
Inspection before wiring found all six references non-persistent with no enable
parents. CK assignment of placed-reference properties normally makes the refs
persistent. After saving, verify Persistent on all six; if CK did not set it,
set it explicitly for reliable quest access while the exterior cell is unloaded.
No persistence flags or ESP records were changed by this implementation.
See https://wiki.beyondskyrim.org/wiki/Arcane_University:Scripting_Best_Practices
for the property/persistence behavior.

RefreshWhiterunDisplay() reconciles every slot, including disabling slots above
the visible count. EnableNoWait/DisableNoWait avoid waiting for exterior 3D.
If any property is empty the entire refresh is skipped with a trace. Banners
and construction-material references are not controlled.

## Initialization fix

The previous array == None checks compiled into None-to-array casts, with the
same temporary then reused by ARRAY_CREATE. Runtime logs showed those casts
and allocations failing despite correct array declarations in the PEX.
Initialization now uses Boolean checks, verifies allocation and exact lengths,
and aborts callers before array access on failure. Registration success is
logged only after incrementing and reading back the pending count.

## Runtime test

1. Confirm this mod supplies the winning core and Headhunter override PEX files.
2. Start a new game with Papyrus logging enabled.
3. Hand in a player-owned Whiterun BQ01 head: expect pending 1, visible 0,
   with no array errors. A second turn-in before the deadline gives pending 2
   with the same deadline.
4. Save and reload, then wait/sleep past the logged morning and leave the menu.
   Expect pending 0, visible 2, and no array errors.
5. Hand in another head; verify counts continue accumulating. Test another Hold
   for independent counters, and non-player HeadOwner for a logged skip while
   Headhunter completion continues normally.
6. Before the first promotion, run `cqf BTOOTJ_CoreQuest RefreshWhiterunDisplay`:
   expect visible 0 and all installed pikes/heads disabled. After each Whiterun
   promotion expect one, then two, then three pairs. A fourth head must log
   visible 4 and slots enabled 3. Repeat refresh to verify stable reconciliation.
7. Let a promotion occur inside an interior or away from Whiterun, then return
   normally to WhiterunExterior13. Verify the correct pairs appear, and save/load
   preserves them. Banners and material pikes should remain unchanged.
