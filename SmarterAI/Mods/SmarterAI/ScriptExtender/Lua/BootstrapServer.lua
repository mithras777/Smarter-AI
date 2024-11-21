-- Function to get MCM setting values
function MCMGet(settingID)
    return Mods.BG3MCM.MCMAPI:GetSettingValue(settingID, ModuleUUID)
end

local function OnSessionLoaded()
    print("Smarter AI - MCM Version")
    Vars = {
        StartWithDash = MCMGet("StartWithDash"),
        DisengageIsFree = MCMGet("DisengageIsFree"),
        OneDash = MCMGet("OneDash"),
        ProficiencyBonus = MCMGet("ProficiencyBonus"),
        DisableJump = MCMGet("DisableJump"),
        DisableDash = MCMGet("DisableDash"),
        Advantageous = MCMGet("Advantageous"),
        Debug = MCMGet("Debug")
    }
    Current_combat = ""
    CombatNPCs = {}
end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)

local function GetCharacterId(rawId)
    return rawId:match(".*_(.*)") or rawId
end

---@param entity table
---@param spellName string
local function RemoveSpellFromSpellBook(entity, spellName)
    if entity.SpellBook then
        local spellExists = false
        for i, spell in pairs(entity.SpellBook.Spells) do
            if spell.Id.OriginatorPrototype == spellName then
                entity.SpellBook.Spells[i] = nil
                spellExists = true
                break
            end
        end

        if spellExists then
            entity:Replicate('SpellBook')
        end
    end
end


Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function (character, combatid)
    local cleanCharacterId = GetCharacterId(character)
    local entity = Ext.Entity.Get(cleanCharacterId)
    Current_combat = combatid

    if IsCharacter(cleanCharacterId) == 1 then
        table.insert(CombatNPCs, cleanCharacterId)
        if Vars["Debug"] then print(Ext.Loca.GetTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle) .. " added to CombatNPCs table") end
    end

    if entity and entity.ServerCharacter and entity.ServerCharacter.Template then
        local entityid = string.format("%s_%s", entity.ServerCharacter.Template.Name, cleanCharacterId)
        if IsCharacter(cleanCharacterId) == 1 and IsEnemy(cleanCharacterId, GetHostCharacter()) == 1 then

            if Vars["DisableJump"] == true then
                RemoveSpellFromSpellBook(entity, "Projectile_Jump")
            end

            if Vars["StartWithDash"] == true then
                ApplyStatus(character, "DASH_FREE", -1)
            end

            if Vars["OneDash"] == true then
                ApplyStatus(character, "DASH_FREE", 6, -1)
            end

            if Vars["DisengageIsFree"] == true then
                ApplyStatus(character, "DISENGAGE_FREE", -1)
            end

            if Vars["FreeJump"] == true then
                ApplyStatus(character,"STEP_OF_THE_WIND_FREE",-1)
            end

            if Vars["Advantageous"] == true then
                ApplyStatus(character,"ADVANTAGEOUS",-1)
            end

            if Vars["ProficiencyBonus"] == true then
                AddBoosts(cleanCharacterId,"Proficiency(LightArmor)","","")
                AddBoosts(cleanCharacterId,"Proficiency(MediumArmor)","","")
                AddBoosts(cleanCharacterId,"Proficiency(HeavyArmor)","","")
                AddBoosts(cleanCharacterId,"Proficiency(Shields)","","")
                AddBoosts(cleanCharacterId,"Proficiency(MartialWeapons)","","")
                AddBoosts(cleanCharacterId,"Proficiency(SimpleWeapons)","","")
            end

            if Vars["DisableDash"] == true then
                RemoveSpellFromSpellBook(entity, "Shout_Dash")
            end

            if Vars["Debug"] == true then
                print("The character: " .. entity.ServerCharacter.Template.Name .. " has the following AI Archetype: " .. GetActiveArchetype(cleanCharacterId))
            end
        end
    end
end)

Ext.Osiris.RegisterListener("Dying", 1, "after", function(entity)
    -- Remove character from CombatNPCs table when they die
    for i, npc in ipairs(CombatNPCs) do
        if npc == entity then
            table.remove(CombatNPCs, i)
            if Vars["Debug"] then print(Ext.Loca.GetTranslatedString(Ext.Entity.Get(entity).DisplayName.NameKey.Handle.Handle) .. " removed from CombatNPCs table") end
            break
        end
    end

end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(combatId)
    -- Clear the CombatNPCs table
    CombatNPCs = {}

    -- Optionally, reset other variables or states as needed
    Current_combat = nil
end)

               
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
    if Vars["Debug"] == true and Ext.Entity.Get(caster).ServerCharacter and Ext.Entity.Get(target).ServerCharacter then
        print("The character: " .. Ext.Entity.Get(caster).ServerCharacter.Template.Name .. " is using the following spell: " .. spell .. " with the following target:" .. Ext.Entity.Get(target).ServerCharacter.Template.Name)
    end
end)


Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end
    
    if Vars[payload.settingId] ~= nil then
        Vars[payload.settingId] = payload.value
    end
end)