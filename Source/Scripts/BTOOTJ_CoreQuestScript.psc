Scriptname BTOOTJ_CoreQuestScript extends Quest

; Saved with this quest's script instance. One accumulating pending batch per Hold.
; The first head sets its morning deadline; later heads join without postponing it.
; Hold indices: Whiterun, Haafingar, Eastmarch, Rift, Reach.
Int[] PendingHeads
Float[] PromotionDates
Int[] VisibleHeads

; Fill with placed Whiterun display references, not their base objects.
ObjectReference Property WhiterunPike01Installed Auto
ObjectReference Property WhiterunPike02Installed Auto
ObjectReference Property WhiterunPike03Installed Auto
ObjectReference Property WhiterunHead01 Auto
ObjectReference Property WhiterunHead02 Auto
ObjectReference Property WhiterunHead03 Auto
ObjectReference Property WhiterunPike01Material Auto
ObjectReference Property WhiterunPike02Material Auto
ObjectReference Property WhiterunPike03Material Auto
ObjectReference Property WhiterunMaterialCrate Auto
; Built-state scenery, controlled together with the installed pikes.
ObjectReference Property WhiterunNotice Auto
ObjectReference Property WhiterunNoticeDagger Auto
ObjectReference Property WhiterunToolsAfter Auto
ObjectReference Property WhiterunRag01 Auto
ObjectReference Property WhiterunRag02 Auto
ObjectReference Property WhiterunRag03 Auto
ObjectReference Property WhiterunToolsHammer Auto

Event OnInit()
    Debug.Trace("[BTOOTJ] Initialized!")
    EnsureHeadState()
EndEvent

Function RegisterBanditHead(Location akHoldLocation)
    int holdIndex = GetHoldIndex(akHoldLocation)
    If holdIndex < 0
        Debug.Trace("[BTOOTJ] Bandit head registration skipped: unsupported or missing Hold=" + akHoldLocation)
        Return
    EndIf

    ; Abort before array access if allocation or saved-state validation fails.
    If !EnsureHeadState()
        Return
    EndIf
    float currentDay = Utility.GetCurrentGameTime()
    PromoteDueHeads(currentDay)
    If PendingHeads[holdIndex] == 0
        PromotionDates[holdIndex] = Math.Floor(currentDay) + 1.25
    EndIf

    int expectedPendingCount = PendingHeads[holdIndex] + 1
    PendingHeads[holdIndex] = expectedPendingCount
    If PendingHeads[holdIndex] != expectedPendingCount
        Debug.Trace("[BTOOTJ] Bandit head registration failed: pending count was not incremented for " + GetHoldLabel(holdIndex))
        Return
    EndIf
    Debug.Trace("[BTOOTJ] Registered pending bandit head for " + GetHoldLabel(holdIndex))
    LogHeadCounts(holdIndex)
    Debug.Trace("[BTOOTJ] " + GetHoldLabel(holdIndex) + " pending batch eligible at game day=" + PromotionDates[holdIndex] + " (06:00)")
    ScheduleNextPromotion()
EndFunction

Event OnUpdateGameTime()
    If !EnsureHeadState()
        UnregisterForUpdateGameTime()
        Return
    EndIf
    PromoteDueHeads(Utility.GetCurrentGameTime())
    ScheduleNextPromotion()
EndEvent

Bool Function EnsureHeadState()
    ; Array == None emits unsafe None-to-array casts in the Skyrim compiler.
    ; Boolean checks avoid those casts. Existing valid state is never reset.
    If !PendingHeads
        PendingHeads = new Int[5]
    EndIf
    If !PromotionDates
        PromotionDates = new Float[5]
    EndIf
    If !VisibleHeads
        VisibleHeads = new Int[5]
    EndIf

    If !PendingHeads || !PromotionDates || !VisibleHeads
        Debug.Trace("[BTOOTJ] Head state initialization failed: an array is still missing; registration skipped")
        Return False
    EndIf
    If PendingHeads.Length != 5 || PromotionDates.Length != 5 || VisibleHeads.Length != 5
        Debug.Trace("[BTOOTJ] Head state initialization failed: expected five entries per array; use a clean prototype save")
        Return False
    EndIf
    Return True
EndFunction

