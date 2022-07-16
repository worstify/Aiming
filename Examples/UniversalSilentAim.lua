--[[
    Information:

    - Inspired by https://github.com/Averiias/Universal-SilentAim/blob/main/main.lua

    You can combine methods. Simply seperate them with a comma. For example: "Target,UnitRay"
    -> Make sure you use the supported methods exactly (Capitalisation matters!)
]]

-- // Dependencies
local _, AimingPage, _ = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Aiming/main/GUI.lua"))()
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Aiming/main/Load.lua"))()("Module")
local AimingChecks = Aiming.Checks
local AimingSelected = Aiming.Selected
local AimingSettingsIgnored = Aiming.Settings.Ignored
local AimingSettingsIgnoredPlayers = Aiming.Settings.Ignored.Players
local AimingSettingsIgnoredWhitelistMode = AimingSettingsIgnored.WhitelistMode

-- // Services
local UserInputService = game:GetService("UserInputService")

-- // Config
local Configuration = {
    -- // The ones under this you may change - if you are a normal user
    Enabled = true,
    Method = "Target,Hit",
    FocusMode = false, -- // Stays locked on to that player only. If true then uses the silent aim keybind, if a input type is entered, then that is used
    ToggleBind = false, -- // true = Toggle, false = Hold (to enable)
    Keybind = Enum.UserInputType.MouseButton2, -- // You can also have Enum.KeyCode.E, etc.

    -- // Do not change anything below here - if you are not a normal user
    CurrentlyFocused = nil,
    SupportedMethods = {
        __namecall = {"Raycast", "FindPartOnRay", "FindPartOnRayWithWhitelist", "FindPartOnRayWithIgnoreList"},
        __index = {"Target", "Hit", "X", "Y", "UnitRay"}
    },

    ExpectedArguments = {
        FindPartOnRayWithIgnoreList = {
            ArgCountRequired = 3,
            Args = {
                "Instance", "Ray", "table", "boolean", "boolean"
            }
        },
        FindPartOnRayWithWhitelist = {
            ArgCountRequired = 3,
            Args = {
                "Instance", "Ray", "table", "boolean"
            }
        },
        FindPartOnRay = {
            ArgCountRequired = 2,
            Args = {
                "Instance", "Ray", "Instance", "boolean", "boolean"
            }
        },
        Raycast = {
            ArgCountRequired = 3,
            Args = {
                "Instance", "Vector3", "Vector3", "RaycastParams"
            }
        }
    }
}
local IsToggled = false
Aiming.SilentAim = Configuration

-- // Functions
local function CalculateDirection(Origin, Destination, Length)
    return (Destination - Origin).Unit * Length
end

-- // Make sure all of the types match up. I don't think I need this because of ArgGuard but added it since the original did
local function ValidateArguments(Args, RayMethod)
    -- // Vars
    local Matches = 0
    local RayData = Configuration.ExpectedArguments[RayMethod]

    -- // Make sure we have enough args
    if (#Args < RayData.ArgCountRequired) then
        return false
    end

    -- // Loop through each argument
    for Pos, Argument in ipairs(Args) do
        -- // Make sure each argument matches
        if typeof(Argument) == RayData.Args[Pos] then
            Matches = Matches + 1
        end
    end

    -- // Return success/fail
    return Matches >= RayData.ArgCountRequired
end

-- // Checks if a certain method is enabled
local function IsMethodEnabled(Method, Given, PossibleMethods)
    -- // Split it all up
    PossibleMethods = PossibleMethods or Configuration.Method:split(",")
    Given = Given or Method

    -- // Vars
    local FoundI = table.find(PossibleMethods, Method) or table.find(PossibleMethods, Method:lower()) -- // to cover stuff like target (lowercase)
    local Found = FoundI ~= nil
    local Matches = Method:lower() == Given:lower()

    -- // Return
    return Found and Matches
end

-- // Allows you to easily toggle multiple methods on and off
local function ToggleMethod(Method, State)
    -- // Vars
    local EnabledMethods = Configuration.Method:split(",")
    local FoundI = table.find(EnabledMethods, Method)

    -- //
    if (State) then
        if (not FoundI) then
            table.insert(EnabledMethods, Method)
        end
    else
        if (FoundI) then
            table.remove(EnabledMethods, FoundI)
        end
    end

    -- // Set
    Configuration.Method = table.concat(EnabledMethods, ",")
end

-- // Focuses a player
local Backup = {table.unpack(AimingSettingsIgnoredPlayers)}
function Configuration.FocusPlayer(Player)
    table.insert(AimingSettingsIgnoredPlayers, Player)
    AimingSettingsIgnoredWhitelistMode.Players = true
end

-- // Unfocuses a player
function Configuration.Unfocus(Player)
    -- // Find it within ignored, and remove if found
    local PlayerI = table.find(AimingSettingsIgnoredPlayers, Player)
    if (PlayerI) then
        table.remove(AimingSettingsIgnoredPlayers, PlayerI)
    end

    -- // Disable whitelist mode
    AimingSettingsIgnoredWhitelistMode.Players = false
end

-- // Unfocuses everything
function Configuration.UnfocusAll(Replacement)
    Replacement = Replacement or Backup
    AimingSettingsIgnored.Players = Replacement
    AimingSettingsIgnoredWhitelistMode.Players = false
end

-- //
function Configuration.FocusHandler()
    if (Configuration.CurrentlyFocused) then
        Configuration.Unfocus(Configuration.CurrentlyFocused)
        Configuration.CurrentlyFocused = nil
        return
    end

    if (AimingChecks.IsAvailable()) then
        Configuration.FocusPlayer(AimingSelected.Instance)
        Configuration.CurrentlyFocused = AimingSelected.Instance
    end
end

-- // For the toggle and stuff
local function CheckInput(Input, Expected)
    local InputType = Expected.EnumType == Enum.KeyCode and "KeyCode" or "UserInputType"
    return Input[InputType] == Expected
end

UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
    -- // Make sure is not processed
    if (GameProcessedEvent) then
        return
    end

    -- // Check if matches bind
    local FocusMode = Configuration.FocusMode
    if (CheckInput(Input, Configuration.Keybind)) then
        if (Configuration.ToggleBind) then
            IsToggled = not IsToggled
        else
            IsToggled = true
        end

        if (FocusMode == true) then
            Configuration.FocusHandler()
        end
    end

    -- // FocusMode check
    if (typeof(FocusMode) == "Enum" and CheckInput(Input, FocusMode)) then
        Configuration.FocusHandler()
    end
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
    -- // Make sure is not processed
    if (GameProcessedEvent) then
        return
    end

    -- // Check if matches bind
    if (CheckInput(Input, Configuration.Keybind) and not Configuration.ToggleBind) then
        IsToggled = false
    end
end)

