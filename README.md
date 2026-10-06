# By The Order Of The Jarl — prototype

The BQ01 Headhunter turn-in hook registers a bandit head only when HeadOwner
(alias 15) resolves to the player. Hold alias 4 determines the supported Hold.
Existing diagnostics and Headhunter's original SetStage call remain intact.

The core quest saves three five-entry arrays: Int[] PendingHeads,
Float[] PromotionDates, and Int[] VisibleHeads. Index order is Whiterun,
Haafingar, Eastmarch, Rift, Reach. The first pending head sets next-day 06:00;
later heads join that batch. One game-time callback targets the earliest batch.
Visible counts are state only; no world displays are implemented.

## Clean-save requirement

Start a new game for this prototype version. Experimental two-batch migration
has been removed, and promotionDays was replaced by PromotionDates. Do not
reuse saves containing earlier core-script state or suspended script stacks.
No CK properties or ESP changes are needed.

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
