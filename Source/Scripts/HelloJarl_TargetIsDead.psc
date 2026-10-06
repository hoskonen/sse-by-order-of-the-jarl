;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname HelloJarl_TargetIsDead Extends TopicInfo Hidden
int Property stage = 200 Auto

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
;Debug.Notification("TargetIsDead")
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
Debug.Trace("[BTOOTJ] HelloJarl_TargetIsDead.Fragment_0 fired")
Debug.Trace("[BTOOTJ] akSpeakerRef=" + akSpeakerRef)
Debug.Trace("[BTOOTJ] GetOwningQuest()=" + GetOwningQuest())
Debug.Trace("[BTOOTJ] stage=" + stage)

; BQ01 is Skyrim.esm:00095125. Inspect aliases before SetStage can clear them.
Quest bountyQuest = GetOwningQuest()
Quest banditBountyQuest = Game.GetFormFromFile(0x00095125, "Skyrim.esm") as Quest
If bountyQuest && banditBountyQuest && bountyQuest == banditBountyQuest
    Debug.Trace("[BTOOTJ] BQ01 alias snapshot before SetStage")
    ; Alias IDs and types verified against the installed Headhunter BQ01 record.
    LogBountyLocationAlias(bountyQuest, 6, "BountyLocation")
    LogBountyReferenceAlias(bountyQuest, 8, "Jarl")
    LogBountyReferenceAlias(bountyQuest, 13, "Steward")
    LogBountyReferenceAlias(bountyQuest, 15, "HeadOwner")
    LogBountyLocationAlias(bountyQuest, 4, "Hold")
    LogBountyLocationAlias(bountyQuest, 0, "Location")

    ; The Hold alias is authoritative; BountyLocation remains diagnostic only.
    LocationAlias holdAlias = bountyQuest.GetAlias(4) as LocationAlias
    Location holdLocation = None
    If holdAlias
        holdLocation = holdAlias.GetLocation()
    EndIf
    ReferenceAlias headOwnerAlias = bountyQuest.GetAlias(15) as ReferenceAlias
    ObjectReference headOwner = None
    If headOwnerAlias
        headOwner = headOwnerAlias.GetReference()
    EndIf
    If headOwner && headOwner == Game.GetPlayer()
        If holdLocation
            BTOOTJ_CoreQuestScript coreQuest = Game.GetFormFromFile(0x00000801, "ByTheOrderOfTheJarl.esp") as BTOOTJ_CoreQuestScript
            If coreQuest
                coreQuest.RegisterBanditHead(holdLocation)
            Else
                Debug.Trace("[BTOOTJ] Bandit head registration skipped: BTOOTJ_CoreQuest script unavailable")
            EndIf
        Else
            Debug.Trace("[BTOOTJ] Bandit head registration skipped: BQ01 Hold alias is missing or unfilled")
        EndIf
    Else
        Debug.Trace("[BTOOTJ] Bandit head registration skipped: BQ01 HeadOwner is not the player; HeadOwner=" + headOwner)
    EndIf
EndIf

getowningquest().setstage(stage)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Function LogBountyLocationAlias(Quest akQuest, int aiAliasID, string asAliasName)
    Alias bountyAlias = akQuest.GetAlias(aiAliasID)
    LocationAlias bountyLocationAlias = bountyAlias as LocationAlias
    If bountyLocationAlias
        Debug.Trace("[BTOOTJ] BQ01 " + asAliasName + " aliasID=" + aiAliasID + " alias=" + bountyAlias + " location=" + bountyLocationAlias.GetLocation())
    Else
        Debug.Trace("[BTOOTJ] BQ01 " + asAliasName + " aliasID=" + aiAliasID + " alias=" + bountyAlias + " missing or not a LocationAlias")
    EndIf
EndFunction

Function LogBountyReferenceAlias(Quest akQuest, int aiAliasID, string asAliasName)
    Alias bountyAlias = akQuest.GetAlias(aiAliasID)
    ReferenceAlias bountyReferenceAlias = bountyAlias as ReferenceAlias
    If bountyReferenceAlias
        Debug.Trace("[BTOOTJ] BQ01 " + asAliasName + " aliasID=" + aiAliasID + " alias=" + bountyAlias + " reference=" + bountyReferenceAlias.GetReference())
    Else
        Debug.Trace("[BTOOTJ] BQ01 " + asAliasName + " aliasID=" + aiAliasID + " alias=" + bountyAlias + " missing or not a ReferenceAlias")
    EndIf
EndFunction