int Function GetHoldIndex(Location akHoldLocation)
    If akHoldLocation == None
        Return -1
    EndIf
    ; Vanilla Hold locations verified in Skyrim.esm; no bounty-site mapping.
    If akHoldLocation == Game.GetFormFromFile(0x00016772, "Skyrim.esm") as Location
        Return 0
    ElseIf akHoldLocation == Game.GetFormFromFile(0x00016770, "Skyrim.esm") as Location
        Return 1
    ElseIf akHoldLocation == Game.GetFormFromFile(0x0001676A, "Skyrim.esm") as Location
        Return 2
    ElseIf akHoldLocation == Game.GetFormFromFile(0x0001676C, "Skyrim.esm") as Location
        Return 3
    ElseIf akHoldLocation == Game.GetFormFromFile(0x00016769, "Skyrim.esm") as Location
        Return 4
    EndIf
    Return -1
EndFunction

string Function GetHoldLabel(int aiHoldIndex)
    If aiHoldIndex == 0
        Return "Whiterun"
    ElseIf aiHoldIndex == 1
        Return "Haafingar (Solitude)"
    ElseIf aiHoldIndex == 2
        Return "Eastmarch (Windhelm)"
    ElseIf aiHoldIndex == 3
        Return "The Rift (Riften)"
    ElseIf aiHoldIndex == 4
        Return "The Reach (Markarth)"
    EndIf
    Return "Unknown Hold"
EndFunction

Function PromoteDueHeads(float afCurrentDay)
    int holdIndex = 0
    While holdIndex < VisibleHeads.Length
        If PendingHeads[holdIndex] > 0 && PromotionDates[holdIndex] <= afCurrentDay
            int promotedHeads = PendingHeads[holdIndex]
            VisibleHeads[holdIndex] = VisibleHeads[holdIndex] + promotedHeads
            PendingHeads[holdIndex] = 0
            PromotionDates[holdIndex] = 0.0
            Debug.Trace("[BTOOTJ] Promoted pending head(s) for " + GetHoldLabel(holdIndex) + ": " + promotedHeads)
            LogHeadCounts(holdIndex)
            If holdIndex == 0
                RefreshWhiterunDisplay()
            EndIf
        EndIf
        holdIndex = holdIndex + 1
    EndWhile
EndFunction

; Development console entry point only. Never called by normal bounty gameplay.
; Pending counts, deadlines, and the existing game-time registration are untouched.
Function DebugSetWhiterunVisibleHeads(Int aiCount)
    If !EnsureHeadState()
        Debug.Trace("[BTOOTJ] DEV Whiterun display test skipped: head state unavailable")
        Return
    EndIf
    If aiCount < 0
        aiCount = 0
    EndIf
    VisibleHeads[0] = aiCount
    RefreshWhiterunDisplay()
    int displayedSlotTarget = aiCount
    If displayedSlotTarget > 3
        displayedSlotTarget = 3
    EndIf
    Debug.Trace("[BTOOTJ] DEV Whiterun logical visible heads=" + VisibleHeads[0] + " displayed slot target=" + displayedSlotTarget)
EndFunction

Function RefreshWhiterunDisplay()
    If !EnsureHeadState()
        Return
    EndIf
    int visibleCount = VisibleHeads[0]
    Debug.Trace("[BTOOTJ] Refreshing Whiterun display: visible heads=" + visibleCount)
    ; Avoid a partially updated scene when CK reference wiring is incomplete.
    If !WhiterunDisplayReferencesReady()
        Return
    EndIf

    ; Inferred for now; construction reconciliation is separate from head slots
    ; so a future independent lifecycle can supply the built state here.
    Bool isBuilt = visibleCount > 0
    ReconcileWhiterunConstruction(isBuilt)
    ReconcileWhiterunHeads(visibleCount)
    Debug.Trace("[BTOOTJ] Whiterun construction state: built=" + isBuilt)
    ; Cap only the scene's slot count, never the persistent logical count.
    int enabledSlots = visibleCount
    If enabledSlots > 3
        enabledSlots = 3
    ElseIf enabledSlots < 0
        enabledSlots = 0
    EndIf
    Debug.Trace("[BTOOTJ] Whiterun head slots enabled=" + enabledSlots)
EndFunction