-- // Hooks
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(...)
    -- // Vars
    local args = {...}
    local self = args[1]
    local method = getnamecallmethod()

    -- // Make sure everything is in order
    if (self == workspace and not checkcaller() and IsToggled and table.find(Configuration.SupportedMethods.__namecall, method) and AimingChecks.IsAvailable() and Configuration.Enabled and ValidateArguments(args, method)) then
        -- // Raycast
        if (IsMethodEnabled("Raycast", method)) then
            -- // Modify args
            args[3] = CalculateDirection(args[2], AimingSelected.Part.Position, 1000)

            -- // Return
            return __namecall(unpack(args))
        end

        -- // The rest pretty much, modify args
        if (IsMethodEnabled(method)) then
            local Origin = args[2].Origin
            local Direction = CalculateDirection(Origin, AimingSelected.Part.Position, 1000)
            args[2] = Ray.new(Origin, Direction)

            -- // Return
            return __namecall(unpack(args))
        end
    end

    -- //
    return __namecall(...)
end)

local __index
__index = hookmetamethod(game, "__index", function(t, k)
    -- // Make sure everything is in order
    if (t:IsA("Mouse") and not checkcaller() and IsToggled and AimingChecks.IsAvailable() and IsMethodEnabled(k) and Configuration.Enabled) then
        -- // Vars
        local EnabledMethods = Configuration.Method:split(",")

        -- // Target
        if (IsMethodEnabled("Target", k, EnabledMethods)) then
            return AimingSelected.Part
        end

        -- // Hit
        if (IsMethodEnabled("Hit", k, EnabledMethods)) then
            return AimingSelected.Part.CFrame
        end

        -- // X/Y
        if (IsMethodEnabled("X", k, EnabledMethods) or IsMethodEnabled("Y", k, EnabledMethods)) then
            return AimingSelected.Position[k]
        end

        -- // UnitRay
        if (IsMethodEnabled("UnitRay", k, EnabledMethods)) then
            local Origin = __index(t, k).Origin
            local Direction = CalculateDirection(Origin, AimingSelected.Part.Position)
            return Ray.new(Origin, Direction)
        end
    end

    -- // Return
    return __index(t, k)
end)

-- // GUI
local SilentAimSection = AimingPage:addSection({
    title = "Silent Aim"
})

SilentAimSection:addToggle({
    title = "Enabled",
    default = Configuration.Enabled,
    callback = function(value)
        Configuration.Enabled = value
    end
})

SilentAimSection:addToggle({
    title = "Focus Mode",
    default = Configuration.FocusMode,
    callback = function(value)
        Configuration.FocusMode = value
    end
})

SilentAimSection:addToggle({
    title = "Toggle Bind",
    default = Configuration.ToggleBind,
    callback = function(value)
        Configuration.ToggleBind = value
    end
})

SilentAimSection:addKeybind({
    title = "Keybind",
    default = Configuration.Keybind,
    changedCallback = function(value)
        Configuration.Keybind = value
    end
})

SilentAimSection:addToggle({
    title = "Focus Mode (Uses Keybind)",
    default = Configuration.FocusMode,
    callback = function(value)
        Configuration.FocusMode = value
    end
})
SilentAimSection:addKeybind({
    title = "Focus Mode (Custom Bind)",
    changedCallback = function(value)
        Configuration.FocusMode = value
    end
})

-- // Adding each method
local SilentAimMethodsSection = AimingPage:addSection({
    title = "Silent Aim: Methods"
})

for _, method in ipairs(Configuration.SupportedMethods.__index) do
    SilentAimMethodsSection:addToggle({
        title = method,
        default = IsMethodEnabled(method),
        callback = function(value)
            ToggleMethod(method, value)
        end
    })
end
for _, method in ipairs(Configuration.SupportedMethods.__namecall) do
    SilentAimMethodsSection:addToggle({
        title = method,
        default = IsMethodEnabled(method),
        callback = function(value)
            ToggleMethod(method, value)
        end
    })
end