# By The Order Of The Jarl — prototype

The BQ01 Headhunter turn-in hook registers a bandit head only when HeadOwner
(alias 15) resolves to the player. Hold alias 4 determines the supported Hold.
Existing diagnostics and Headhunter's original SetStage call remain intact.

The core quest saves three five-entry arrays: Int[] PendingHeads,
Float[] PromotionDates, and Int[] VisibleHeads. Index order is Whiterun,
Haafingar, Eastmarch, Rift, Reach. The first pending head sets next-day 06:00;
later heads join that batch. One game-time callback targets the earliest batch.
Whiterun promotion constructs all three installed pikes together on the first
visible head and hides the material pikes/crate. Heads fill up to three slots.
Visible counts above three are retained. At zero, installed pikes and heads are
disabled and the material pikes/crate are enabled. Banners remain untouched.

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
| WhiterunPike01Material | BTOOTJ_Whiterun_Pike01_Material |
| WhiterunPike02Material | BTOOTJ_Whiterun_Pike02_Material |
| WhiterunPike03Material | BTOOTJ_Whiterun_Pike03_Material |
| WhiterunMaterialCrate | CommonCrate02 placed REFR, ByTheOrderOfTheJarl.esp local ID 00000D6F |

Select the placed REFRs, not the base objects. Keep Initially Disabled checked
for installed pikes and heads, and unchecked for material pikes and the crate.
The crate has no reference Editor ID; its base is CommonCrate02 (Skyrim.esm
000DAE82), and its position is approximately X=15154.29, Y=-7329.56, Z=-4354.24
in WhiterunExterior13. The runtime load-order prefix is not part of its local ID.
The four material references are currently non-persistent. CK assignment of
placed-reference properties normally makes the refs persistent. After saving,
verify Persistent on all ten; if CK did not set it,
set it explicitly for reliable quest access while the exterior cell is unloaded.
No persistence flags or ESP records were changed by this implementation.
See https://wiki.beyondskyrim.org/wiki/Arcane_University:Scripting_Best_Practices
for the property/persistence behavior.

RefreshWhiterunDisplay() separately calls ReconcileWhiterunConstruction() and
ReconcileWhiterunHeads(). Built state is currently inferred from VisibleHeads[0]
being positive, with no additional persistent lifecycle state. All three pikes
share the built state; each head uses its own visible-count threshold.
EnableNoWait/DisableNoWait avoid waiting for exterior 3D. If any of the ten
required properties is empty, the entire refresh is skipped with a specific
trace before any scene reference is changed. Banners are not controlled.

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
6. Before the first promotion, expect visible 0 and all installed pikes/heads
   disabled on a fresh game, with material pikes/crate enabled. After the first
   Whiterun promotion all three installed pikes are enabled and all materials
   disabled. Further promotions add heads only. A fourth head must log visible
   4 and head slots enabled 3.
7. Let a promotion occur inside an interior or away from Whiterun, then return
   normally to WhiterunExterior13. Verify the correct pairs appear, and save/load
   preserves the construction/head state. Banners should remain unchanged.

## Development console display test

DebugSetWhiterunVisibleHeads(Int aiCount) remains the implementation function.
Temporary quest-stage fragments provide the vanilla-console entry point; direct
quest-function console calls are not supported by this testing procedure.
The debug function replaces the saved Whiterun visible count. It does
not alter pending heads, promotion dates, or game-time scheduling, and normal
gameplay does not call it. Negative input becomes zero; counts above three
remain logical counts while the existing refresh shows at most three slots.

### CK stage setup required

These stages are a plan until added in CK; the ESP has not been edited here.
Load ByTheOrderOfTheJarl.esp as the active file, open BTOOTJ_CoreQuest, then its
Quest Stages tab. Add stages 901, 902, 903, and 904. Create one stage log entry
per stage and enter the corresponding Papyrus fragment below. Keep log text
empty and Complete Quest / Fail Quest flags unchecked. Do not add objectives,
conditions, aliases, or startup calls for these development stages.

| Stage | Papyrus fragment |
| --- | --- |
| 901 | `(Self as BTOOTJ_CoreQuestScript).DebugSetWhiterunVisibleHeads(1)` |
| 902 | `(Self as BTOOTJ_CoreQuestScript).DebugSetWhiterunVisibleHeads(2)` |
| 903 | `(Self as BTOOTJ_CoreQuestScript).DebugSetWhiterunVisibleHeads(3)` |
| 904 | `(Self as BTOOTJ_CoreQuestScript).DebugSetWhiterunVisibleHeads(4)` |

Self is the quest fragment's owning Quest, so casting it accesses the existing
BTOOTJ_CoreQuestScript attachment without another property or a FormID lookup.
Compile the fragments through CK, let CK create/bind the generated quest
fragment script, save the ESP, and retain its generated PEX in this mod. Verify
the original core script attachment and all ten display properties remain filled.

Use a fresh development game after saving the CK changes. Test the initial
zero-head scene before running any stages, then enter these commands in order:

```text
setstage BTOOTJ_CoreQuest 901
setstage BTOOTJ_CoreQuest 902
setstage BTOOTJ_CoreQuest 903
setstage BTOOTJ_CoreQuest 904
```

Expect all three installed pikes enabled and all material props disabled at each
stage. Enabled heads are 1/2/3/3 respectively, with logical count 4 at stage 904.
Reload the pre-test save when repeating the stage sequence; do not reset or
restart the core quest to rerun this display test. These stage fragments only
invoke the existing debug function and are never called by normal gameplay.
The refresh logs built state and head-slot requests when all ten properties are wired, or a
skip when wiring is incomplete. The development trace also reports the logical
count and slot target; it is not proof that unloaded 3D has appeared yet.

## Hook investigation after compaction (2026-10-07)

The inspected Papyrus.0.log contains only the core initialization trace, with
no hook entry or BTOOTJ binding failure. Source and compiled hook signatures,
diagnostics, BQ01 guard, and player HeadOwner check were intact. In the inspected
Ancestries profile, Headhunter remains the winning provider of reward INFO
Skyrim.esm:00095124, with HelloJarl_TargetIsDead.Fragment_0 still attached. The
latest BQ01 override is BountiesRedone_MissivesExtension.esp; its presence alone
does not establish why a dialogue fragment did not execute.

The compacted BTOOTJ ESP is ESL flagged and has Skyrim.esm and Headhunter as
masters. The core quest still has local ID 00000801, so its existing plugin-local
GetFormFromFile lookup remains correct. No core lookup can explain absence of
the earlier hook traces. The only loose target PEX found in the mod folders is
this mod's copy; Ancestries enables it with loose-file archive invalidation.
No MO2 priority change is indicated by that inspection. Confirm its origin in
MO2's Data tab for the actual launch profile if the new entry marker is absent.

The rebuilt fragment now logs its dated entry marker as its first executable
instruction, before the actor cast or any quest lookup. It separately logs the
resolved core form and script immediately before registration. The evidence
does not establish the exact cause of the missed runtime dialogue hook; retry
a normal BQ01 dead-target hand-in on a fresh game with the rebuilt override.
Entry absent: verify the launched profile, VFS file winner, and actual reward
INFO used. Entry present but registration absent: inspect ownership, Hold, and
core-resolution traces. Do not diagnose ESL conversion from silence alone.
