Scriptname BTOOTJ_CoreQuestScript extends Quest

; Saved with this quest's script instance. One accumulating pending batch per Hold.
; The first head sets its morning deadline; later heads join without postponing it.
; Hold indices: Whiterun, Haafingar, Eastmarch, Rift, Reach.
Int[] PendingHeads
Float[] PromotionDates
Int[] VisibleHeads

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
        EndIf
        holdIndex = holdIndex + 1
    EndWhile
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
