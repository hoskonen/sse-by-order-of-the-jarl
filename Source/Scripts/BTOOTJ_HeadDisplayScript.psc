Scriptname BTOOTJ_HeadDisplayScript extends ObjectReference

Event OnActivate(ObjectReference akActionRef)
    If akActionRef == Game.GetPlayer()
        Debug.Trace("[BTOOTJ] Bandit head activated")
    EndIf
EndEvent