Bool Function WhiterunDisplayReferencesReady()
    If !WhiterunPike01Installed || !WhiterunPike02Installed || !WhiterunPike03Installed
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: installed pike properties are incomplete")
        Return False
    EndIf
    If !WhiterunHead01 || !WhiterunHead02 || !WhiterunHead03
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: head properties are incomplete")
        Return False
    EndIf
    If !WhiterunPike01Material || !WhiterunPike02Material || !WhiterunPike03Material
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: material pike properties are incomplete")
        Return False
    EndIf
    If !WhiterunMaterialCrate
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunMaterialCrate is unfilled")
        Return False
    EndIf
    Return WhiterunFinishedSceneReferencesReady()
EndFunction

Bool Function WhiterunFinishedSceneReferencesReady()
    If !WhiterunNotice
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunNotice is unfilled")
        Return False
    EndIf
    If !WhiterunNoticeDagger
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunNoticeDagger is unfilled")
        Return False
    EndIf
    If !WhiterunToolsAfter
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunToolsAfter is unfilled")
        Return False
    EndIf
    If !WhiterunRag01
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunRag01 is unfilled")
        Return False
    EndIf
    If !WhiterunRag02
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunRag02 is unfilled")
        Return False
    EndIf
    If !WhiterunRag03
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunRag03 is unfilled")
        Return False
    EndIf
    If !WhiterunToolsHammer
        Debug.Trace("[BTOOTJ] Whiterun display refresh skipped: WhiterunToolsHammer is unfilled")
        Return False
    EndIf
    Return True
EndFunction

Function ReconcileWhiterunConstruction(Bool abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike01Installed, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike02Installed, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike03Installed, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike01Material, !abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike02Material, !abBuilt)
    SetWhiterunReferenceEnabled(WhiterunPike03Material, !abBuilt)
    SetWhiterunReferenceEnabled(WhiterunMaterialCrate, !abBuilt)
    SetWhiterunReferenceEnabled(WhiterunNotice, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunNoticeDagger, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunToolsAfter, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunToolsHammer, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunRag01, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunRag02, abBuilt)
    SetWhiterunReferenceEnabled(WhiterunRag03, abBuilt)
EndFunction

Function ReconcileWhiterunHeads(Int aiVisibleCount)
    SetWhiterunReferenceEnabled(WhiterunHead01, aiVisibleCount >= 1)
    SetWhiterunReferenceEnabled(WhiterunHead02, aiVisibleCount >= 2)
    SetWhiterunReferenceEnabled(WhiterunHead03, aiVisibleCount >= 3)
EndFunction

Function SetWhiterunReferenceEnabled(ObjectReference akReference, Bool abEnabled)
    If !akReference
        Debug.Trace("[BTOOTJ] Whiterun reference update skipped: missing placed reference")
        Return
    EndIf
    ; NoWait changes enable state without waiting for exterior 3D to load.
    ; References must be persistent and filled through the core quest properties.
    If abEnabled
        If akReference.IsDisabled()
            akReference.EnableNoWait()
        EndIf
    Else
        If !akReference.IsDisabled()
            akReference.DisableNoWait()
        EndIf
    EndIf
EndFunction

Function LogHeadCounts(int aiHoldIndex)
    If !EnsureHeadState()
        Return
    EndIf
    Debug.Trace("[BTOOTJ] Pending " + GetHoldLabel(aiHoldIndex) + " heads = " + PendingHeads[aiHoldIndex])
    Debug.Trace("[BTOOTJ] Visible " + GetHoldLabel(aiHoldIndex) + " heads = " + VisibleHeads[aiHoldIndex])
EndFunction

Function ScheduleNextPromotion()
    ; One outstanding game-time update, only while a pending batch exists.
    UnregisterForUpdateGameTime()
    float nextDay = -1.0
    int batchIndex = 0
    While batchIndex < PendingHeads.Length
        If PendingHeads[batchIndex] > 0
            If nextDay < 0.0 || PromotionDates[batchIndex] < nextDay
                nextDay = PromotionDates[batchIndex]
            EndIf
        EndIf
        batchIndex = batchIndex + 1
    EndWhile
    If nextDay >= 0.0
        float hoursUntilPromotion = (nextDay - Utility.GetCurrentGameTime()) * 24.0
        ; A small positive interval also catches an overdue batch safely.
        If hoursUntilPromotion < 0.01
            hoursUntilPromotion = 0.01
        EndIf
        RegisterForSingleUpdateGameTime(hoursUntilPromotion)
        Debug.Trace("[BTOOTJ] Next head promotion scheduled for game day=" + nextDay)
    EndIf
EndFunction
