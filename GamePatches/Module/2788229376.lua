--[[
    Information:

    - Da Hood (https://www.roblox.com/games/2788229376/)
]]

-- // Dependencies
local Aiming = loadstring(game:HttpGet("https://pastefy.ga/7kPjf9iM/raw"))()

-- // Disable Team Check
local AimingIgnored = Aiming.Ignored
AimingIgnored.TeamCheck(false)

local AimingSettings = Aiming.Settings
AimingSettings.Ignored.IgnoreLocalTeam = false

-- // Downed Check
local AimingChecks = Aiming.Checks
local AimingUtilities = Aiming.Utilities
function AimingChecks.Custom(Player)
    -- // Check if downed
    local Character = AimingUtilities.Character(Player)
    local KOd = Character:WaitForChild("BodyEffects"):FindFirstChild("K.O")
    local Grabbed = Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil

    -- // Check B
    if ((KOd and KOd.Value) or Grabbed) then
        return false
    end

    -- //
    return true
end

-- // Return
return Aiming