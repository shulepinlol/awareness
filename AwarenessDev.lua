--[[
     █████  ██     ██  █████  ██████  ███████ ███    ██ ███████ ███████ ███████ 
    ██   ██ ██     ██ ██   ██ ██   ██ ██      ████   ██ ██      ██      ██      
    ███████ ██  █  ██ ███████ ██████  █████   ██ ██  ██ █████   ███████ ███████ 
    ██   ██ ██ ███ ██ ██   ██ ██   ██ ██      ██  ██ ██ ██           ██      ██ 
    ██   ██  ███ ███  ██   ██ ██   ██ ███████ ██   ████ ███████ ███████ ███████                                                                                                                                                 
]]

--#region Awareness

local filepath = _G.GetCurrentFilePath()
local localVersionPath = "lol\\Modules\\AwarenessDev"
if not filepath:find(localVersionPath) and io.exists(localVersionPath .. ".lua") then
    require(localVersionPath)
    return
end

local Script = {
    Name = "Awareness",
    Version = "1.1.0",
    LastUpdate = "19/06/2022",
    Initialized = false,
    Disabled = false,
    Modules = {
        TurretRange = {},
        InhibTimer = {},
        SideHUD = {},
        CDTracker = {},
        RecallTracker = {},
        BaseUlt = {},
        PathTracker = {},
        MIATracker = {},
        WardTracker = {},
        JungleTracker = {},
        BaronTracker = {},
        CloneTracker = {},
        Radar = {},
        DashTracker = {},
    }
}

module(Script.Name, package.seeall, log.setup)
clean.module(Script.Name, clean.seeall, log.setup)

--#endregion

--[[
     █████  ██████  ██ 
    ██   ██ ██   ██ ██ 
    ███████ ██████  ██ 
    ██   ██ ██      ██ 
    ██   ██ ██      ██                                  
]]

--#region API

local SDK = _G.CoreEx
local Player = _G.Player

local DamageLib, CollisionLib, DashLib, HealthPred, ImmobileLib, Menu, Orbwalker, Prediction, Profiler, Spell, TS =
_G.Libs.DamageLib, _G.Libs.CollisionLib, _G.Libs.DashLib, _G.Libs.HealthPred, _G.Libs.ImmobileLib, _G.Libs.NewMenu,
_G.Libs.Orbwalker, _G.Libs.Prediction, _G.Libs.Profiler, _G.Libs.Spell, _G.Libs.TargetSelector()

local AutoUpdate, Enums, EvadeAPI, EventManager, Game, Geometry, Input, Nav, ObjectManager, Renderer =
SDK.AutoUpdate, SDK.Enums, SDK.EvadeAPI, SDK.EventManager, SDK.Game, SDK.Geometry, SDK.Input, SDK.Nav, SDK.ObjectManager, SDK.Renderer

local AbilityResourceTypes, BuffType, DamageTypes, Events, GameMaps, GameObjectOrders, HitChance, ItemSlots, 
ObjectTypeFlags, PerkIDs, QueueTypes, SpellSlots, SpellStates, Teams = 
Enums.AbilityResourceTypes, Enums.BuffTypes, Enums.DamageTypes, Enums.Events, Enums.GameMaps, Enums.GameObjectOrders,
Enums.HitChance, Enums.ItemSlots, Enums.ObjectTypeFlags, Enums.PerkIDs, Enums.QueueTypes, Enums.SpellSlots, Enums.SpellStates,
Enums.Teams

local Vector, BestCoveringCircle, BestCoveringCone, BestCoveringRectangle, Circle, CircleCircleIntersection,
Cone, LineCircleIntersection, Path, Polygon, Rectangle, Ring =
Geometry.Vector, Geometry.BestCoveringCircle, Geometry.BestCoveringCone, Geometry.BestCoveringRectangle, Geometry.Circle,
Geometry.CircleCircleIntersection, Geometry.Cone, Geometry.LineCircleIntersection, Geometry.Path, Geometry.Polygon,
Geometry.Rectangle, Geometry.Ring

local abs, acos, asin, atan, ceil, cos, deg, exp, floor, fmod, huge, log, max, min, modf, pi, rad, random, randomseed, sin,
sqrt, tan, type, ult = 
_G.math.abs, _G.math.acos, _G.math.asin, _G.math.atan, _G.math.ceil, _G.math.cos, _G.math.deg, _G.math.exp,
_G.math.floor, _G.math.fmod, _G.math.huge, _G.math.log, _G.math.max, _G.math.min, _G.math.modf, _G.math.pi, _G.math.rad,
_G.math.random, _G.math.randomseed, _G.math.sin, _G.math.sqrt, _G.math.tan, _G.math.type, _G.math.ult

local byte, char, dump, ends_with, find, format, gmatch, gsub, len, lower, match, pack, packsize, rep, reverse,
starts_with, sub, unpack, upper = 
_G.string.byte, _G.string.char, _G.string.dump, _G.string.ends_with, _G.string.find, _G.string.format,
_G.string.gmatch, _G.string.gsub, _G.string.len, _G.string.lower, _G.string.match, _G.string.pack, _G.string.packsize,
_G.string.rep, _G.string.reverse, _G.string.starts_with, _G.string.sub, _G.string.unpack, _G.string.upper

local clock, date, difftime, execute, exit, getenv, remove, rename, setlocale, time, tmpname = 
_G.os.clock, _G.os.date, _G.os.difftime, _G.os.execute, _G.os.exit, _G.os.getenv, _G.os.remove, _G.os.rename, _G.os.setlocale,
_G.os.time, _G.os.tmpname

local concat, insert = _G.table.concat, _G.table.insert

local _Q, _W, _E, _R = 0, 1, 2, 3
local Resolution = Renderer.GetResolution()

---@type ItemIDs
local ItemID = require("lol\\Modules\\Common\\ItemID")

local SLib = _G.Libs.SLib
local Common = SLib.Common

local ScreenPos = {x = Resolution.x, y = Resolution.y}
local ScreenCenter = Vector(ScreenPos.x / 2, ScreenPos.y / 2)
local ScreenPosPct = {x = ScreenPos.x / 100, y = ScreenPos.y / 100}

local testTime = Game.GetTime() --! check

--#endregion

--[[
    ████████ ██    ██ ██████  ██████  ███████ ████████     ██████   █████  ███    ██  ██████  ███████ 
       ██    ██    ██ ██   ██ ██   ██ ██         ██        ██   ██ ██   ██ ████   ██ ██       ██      
       ██    ██    ██ ██████  ██████  █████      ██        ██████  ███████ ██ ██  ██ ██   ███ █████   
       ██    ██    ██ ██   ██ ██   ██ ██         ██        ██   ██ ██   ██ ██  ██ ██ ██    ██ ██      
       ██     ██████  ██   ██ ██   ██ ███████    ██        ██   ██ ██   ██ ██   ████  ██████  ███████                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
]]

--#region Turret Range

local TurretRange = Script.Modules.TurretRange

TurretRange.List = {}
TurretRange.Config = {}
TurretRange.Color = 0xFFFFFF00

function TurretRange.Initialize(self)
    local invalidTurrets = {
        ["Turret_ChaosTurretShrine_A"] = true,
        ["Turret_OrderTurretShrine_A"] = true,
    }

    for handle, obj in pairs(ObjectManager.Get("all", "turrets")) do
        local turret = obj.AsAI
        if turret and not invalidTurrets[turret.Name] then
            TurretRange.List[#TurretRange.List + 1] = {
                Object = obj,
                IsEnemy = turret.IsEnemy,
                Range = turret.BoundingRadius + 785,
                Position = turret.Position + Vector(0, 0, 15)
            }
        end
    end
end

function TurretRange.LoadConfig()
    Menu.NewTree("SAwareness.TurretRange", "Turret Range", function()
		Common.CreateCheckbox("SAwareness.TurretRange.Enabled", "Enabled", true)

        Menu.NewTree("SAwareness.TurretRange.DrawSettings", "Draw Settings", function()
            Common.CreateCheckbox("SAwareness.TurretRange.DrawAlly", "Draw On Ally Turrets", true)
            Common.CreateCheckbox("SAwareness.TurretRange.DrawEnemy", "Draw On Enemy Turrets", true)
            Common.CreateSlider("SAwareness.TurretRange.Thickness", "Thickness", 3, 1, 10, 1)
            Common.CreateColorPicker("SAwareness.TurretRange.Color", "Color", 0xFFFFFF00)
        end)

        Menu.NewTree("SAwareness.TurretRange.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("TurretRange")
        end)
        TurretRange.Color = bit.band(0xFFFFFF00, TurretRange.Get("Color"))
    end) 
end

function TurretRange.Get(value)
	return Menu.Get("SAwareness.TurretRange." .. value, true)
end

function TurretRange.OnDraw()
	if not TurretRange.Get("Enabled") then return end

    local bEnemy, bAlly = TurretRange.Get("DrawEnemy"), TurretRange.Get("DrawAlly")
    if not (bEnemy or bAlly) then return end

	local thickness = TurretRange.Get("Thickness")
    local myPosition = Player.Position

    local count = #TurretRange.List
    for i = count, 1, -1 do
        local turret = TurretRange.List[i]
        local position = turret.Position
        local dist = position:Distance(myPosition)
            
        if dist < 1300 then
            local obj = turret.Object
    	    if obj.IsValid and not obj.IsDead then
                if (bEnemy and turret.IsEnemy) or (bAlly and not turret.IsEnemy) then                    
                    local alpha = (400 - dist * 0.5) + 260
                    local color = TurretRange.Color + min(alpha, 255)

                    local spell = obj.ActiveSpell
                    local target = spell and spell.Target                    
                    if target and target.IsMe then
                        color = 0xE60000FF
                    end
                    Renderer.DrawCircle3D(position, turret.Range, 10, thickness, color)
                end
            else
                TurretRange.List[i] = TurretRange.List[count]
                TurretRange.List[count] = nil
                count = count - 1
            end
        end
    end
end

--#endregion

--[[
    ██ ███    ██ ██   ██ ██ ██████      ████████ ██ ███    ███ ███████ ██████  
    ██ ████   ██ ██   ██ ██ ██   ██        ██    ██ ████  ████ ██      ██   ██ 
    ██ ██ ██  ██ ███████ ██ ██████         ██    ██ ██ ████ ██ █████   ██████  
    ██ ██  ██ ██ ██   ██ ██ ██   ██        ██    ██ ██  ██  ██ ██      ██   ██ 
    ██ ██   ████ ██   ██ ██ ██████         ██    ██ ██      ██ ███████ ██   ██                                                                                                                                                                                                                                                               
]]

--#region Inhibitor Timer

local InhibTimer = Script.Modules.InhibTimer

InhibTimer.List = {}
InhibTimer.Sprites = {}
InhibTimer.Fonts = {}
InhibTimer.LastTime = 0
InhibTimer.Scale = 1

function InhibTimer.Initialize()
    InhibTimer.LoadObjects()
    InhibTimer.LoadSprites()
    InhibTimer.LoadFonts()
end

function InhibTimer.LoadObjects()
    for handle, inhib in pairs(ObjectManager.Get("all", "inhibitors")) do
        InhibTimer.List[#InhibTimer.List + 1] = {
            Object = inhib,
            RespawnTime = 0,
            Position = inhib.Position,    
            IsDestroyed = inhib.IsDead       
        }
    end
end

function InhibTimer.LoadSprites()
    InhibTimer["Sprites"]["Icon"] = SLib.CreateSprite("Icons\\button-hover.png", 64, 64)
end

function InhibTimer.LoadFonts()
    InhibTimer["Fonts"]["WT"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
    InhibTimer["Fonts"]["WTMM"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
end

function InhibTimer.LoadConfig()
    Menu.NewTree("SAwareness.InhibTimer", "Inhibitor Timer", function()
		Common.CreateCheckbox("SAwareness.InhibTimer.Enabled", "Enabled", true)

        Common.CreateCheckbox("SAwareness.InhibTimer.DrawOnInhib", "Draw On Inhibitor", true)
        Common.CreateCheckbox("SAwareness.InhibTimer.DrawOnMM", "Draw On Minimap", true)

        Menu.NewTree("SAwareness.InhibTimer.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.InhibTimer.WT", "Inhibitor Timer [World]", function()
                Common.CreateCheckbox("SAwareness.InhibTimer.WT.Sprite", "Draw Sprite", true)
                if InhibTimer.Get("WT.Sprite") then
                    Common.CreateSlider("SAwareness.InhibTimer.WT.Scale", "Sprite Scale", 100, 0, 200, 1)
                end
                Common.CreateSlider("SAwareness.InhibTimer.WT.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.InhibTimer.WT.FontColor", "Font Color", 0xFFFFFFFF)
            end)
            Menu.NewTree("SAwareness.InhibTimer.WTMM", "Inhibitor Timer [Minimap]", function()
                Common.CreateCheckbox("SAwareness.InhibTimer.WTMM.Rect", "Draw Semi-transparent Rectangle Behing Font", true)
                Menu.Text("")
                Common.CreateSlider("SAwareness.InhibTimer.WTMM.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.InhibTimer.WTMM.FontColor", "Font Color", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SAwareness.InhibTimer.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("InhibTimer")
        end)
    end)
end

function InhibTimer.Get(value)
	return Menu.Get("SAwareness.InhibTimer." .. value, true)
end

function InhibTimer.OnTick()
    InhibTimer.Scale = InhibTimer.Get("WT.Scale") / 100
    
    local gameTime = Game.GetTime()    
    if InhibTimer.LastTime < gameTime then
        InhibTimer.LastTime = gameTime + 1

        for i, inhib in ipairs(InhibTimer.List) do
            local obj = inhib.Object
            if obj.IsValid then
                local health = obj.Health
                if health == 0 and not inhib.IsDestroyed then
                    inhib.IsDestroyed = true
                    inhib.RespawnTime = gameTime
                elseif health > 0 and inhib.IsDestroyed then
                    inhib.IsDestroyed = false
                end
            end
        end
    end
end

function InhibTimer.OnDraw()
    if not InhibTimer.Get("Enabled") then return end

    local X, Y = (32 * InhibTimer.Scale), (32 * InhibTimer.Scale)
    local W, H = (64 * InhibTimer.Scale), (64 * InhibTimer.Scale)

    local scaleX = InhibTimer.Sprites.Icon.X * InhibTimer.Scale
    local scaleY = InhibTimer.Sprites.Icon.Y * InhibTimer.Scale

    local bDrawWorld, bDrawMM = InhibTimer.Get("DrawOnInhib"), InhibTimer.Get("DrawOnMM")
    local WT_Color, WTMM_Color = InhibTimer.Get("WT.FontColor"), InhibTimer.Get("WTMM.FontColor")
    local WT_Size, WTMM_Size = InhibTimer.Get("WT.FontSize") * InhibTimer.Scale, InhibTimer.Get("WTMM.FontSize") * InhibTimer.Scale
    local WT_bg, WTMM_bg = InhibTimer.Get("WT.Sprite"), InhibTimer.Get("WTMM.Rect")
    local WT_Font, WTMM_Font = InhibTimer.Fonts.WT, InhibTimer.Fonts.WTMM
    
    local gameTime = Game.GetTime()
    for i, inhib in ipairs(InhibTimer.List) do
        if inhib.IsDestroyed then
            local time = inhib.RespawnTime + 300 - gameTime            
            if time > 0 then
                local pos = inhib.Position
                local text = Common.DecToMin(time)

                if bDrawWorld and WT_Font then
                    local posw2s = inhib.Position:ToScreen()                    
                    if Renderer.IsOnScreen2D(posw2s) then
                        if WT_bg then
                            InhibTimer.Sprites.Icon:SetScale(scaleX, scaleY):Draw(posw2s, nil, true)
                        end

                        local textExtent = WT_Font.Font:CalcTextSize(text)
                        local textVector = Vector(posw2s.x - X + (W - textExtent.x)/2, posw2s.y - Y + (H - textExtent.y)/2)
                        WT_Font:SetColor(WT_Color):SetSize(WT_Size):Draw(textVector, text)
                    end
                end
                if bDrawMM and WTMM_Font then        
                    local posw2m = inhib.Position:ToMM()                
                    local textExtent = WTMM_Font.Font:CalcTextSize(text)                    
                    local textVector = Vector(posw2m.x - (textExtent.x / 2), posw2m.y - (textExtent.y / 2))
                    
                    if WTMM_bg then
                        Renderer.DrawFilledRect(textVector, textExtent, 0, 0x00000069)
                    end
                    WTMM_Font:SetColor(WTMM_Color):SetSize(WTMM_Size):Draw(textVector, text) 
                end
            end
        end
    end
end

--#endregion

--[[
    ███████ ██ ██████  ███████     ██   ██ ██    ██ ██████  
    ██      ██ ██   ██ ██          ██   ██ ██    ██ ██   ██ 
    ███████ ██ ██   ██ █████       ███████ ██    ██ ██   ██ 
         ██ ██ ██   ██ ██          ██   ██ ██    ██ ██   ██ 
    ███████ ██ ██████  ███████     ██   ██  ██████  ██████                                                                                                              
]]

--#region Side HUD

local SideHUD = Script.Modules.SideHUD

SideHUD.X = 0
SideHUD.Y = 0
SideHUD.Scale = 1
SideHUD.Fonts = {}
SideHUD.Rect = {}
SideHUD.MoveOffset = {}
SideHUD.Data = {
    ["HP"] = {},
    ["MP"] = {},
    ["Ultimate"] = {},
    ["Summoners"] = {},
    ["ChampionLevel"] = {},
}

SideHUD.Sprites = {
    ["Main"] = nil,
    ["CD"] = {},
    ["Champions"] = {},
    ["Ultimates"] = {},
    ["Summoners"] = {
        ["CD"] = nil,
    },
    ["Elements"] = {},
}

SideHUD.SpriteNames = {
    ["Summoners"] = {
        ["S5_SummonerSmiteDuel"] = true,
        ["S5_SummonerSmitePlayerGanker"] = true,
        ["SummonerSmite"] = true,
        ["SummonerBoost"] = true,
        ["SummonerBarrier"] = true,
        ["SummonerDot"] = true,
        ["SummonerExhaust"] = true,
        ["SummonerFlash"] = true,
        ["SummonerTeleport"] = true,
        ["SummonerTeleportUpgrade"] = true,
        ["SummonerHaste"] = true,
        ["SummonerHeal"] = true,
        ["SummonerMana"] = true,
        ["SummonerPoroRecall"] = true,
        ["SummonerPoroThrow"] = true,
        ["SummonerFlashPerksHextechFlashtraptionV2"] = true,
        ["SummonerSnowball"] = true,
        ["SummonerDarkStarChampSelect1"] = true,
        ["SummonerSnowURFSnowball_Mark"] = true,
    }
}

function SideHUD.Initialize()
    SideHUD.DrawQueue = {}
    SideHUD.LastUpdate = 0

    SideHUD.LoadSprites()
    SideHUD.LoadFonts()
end

function SideHUD.LoadSprites()
    SideHUD["Sprites"]["Main"] = SLib.CreateSprite("HUD\\SIDE_HUD.png", 137, 107)
    SideHUD["Sprites"]["CD"] = SLib.CreateSprite("HUD\\WB.png", 64, 64)
    SideHUD["Sprites"]["DeathTimer"] = SLib.CreateSprite("HUD\\WB.png", 45, 45)
    SideHUD["Sprites"]["ChampionLevel"] = SLib.CreateSprite("HUD\\WB.png", 64, 64)
    SideHUD["Sprites"]["Summoners"]["CD"] = SLib.CreateSprite("HUD\\WB.png", 21, 21)
    
    for handle, hero in pairs(ObjectManager.Get("all", "heroes")) do
        local charName = hero.CharName
        SideHUD["Sprites"]["Champions"][charName] = SLib.CreateSprite("Champions\\" .. charName .. "_Square.png", 45, 45)
        SideHUD["Sprites"]["Ultimates"][charName] = SLib.CreateSprite("Spells\\" .. charName .. "\\" .. "R.png", 45, 45)
        
        SideHUD["Sprites"]["Elements"][charName] = {}
        SideHUD["Sprites"]["Elements"][charName]["HP"] = SLib.CreateSprite("HUD\\WB.png", 121, 18)
        SideHUD["Sprites"]["Elements"][charName]["MP"] = SLib.CreateSprite("HUD\\WB.png", 121, 18)
    end

    for name, position in pairs(SideHUD.SpriteNames["Summoners"]) do
        SideHUD["Sprites"]["Summoners"][name] = SLib.CreateSprite("Summoners\\" .. name .. ".png", 21, 21)
    end
end

function SideHUD.LoadFonts()
    SideHUD["Fonts"]["HP"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
    SideHUD["Fonts"]["MP"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
    SideHUD["Fonts"]["Ultimate"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
    SideHUD["Fonts"]["Summoners"] = SLib.CreateFont("Bahnschrift.ttf", 16, 0xFFFFFFFF)
    SideHUD["Fonts"]["ChampionLevel"] = SLib.CreateFont("Bahnschrift.ttf", 12, 0xFFFFFFFF)
    SideHUD["Fonts"]["DeathTimer"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
end

function SideHUD.LoadConfig()
    Menu.NewTree("SAwareness.SideHUD", "Side HUD", function()
		Common.CreateCheckbox("SAwareness.SideHUD.Enabled", "Enabled", false)
        
        Menu.NewTree("SAwareness.SideHUD.PositionSettings", "Position Settings", function()
            Common.CreateSlider("SAwareness.SideHUD.X", "X", 100, 0, Resolution.x, 1)
            Common.CreateSlider("SAwareness.SideHUD.Y", "Y", 100, 0, Resolution.y, 1)
            Common.CreateSlider("SAwareness.SideHUD.Scale", "Scale", 75, 0, 200, 1)
            Common.CreateSlider("SAwareness.SideHUD.Space", "Space", 0, -100, 100, 1)
            Common.CreateDropdown("SAwareness.SideHUD.Orientation", "Orientation", 0, {"Vertical", "Horizontal"})
            Common.CreateCheckbox("SAwareness.SideHUD.Drag", "Allow To Drag By SHIFT + LMB", true)
        end)
        
        Menu.NewTree("SAwareness.SideHUD.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.SideHUD.HP", "Health Bar", function()
                Common.CreateColorPicker("SAwareness.SideHUD.HP.BarColor", "Bar Color", 0x25882EFF)
                Common.CreateSlider("SAwareness.SideHUD.HP.FontSize", "Font Size", 20, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.HP.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.SideHUD.HP.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.HP.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.SideHUD.MP", "Mana Bar", function()
                Common.CreateColorPicker("SAwareness.SideHUD.MP.BarColor", "Bar Color", 0x3A95B9FF)
                Common.CreateSlider("SAwareness.SideHUD.MP.FontSize", "Font Size", 20, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.MP.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.SideHUD.MP.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.MP.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.SideHUD.Ultimate", "Ultimate Spell", function()
                Common.CreateDropdown("SAwareness.SideHUD.Ultimate.Format", "Format", 2, { "Seconds", "Minutes : Seconds", "Minutes (If < 1 Then Seconds)" })
                Common.CreateSlider("SAwareness.SideHUD.Ultimate.FontSize", "Font Size", 20, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.Ultimate.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.SideHUD.Ultimate.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.Ultimate.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.SideHUD.Summoners", "Summoner Spells", function()
                Common.CreateDropdown("SAwareness.SideHUD.Summoners.Format", "Format", 2, { "Seconds", "Minutes : Seconds", "Minutes (If < 1 Then Seconds)" })
                Common.CreateSlider("SAwareness.SideHUD.Summoners.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.Summoners.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.SideHUD.Summoners.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.Summoners.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.SideHUD.ChampionLevel", "Champion Level", function()
                Menu.Checkbox("SAwareness.SideHUD.ChampionLevel.Enabled", "Enabled", true)
                Common.CreateSlider("SAwareness.SideHUD.ChampionLevel.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.ChampionLevel.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.SideHUD.ChampionLevel.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.ChampionLevel.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.SideHUD.DeathTimer", "Death Timer", function()
                Menu.Checkbox("SAwareness.SideHUD.DeathTimer.Enabled", "Enabled", true)
                Common.CreateSlider("SAwareness.SideHUD.DeathTimer.FontSize", "Font Size", 20, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.SideHUD.DeathTimer.FontColor", "Font Color", 0xFF2626FF)
                Common.CreateSlider("SAwareness.SideHUD.DeathTimer.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.SideHUD.DeathTimer.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
        end)
        
        Menu.NewTree("SAwareness.SideHUD.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("SideHUD")
        end)
    end)
end

function SideHUD.Get(value)
	return Menu.Get("SAwareness.SideHUD." .. value, true)
end

function SideHUD.UpdateSprites(sprites, scale)
    for _, sprite in pairs(sprites) do
        if sprite.SetScale then
            sprite:SetScale(sprite.X * scale, sprite.Y * scale)
        else
            --Update Recursively
            SideHUD.UpdateSprites(sprite, scale)
        end
    end
end

function SideHUD.UpdateFonts(fonts, scale)
    for name, font in pairs(fonts) do
        font:SetColor(SideHUD.Get(name..".FontColor"))
        font:SetSize(SideHUD.Get(name..".FontSize") * scale)
    end
end

function SideHUD.UpdateDrag()
    local time = Game.GetTime()    
    local stoppedDragging = false
    SideHUD.IsDragging = false

    if Common.ShiftPressed and SideHUD.Get("Drag") then
        SideHUD.IsDragging = true

        local width = 0
        local space = SideHUD.Get("Space")
        local orientation = SideHUD.Get("Orientation")
        for handle, hero in pairs(SLib.Heroes) do
            if not hero.IsAlly then            
                if orientation == 0 then
                    width = width + ((108 + space) * SideHUD.Scale)
                else
                    width = width + ((140 + space) * SideHUD.Scale)
                end
            end   
        end
            
        local cursorPos = Renderer.GetCursorPos()
        if orientation == 0 then
            SideHUD.Rect = {x = SideHUD.X - 5, y = SideHUD.Y - 5, z = 138 * SideHUD.Scale, w = width}
        else
            SideHUD.Rect = {x = SideHUD.X - 5, y = SideHUD.Y - 5, z = width, w = 107 * SideHUD.Scale}
        end

        local rect = SideHUD.Rect
        if not SideHUD.MoveOffset and rect and Common.CursorIsUnder(rect.x, rect.y, rect.z, rect.w) and Common.LMBPressed then
            SideHUD.MoveOffset = {
                x = rect.x - cursorPos.x + 5,
                y = rect.y - cursorPos.y + 5
            }
        elseif SideHUD.MoveOffset and not Common.LMBPressed then
            SideHUD.MoveOffset = nil
            stoppedDragging = true            
        end

        if SideHUD.MoveOffset and rect and rect.x and rect.y then
            rect.x = SideHUD.MoveOffset.x + cursorPos.x
            rect.x = rect.x > 0 and rect.x or 0
            rect.x = rect.x < Resolution.x - rect.z and rect.x or Resolution.x - rect.z

            rect.y = SideHUD.MoveOffset.y + cursorPos.y
            rect.y = rect.y > 0 and rect.y or 0
            rect.y = rect.y < (Resolution.y - rect.w + 6) and rect.y or (Resolution.y - rect.w + 6)

            if Common.LMBPressed then
                SideHUD.X = rect.x
                SideHUD.Y = rect.y

                SideHUD.OverridePos = {x=rect.x, y=rect.y}
            end
        end
    end

    if stoppedDragging and SideHUD.OverridePos then
        Menu.Set("SAwareness.SideHUD.X", SideHUD.OverridePos.x, true)
        Menu.Set("SAwareness.SideHUD.Y", SideHUD.OverridePos.y, true)
        SideHUD.OverridePos = nil
    end
end

function SideHUD.UpdateDrawings()
    local time = Game.GetTime()
    if (time - SideHUD.LastUpdate < 0.2) and not SideHUD.IsDragging then return end
    SideHUD.LastUpdate = time

    SideHUD.DrawQueue = {}
    
    local hudScale = SideHUD.Scale
    SideHUD.UpdateFonts(SideHUD.Fonts, hudScale)
    SideHUD.UpdateSprites(SideHUD.Sprites, hudScale)

    local x, y = SideHUD.X, SideHUD.Y
    local isVertical = SideHUD.Get("Orientation") == 0
    local incrementX = isVertical and 0 or ((140 + SideHUD.Get("Space")) * hudScale)
    local incrementY = isVertical and ((108 + SideHUD.Get("Space")) * hudScale) or 0

    local deathTimerSize = {
        SideHUD.Get("DeathTimer.FontOffsetX") + (45 * hudScale)*0.5,
        SideHUD.Get("DeathTimer.FontOffsetY") + (45 * hudScale)*0.5
    }

    local hpBarColor = SideHUD.Get("HP.BarColor")
    local mpBarColor = SideHUD.Get("MP.BarColor")
    local drawLevel  = SideHUD.Get("ChampionLevel.Enabled")
    local summonerFm = SideHUD.Get("Summoners.Format")
    local ultimateFm = SideHUD.Get("Ultimate.Format")

    local healthBarSize = {
        (3 * hudScale) + SideHUD.Get("HP.FontOffsetX") + (125 * hudScale)/2,
        (51 * hudScale) + SideHUD.Get("HP.FontOffsetY") + (23 * hudScale)/2
    }

    local manaBarSize = {
        (3 * hudScale) + SideHUD.Get("MP.FontOffsetX") + (125 * hudScale)/2,
        (74 * hudScale) + SideHUD.Get("MP.FontOffsetY") + (23 * hudScale)/2
    }
    local summonerSize = {
        (23 * hudScale)/2 + SideHUD.Get("Summoners.FontOffsetX"),
        (20 * hudScale)/2 + SideHUD.Get("Summoners.FontOffsetY")
    }
    local ultimateSize = {
        SideHUD.Get("Ultimate.FontOffsetX") + (45 * hudScale)/2 + hudScale ,
        SideHUD.Get("Ultimate.FontOffsetY") + (45 * hudScale)/2            
    }

    for handle, hero in pairs(SLib.Heroes) do
        if hero.IsAlly then
            goto skip
        end        

        local hp = hero.Health.Value
        local maxHp = hero.MaxHealth.Value
        local mana = hero.Mana.Value
        local maxMana = hero.MaxMana.Value
        local hpPercent = hero.HealthPercent.Value
        local mpPercent = hero.ManaPercent.Value
        local charName = hero.CharName
        local isDead = hero.IsDead.Value

        do --//* Main HUD *//--
            local sprite = SideHUD.Sprites.Main
            if sprite then                
                local position = {x = x - (4 * hudScale), y = y - (4 * hudScale)}          
                insert(SideHUD.DrawQueue, function() sprite:Draw(position) end)
            end
        end

        do --//* Champion Sprites *//--
            local heroSprite = SideHUD.Sprites.Champions[charName]
            local mainVec = {x = x + (4 * hudScale), y = y + (4 * hudScale)}
            
            if not isDead then
                if heroSprite then
                    insert(SideHUD.DrawQueue, function() heroSprite:Draw(mainVec) end)
                end
            else   
                if heroSprite then 
                    insert(SideHUD.DrawQueue, function() heroSprite:Draw(mainVec) end)
                end

                local cdSprite = SideHUD.Sprites.DeathTimer
                if cdSprite then
                    cdSprite:SetColor(0x000000CA)
                    insert(SideHUD.DrawQueue, function() cdSprite:Draw(mainVec) end)
                end                

                local font = SideHUD.Fonts["DeathTimer"]
                if font then
                    local text = format("%d", hero.TimeUntilRespawn.Value)
                    
                    -- //TODO: Move textExtent/textPosition out of DrawQueue function when it can be called from out of OnDraw
                    insert(SideHUD.DrawQueue, function() 
                        local textExtent = font.Font:CalcTextSize(text)
                        local textPosition = {x = mainVec.x + deathTimerSize[1] - textExtent.x*0.5, y = mainVec.y + deathTimerSize[2] - textExtent.y*0.5}
                        font:Draw(textPosition, text, handle) 
                    end)                    
                end
            end
        end

        do --//* Health Bar *//--            
            local sprite = SideHUD.Sprites.Elements[charName]["HP"]            
            if sprite then
                sprite:SetColor(hpBarColor):SetScale((sprite.X * hudScale) * hpPercent, (sprite.Y * hudScale))
                
                local spritePosition = {x = x + (4 * hudScale), y = y + (54 * hudScale)}                    
                insert(SideHUD.DrawQueue, function() sprite:Draw(spritePosition) end)
            end

            local font = SideHUD.Fonts["HP"]
            if font then 
                local text = format("%d / %d", hp, maxHp)
                local textExtent = (font.TextSize[handle] and font.TextSize[handle][1]) or {x=0, y=0}
                local textPosition = {
                    x = x + healthBarSize[1] - textExtent.x/2,
                    y = y + healthBarSize[2] - textExtent.y/2
                }
                insert(SideHUD.DrawQueue, function() 
                    font:Draw(textPosition, text, handle) 
                end)
            end
        end

        do --//* Mana Bar *//--         
            local sprite = SideHUD.Sprites.Elements[charName]["MP"]
            if sprite then
                sprite:SetColor(mpBarColor):SetScale((sprite.X * hudScale) * mpPercent, (sprite.Y * hudScale))
                
                local spritePosition = {x = x + (4 * hudScale), y = y + (77 * hudScale)}                    
                insert(SideHUD.DrawQueue, function() sprite:Draw(spritePosition) end)
            end

            local font = SideHUD.Fonts["MP"]
            if font then
                local text = format("%d / %d", mana, maxMana)
                local textExtent = (font.TextSize[handle] and font.TextSize[handle][1]) or {x=0, y=0}
                local textPosition = {
                    x = x + manaBarSize[1] - textExtent.x/2,
                    y = y + manaBarSize[2] - textExtent.y/2
                }
                insert(SideHUD.DrawQueue, function() font:Draw(textPosition, text, handle) end)
            end
        end

        do --//* Summoner Spells *//--
            for slot = 4, 5 do
                local offset = slot == 5 and 28 or 4
                local spell = SLib.SpellManager:Get(hero, slot)                   
                local spritePosition = {x = x + (54 * hudScale), y = y + (offset * hudScale)}

                local sprite = SideHUD.Sprites.Summoners[spell.Name]
                if sprite then
                    insert(SideHUD.DrawQueue, function() sprite:Draw(spritePosition) end)
                end

                local remainingTime = spell.CooldownExpireTime - time
                if remainingTime > 0 then
                    local cdSprite = SideHUD.Sprites.Summoners.CD
                    if cdSprite then
                        cdSprite:SetColor(0x000000CA)
                        local tmpScale = cdSprite.X * hudScale
                        insert(SideHUD.DrawQueue, function() cdSprite:SetScale(tmpScale, tmpScale):Draw(spritePosition) end)
                    end
                    
                    local font = SideHUD.Fonts.Summoners
                    if font then
                        local text = summonerFm == 0 and format("%d", floor(remainingTime)) or 
                                    summonerFm == 1 and Common.DecToMin(remainingTime) or 
                                    summonerFm == 2 and Common.DecToMin3(remainingTime)                        
                        insert(SideHUD.DrawQueue, function() 
                            local textExtent = font.Font:CalcTextSize(text)         
                            local textPosition = {
                                x = spritePosition.x + summonerSize[1] - textExtent.x/2,
                                y = spritePosition.y + summonerSize[2] - textExtent.y/2
                            }
                            font:Draw(textPosition, text) 
                        end)
                    end
                end
            end
        end

        do --//* Ultimate Sprites *//--
            local spritePosition = {x = x + (80 * hudScale), y = y + (4 * hudScale)}
            
            local ultSprite = SideHUD.Sprites.Ultimates[charName]
            if ultSprite then
                insert(SideHUD.DrawQueue, function() ultSprite:Draw(spritePosition) end)
            end
                      
            local cdSprite = SideHUD.Sprites.CD
            local tmpScale = 45 * hudScale

            local spell = SLib.SpellManager:Get(hero, 3)
            local remainingTime = spell.CooldownExpireTime - time
            local lvl = spell.Level

            if remainingTime > 0 and lvl > 0 then
                if cdSprite then
                    cdSprite:SetColor(0x000000CA)
                    insert(SideHUD.DrawQueue, function() cdSprite:SetScale(tmpScale, tmpScale):Draw(spritePosition) end)
                end

                local font = SideHUD.Fonts["Ultimate"]
                if font then
                    local text = ultimateFm == 0 and format("%d", floor(remainingTime)) or 
                        ultimateFm == 1 and Common.DecToMin(remainingTime) or 
                        ultimateFm == 2 and Common.DecToMin3(remainingTime)                    
                    insert(SideHUD.DrawQueue, function() 
                        local textExtent = font.Font:CalcTextSize(text)
                        local textPosition = {
                            x = spritePosition.x + ultimateSize[1] - textExtent.x/2,
                            y = spritePosition.y + ultimateSize[2] - textExtent.y/2
                        }
                        font:Draw(textPosition, text) 
                    end)                        
                end
            elseif lvl < 1 then
                if cdSprite then
                    cdSprite:SetColor(0x000000CA)
                    insert(SideHUD.DrawQueue, function() cdSprite:SetScale(tmpScale, tmpScale):Draw(spritePosition) end)
                end
            end
        end      
        
        do --//* Champion Level *//--
            if drawLevel then                             
                local font = SideHUD.Fonts.ChampionLevel
                if font then
                    local cdSprite = SideHUD.Sprites.ChampionLevel    
                    if cdSprite then
                        cdSprite:SetColor(0x000000CA)

                        local offset = (48 * hudScale)
                        local position = {x = x + offset - font.Size, y = y + offset - font.Size}                        
                        insert(SideHUD.DrawQueue, function() cdSprite:SetScale(font.Size, font.Size):Draw(position) end)
                    end 

                    local text = tostring(hero.Level.Value)
                    local textExtent = (font.TextSize[handle] and font.TextSize[handle][1]) or {x=0, y=0}
                    local textPosition = {
                        x = x + (48 * hudScale) - (font.Size + textExtent.x)/2 + 1,
                        y = y + (48 * hudScale) - font.Size
                    }
                    insert(SideHUD.DrawQueue, function() font:Draw(textPosition, text, handle) end)
                end
            end
        end

        x = x + incrementX
        y = y + incrementY
        ::skip::
    end
end

function SideHUD.OnTick()    
    if not SideHUD.Get("Enabled") then SideHUD.DrawQueue = {}; return end

    SideHUD.X = (SideHUD.OverridePos and SideHUD.OverridePos.x) or SideHUD.Get("X")
    SideHUD.Y = (SideHUD.OverridePos and SideHUD.OverridePos.y) or SideHUD.Get("Y")
    SideHUD.Scale = SideHUD.Get("Scale") * 0.01
        
    SideHUD.UpdateDrag()
    SideHUD.UpdateDrawings() 
end

function SideHUD.OnDraw()    
    if not SideHUD.Get("Enabled") then return end

    for _, f in ipairs(SideHUD.DrawQueue) do
        f()
    end
end

--#endregion

--[[
     ██████ ██████      ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██      ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██      ██   ██        ██    ██████  ███████ ██      █████   █████   ██████  
    ██      ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
     ██████ ██████         ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██ 
                                                                                                                                                     
]]

--#region CD Tracker

local CDTracker = Script.Modules.CDTracker

CDTracker.Fonts = {}
CDTracker.Sprites = {
    ["HP_HUD_1"] = nil,
    ["HP_HUD_2"] = nil,
    ["HP_HUD_3"] = nil,
    ["HP_HUD_4"] = nil,
    ["Summoners"] = {
        ["CD"] = nil,
    },
    ["Spells"] = {
        ["CD"] = nil,
    },
    ["Passives"] = {},
}
CDTracker.Offsets = {
    ["Annie"] = {false, Vector(0, 12, 0)},
    ["Jhin"] = {false, Vector(0, 12, 0)},
    ["Pantheon"] = {false, Vector(0, 12, 0)},
    ["Irelia"] = {false, Vector(0, 12, 0)},
    ["Ryze"] = {false, Vector(0, 16, 0)},
    ["Zoe"] = {true, Vector(0, 0, 0)},
    ["Aphelios"] = {true, Vector(0, 7, 0)},
    ["Xayah"] = {true, Vector(0, 17, 0)},
    ["Samira"] = {false, Vector(0, 12, 0)},
    ["Sylas"] = {true, Vector(0, 0, 0)},
    ["Graves"] = {true, Vector(0, 19, 0)},
    ["Corki"] = {false, Vector(0, 12, 0)},
    ["Seraphine"] = {true, Vector(0, 12, 0)},
    ["Sona"] = {true, Vector(0, 12, 0)},
}

function CDTracker.Initialize()
    CDTracker.LoadSprites()
    CDTracker.LoadFonts()

    CDTracker.xOffset = 77
    CDTracker.yOffset = 25  

    CDTracker.DrawQueue = {}
    CDTracker.LastUpdate = 0
end

function CDTracker.LoadSprites()
    --//* Spell CD *//--
    CDTracker["Sprites"]["HP_HUD_1"] = SLib.CreateSprite("HUD\\WB.png", 26, 2)
    CDTracker["Sprites"]["HP_HUD_2"] = SLib.CreateSprite("HUD\\WB.png", 26, 2)
    CDTracker["Sprites"]["HP_HUD_3"] = SLib.CreateSprite("HUD\\WB.png", 26, 2):SetColor(0x373737FF)
    CDTracker["Sprites"]["HP_HUD_4"] = SLib.CreateSprite("HUD\\WB.png", 105, 2)
    CDTracker["Sprites"]["Spells"]["CD"] = SLib.CreateSprite("HUD\\WB.png", 26, 26):SetColor(0x000000AC)

    for k, hero in pairs(SLib.Heroes) do
        CDTracker["Sprites"]["Spells"][hero.CharName] = {}
        CDTracker["Sprites"]["Passives"][hero.CharName] = SLib.CreateSprite("Passives\\" .. hero.CharName .. ".png", 26, 26)
        for slot = 0, 3 do
            local spell = Common.SlotToString(slot)
            CDTracker["Sprites"]["Spells"][hero.CharName][slot] = SLib.CreateSprite("Spells\\" .. hero.CharName .. "\\" .. spell .. ".png", 26, 26)
        end
    end

    --//* Summoner Spell CD *//--
    CDTracker["Sprites"]["Summoners"]["CD"] = SLib.CreateSprite("HUD\\WB.png", 23, 23):SetColor(0x000000AC)
    for name, position in pairs(SideHUD.SpriteNames["Summoners"]) do
        CDTracker["Sprites"]["Summoners"][name] = SLib.CreateSprite("Summoners\\" .. name .. ".png", 23, 23)
    end
end

function CDTracker.LoadFonts()
    CDTracker["Fonts"]["CD"] = SLib.CreateFont("Bahnschrift.ttf", 16, 0xFFFFFFFF)
    CDTracker["Fonts"]["SummonerCD"] = SLib.CreateFont("Bahnschrift.ttf", 15, 0xFFFFFFFF)
end

function CDTracker.LoadConfig()
    Menu.NewTree("SAwareness.CDTracker", "CD Tracker", function()
		Common.CreateCheckbox("SAwareness.CDTracker.Enabled", "Enabled", true)
        
        Menu.NewTree("SAwareness.CDTracker.AppearanceSettings", "Appearance Settings", function()
            Common.CreateCheckbox("SAwareness.CDTracker.DrawOnAlly", "Draw On Ally", true)
            Common.CreateCheckbox("SAwareness.CDTracker.DrawOnEnemy", "Draw On Enemy", true)
            Common.CreateDropdown("SAwareness.CDTracker.Appearance", "Tracker Style", 0, { "Bars", "Icons" })
        end)
        
        Menu.NewTree("SAwareness.CDTracker.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.CDTracker.SpellCD", "Spell CD", function()
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.X", "X Offset", 0, -100, 100, 1)
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.Y", "Y Offset", 0, -100, 100, 1)
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.Scale", "Scale", 100, 0, 200, 1)
                if CDTracker.Get("Appearance") == 0 then
                    Common.CreateColorPicker("SAwareness.CDTracker.SpellCD.ReadyColor", "Spell Ready Color", 0x00FF25FF)
                    Common.CreateColorPicker("SAwareness.CDTracker.SpellCD.CDColor", "Spell CD Color", 0xFFE100FF)
                    Common.CreateDropdown("SAwareness.CDTracker.SpellCD.FontPosition", "Font Position", 0, { "Bottom of the bar", "Top of the bar" })
                end
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.FontSize", "Font Size", 14, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.CDTracker.SpellCD.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.CDTracker.SpellCD.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
            Menu.NewTree("SAwareness.CDTracker.SummonerCD", "Summoner Spell CD", function()
                Common.CreateCheckbox("SAwareness.CDTracker.SummonerCD.Enabled", "Draw Summoner Spells", true)
                Common.CreateDropdown("SAwareness.CDTracker.SummonerCD.Position", "Position", 1, { "Left", "Right" })
                Common.CreateSlider("SAwareness.CDTracker.SummonerCD.X", "X Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.SummonerCD.Y", "Y Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.SummonerCD.Scale", "Scale", 100, 0, 200, 1)
                Common.CreateDropdown("SAwareness.CDTracker.SummonerCD.Format", "Format", 1, { "Seconds", "Minutes:Seconds", "Minutes (If < 1 Then Seconds)" })
                Common.CreateSlider("SAwareness.CDTracker.SummonerCD.FontSize", "Font Size", 12, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.CDTracker.SummonerCD.FontColor", "Font Color", 0xFFFFFFFF)
            end)
            Menu.NewTree("SAwareness.CDTracker.Exp", "Experience Bar", function()
                Common.CreateCheckbox("SAwareness.CDTracker.ExpBar.Enabled", "Draw Experience Bar", true)
                Common.CreateSlider("SAwareness.CDTracker.ExpBar.X", "X Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.ExpBar.Y", "Y Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.ExpBar.Scale", "Scale", 100, 0, 200, 1)
                Common.CreateSlider("SAwareness.CDTracker.ExpBar.Thickness", "Thickness", 2, 0, 10, 1)
                Common.CreateColorPicker("SAwareness.CDTracker.ExpBar.BarColor", "Bar Color", 0xFFB600FF)
            end)
            Menu.NewTree("SAwareness.CDTracker.PassiveCD", "Passive CD", function()
                Common.CreateCheckbox("SAwareness.CDTracker.PassiveCD.Enabled", "Draw Passive CD", true)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.X", "X Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.Y", "Y Offset", 0, -500, 500, 1)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.Scale", "Scale", 100, 0, 200, 1)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.CDTracker.PassiveCD.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.CDTracker.PassiveCD.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
        end)
        
        Menu.NewTree("SAwareness.CDTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("CDTracker")
        end)
    end)
end

function CDTracker.Get(value)
	return Menu.Get("SAwareness.CDTracker." .. value, true)
end

function CDTracker.ShouldDraw(hero)
    if hero.IsDead.Value or hero.IsZombie.Value or not hero.IsVisible.Value or not hero.IsOnScreen.Value then
        return false
    end

    if hero.CharName == "Yummi" and not hero.IsTargetable.Value then
        return false
    end

    if hero.IsMe then
        return false --CDTracker.Get("DrawOnMe")
    elseif hero.IsEnemy then
        return CDTracker.Get("DrawOnEnemy")
    else
        return CDTracker.Get("DrawOnAlly")
    end
end

function CDTracker.UpdateExpBar(heroList)
    if not CDTracker.Get("ExpBar.Enabled") then return end    
    
    local spriteOffsetX = 31 - CDTracker.xOffset + CDTracker.Get("ExpBar.X")
    local spriteOffsetY = -3 - CDTracker.yOffset + CDTracker.Get("ExpBar.Y")

    local sprite = CDTracker.Sprites.HP_HUD_4
    local color = CDTracker.Get("ExpBar.BarColor")
    local scale = CDTracker.Get("ExpBar.Scale") / 100  
    local thickness = CDTracker.Get("ExpBar.Thickness")      
    local scaleX, scaleY = (sprite.X * scale), thickness * scale
    
    for _, hero in ipairs(heroList) do
        if hero.ExpPercent then
            sprite:SetScale(scaleX * hero.ExpPercent, scaleY):SetColor(color)
            insert(CDTracker.DrawQueue, function()
                local hpBar = hero.Object.HealthBarScreenPos
                sprite:Draw({ x = hpBar.x + spriteOffsetX, y = hpBar.y + spriteOffsetY })
            end)            
        end
    end
end

function CDTracker.UpdatePassiveCD(heroList)
    if not CDTracker.Get("PassiveCD.Enabled") then return end
    local appearance = CDTracker.Get("Appearance")
    local swapSum = CDTracker.Get("SummonerCD.Position") == 0
    local time = Game.GetTime()
    
    local passiveScale = CDTracker.Get("PassiveCD.Scale") / 100    
    local fontCD = CDTracker.Fonts.CD
    local fontColor = CDTracker.Get("PassiveCD.FontColor")
    local fontSize = CDTracker.Get("PassiveCD.FontSize") * passiveScale
    local rectangleSize = {x = 26 * passiveScale, y = 26 * passiveScale}
    local fontOffsetX = CDTracker.Get("PassiveCD.FontOffsetX")
    local fontOffsetY = CDTracker.Get("PassiveCD.FontOffsetY")        
    local spriteOffsetX = CDTracker.Get("PassiveCD.X") - (appearance == 0 and (26 * passiveScale) or 0) - (27 * passiveScale)
    local spriteOffsetY = CDTracker.Get("PassiveCD.Y") - (appearance == 0 and (25 * passiveScale) or 0) - (appearance == 0 and swapSum and (23 * passiveScale) or 0)

    for _, hero in ipairs(heroList) do
        if hero.Object.PassiveCooldownTotalTime > 0 then            
            local sprite_x = - (45 * passiveScale) + spriteOffsetX
            local sprite_y = - (4 * passiveScale) + spriteOffsetY

            local passiveSprite = CDTracker.Sprites.Passives[hero.CharName]
            passiveSprite:SetScale(passiveSprite.X * passiveScale, passiveSprite.Y * passiveScale)
            insert(CDTracker.DrawQueue, function() 
                local hpBar = hero.Object.HealthBarScreenPos
                hpBar.x = hpBar.x + sprite_x; hpBar.y = hpBar.y + sprite_y;
                passiveSprite:Draw(hpBar) 
                -- Renderer.DrawRectOutline(hpBar, rectangleSize, 0, 2, 0x5A5D5AFF)
            end)           

            local passiveCD = hero.Object.PassiveCooldownEndTime - time
            if passiveCD > 0 then
                local cdSprite = CDTracker.Sprites.Spells.CD
                cdSprite:SetScale(cdSprite.X * passiveScale, cdSprite.Y * passiveScale)
                insert(CDTracker.DrawQueue, function() 
                    local hpBar = hero.Object.HealthBarScreenPos
                    hpBar.x = hpBar.x + sprite_x; hpBar.y = hpBar.y + sprite_y;
                    cdSprite:Draw(hpBar) 
                end)

                local text = format((passiveCD < 1 and "%.1f") or "%d", passiveCD)
                fontCD:SetColor(fontColor):SetSize(fontSize)
                insert(CDTracker.DrawQueue, function() 
                    local hpBar = hero.Object.HealthBarScreenPos
                    local textExtent = fontCD.Font:CalcTextSize(text)
                    local textPos = {
                        x = hpBar.x - (32 * passiveScale) - textExtent.x / 2 + fontOffsetX + spriteOffsetX,
                        y = hpBar.y + (8  * passiveScale) - textExtent.y / 2 + fontOffsetY + spriteOffsetY 
                    }
                    fontCD:Draw(textPos, text) 
                end)
            end
        end
    end
end

function CDTracker.UpdateSpellCD(heroList)
    local appearance = CDTracker.Get("Appearance")
    local time = Game.GetTime()

    local cdScale = CDTracker.Get("SpellCD.Scale") / 100    
    local barXOffset = CDTracker.Get("SpellCD.X")
    local barYOffset = CDTracker.Get("SpellCD.Y")
    local mXOffset = CDTracker.Get("SpellCD.FontOffsetX")
    local mYOffset = CDTracker.Get("SpellCD.FontOffsetY")
    
    local sprite_Ready = CDTracker.Sprites.HP_HUD_1
    local scaleX_Ready = CDTracker.Sprites.HP_HUD_1.X * cdScale
    local scaleY_Ready = CDTracker.Sprites.HP_HUD_1.Y * cdScale
    local color_Ready = CDTracker.Get("SpellCD.ReadyColor")
    
    local sprite_BG = CDTracker.Sprites.HP_HUD_3
    local scaleX_BG, scaleY_BG = sprite_BG.X * cdScale, sprite_BG.Y * cdScale
    
    local sprite_CD = CDTracker.Sprites.HP_HUD_2
    local scaleX_CD, scaleY_CD = sprite_CD.X * cdScale, sprite_CD.Y * cdScale
    local color_CD = CDTracker.Get("SpellCD.CDColor")
    local font_CD = CDTracker.Fonts.CD
    local fontPos_CD = CDTracker.Get("SpellCD.FontPosition") == 1 and 2 + font_CD.Size or 0
    local fontColor_CD = CDTracker.Get("SpellCD.FontColor")
    local fontSize_CD = CDTracker.Get("SpellCD.FontSize") * cdScale

    font_CD:SetColor(fontColor_CD):SetSize(fontSize_CD)
    
    local cdRectangleSize = {x = 26 * cdScale, y = 26 * cdScale}

    for _, hero in ipairs(heroList) do
         
        local swapTable = CDTracker.Offsets[hero.CharName]
        local addOffset = (swapTable and swapTable[2]) or { x = 0, y = 0 }

        for slot=0, 3 do
            local spell = SLib.SpellManager:Get(hero, slot)
            local CD = spell.CooldownExpireTime - time
            local totalCD = (CD <= spell.TotalCooldown and spell.TotalCooldown) or spell.TotalAmmoRechargeTime
            local level = spell.Level

            local offset = (27 * slot) * cdScale
            if appearance == 0 then
                local oX = - (45 * cdScale) + offset + addOffset.x + barXOffset
                local oY = - (4 * cdScale) + addOffset.y + barYOffset
                
                insert(CDTracker.DrawQueue, function() 
                    local hpBar = hero.Object.HealthBarScreenPos
                    local cdPos = { x = hpBar.x + oX, y = hpBar.y + oY }

                    if CD < 0.1 and level > 0 then
                        sprite_Ready:SetScale(scaleX_Ready, scaleY_Ready):SetColor(color_Ready):Draw(cdPos) 
                    else                        
                        sprite_BG:SetScale(scaleX_BG, scaleY_BG):Draw(cdPos) 
                        
                        if level > 0 then
                            sprite_CD:SetScale((scaleX_CD * (1 - CD / totalCD)), scaleY_CD):SetColor(color_CD):Draw(cdPos) 
                            
                            local text = format((CD < 1 and "%.1f") or "%d", CD)
                            local textExtent = font_CD.Font:CalcTextSize(text)
                            local textVector = {
                                x = cdPos.x + (13 * cdScale) - textExtent.x / 2 + mXOffset,
                                y = cdPos.y + (2  * cdScale) + mYOffset - fontPos_CD
                            }    
                            font_CD:Draw(textVector, text) 
                        end
                    end
                end)
            elseif appearance == 1 then
                local oX = - (45 * cdScale) + barXOffset + offset
                local oY = - (4  * cdScale) + barYOffset               

                insert(CDTracker.DrawQueue, function() 
                    local hpBar = hero.Object.HealthBarScreenPos
                    local cdPos = { x = hpBar.x + oX, y = hpBar.y + oY }

                    local spellSprite = CDTracker.Sprites.Spells[hero.CharName][slot]                
                    spellSprite:SetScale(spellSprite.X * cdScale, spellSprite.Y * cdScale):Draw(cdPos)
                    
                    if CD > 0 or level == 0 then   
                        local cdSprite = CDTracker.Sprites.Spells.CD
                        cdSprite:SetScale(cdSprite.X * cdScale, cdSprite.Y * cdScale):Draw(cdPos) 
                    end

                    -- Renderer.DrawRectOutline(cdPos, cdRectangleSize, 0, 2, 0x5A5D5AFF)

                    if CD >= 0.1 then
                        local text = format((CD < 1 and "%.1f") or "%d", CD)
                        local textExtent = font_CD.Font:CalcTextSize(text)
                        local textVector = {
                            x = cdPos.x + (13 * cdScale) - textExtent.x / 2  + mXOffset,
                            y = cdPos.y + (12 * cdScale) - textExtent.y / 2  + mYOffset
                        }
                        font_CD:Draw(textVector, text)
                    end
                end)
            end
        end
    end
end

function CDTracker.UpdateSummonerCD(heroList)
    if not CDTracker.Get("PassiveCD.Enabled") then return end
    local appearance = CDTracker.Get("Appearance")
    local time = Game.GetTime()

    local sumScale = CDTracker.Get("SummonerCD.Scale") / 100  
    local sumXOffset = CDTracker.Get("SummonerCD.X")
    local sumYOffset = CDTracker.Get("SummonerCD.Y")    

    local SummonerCD = {                            
        Format = CDTracker.Get("SummonerCD.Format"),
        FontColor = CDTracker.Get("SummonerCD.FontColor"),
        FontSize  = CDTracker.Get("SummonerCD.FontSize") * sumScale,

        Font = CDTracker.Fonts.SummonerCD,
        FontPos = CDTracker.Get("SummonerCD.FontPosition") == 1 and 2 + CDTracker.Fonts.SummonerCD.Size or 0
    }
    SummonerCD.Font:SetColor(SummonerCD.FontColor):SetSize(SummonerCD.FontSize)

    local sumRectangleSize = {x = 23 * sumScale, y = 23 * sumScale}
    local swapSumMenu = CDTracker.Get("SummonerCD.Position") == 0

    for _, hero in ipairs(heroList) do
        
        local swapTable = CDTracker.Offsets[hero.CharName]
        local swapSums  = (swapTable and swapTable[1]) or swapSumMenu

        for slot=4, 5 do
            if CDTracker.Get("SummonerCD.Enabled") then
                local offset = (26 * sumScale) * slot
                local spell = SLib.SpellManager:Get(hero, slot)                        
                local remainingCD = spell.CooldownExpireTime - time                        
                local cdSprite = CDTracker.Sprites.Summoners.CD
                local sumSprite = CDTracker.Sprites.Summoners[spell.Name] 

                local sX, oX, oY
                if appearance == 0 then
                    sX = swapSums and (187 * sumScale) or 0
                    oX =   (37 * sumScale) + offset - (CDTracker.xOffset * sumScale) - sX + sumXOffset
                    oY = - (2 * sumScale) - (CDTracker.yOffset * sumScale) + sumYOffset
                elseif appearance == 1 then
                    sX = swapSums and (159 * sumScale) or 0
                    oX =   (141 * sumScale) - (CDTracker.xOffset * sumScale) - sX + sumXOffset
                    oY = - (106 * sumScale) - (CDTracker.yOffset * sumScale) + sumYOffset + offset
                end

                local text 
                if remainingCD > 0 then
                    text = SummonerCD.Format == 0 and format("%d", floor(remainingCD)) 
                        or SummonerCD.Format == 1 and Common.DecToMin(remainingCD) 
                        or Common.DecToMin3(remainingCD)    
                end 
                
                insert(CDTracker.DrawQueue, function()
                    local hpBar = hero.Object.HealthBarScreenPos
                    local spritePos = {x = hpBar.x + oX, y = hpBar.y + oY}
    
                    if sumSprite then
                        sumSprite:SetScale(sumSprite.X * sumScale, sumSprite.Y * sumScale):Draw(spritePos)
                    end                        
                    if remainingCD > 0 then                            
                        cdSprite:SetScale(cdSprite.X * sumScale, cdSprite.Y * sumScale):Draw(spritePos)
                    end
    
                    -- Renderer.DrawRectOutline(spritePos, sumRectangleSize, 0, 2, 0x5A5D5AFF)
    
                    if remainingCD > 0 then
                        local tmp_x = hpBar.x - (27.5 * sumScale) + sumXOffset - sX
                        local tmp_y = hpBar.y - (16   * sumScale) + sumYOffset
    
                        if appearance == 0 then
                            tmp_x = tmp_x + offset 
                        elseif appearance == 1 then
                            tmp_x = tmp_x + (104 * sumScale)
                            tmp_y = tmp_y - (104 * sumScale) + offset
                        end
                        local textExtent = SummonerCD.Font.Font:CalcTextSize(text)
                        local textVector= { x = tmp_x - textExtent.x / 2, y = tmp_y - textExtent.y / 2}
                        SummonerCD.Font:Draw(textVector, text) 
                    end
                end)
            end
        end
    end
end

function CDTracker.UpdateDrawings()
    local heroesToDraw = {}
    for handle, hero in pairs(SLib.Heroes) do
        if CDTracker.ShouldDraw(hero) then
            heroesToDraw[#heroesToDraw+1] = hero         
        end
    end

    CDTracker.UpdateExpBar(heroesToDraw)
    CDTracker.UpdatePassiveCD(heroesToDraw)
    CDTracker.UpdateSpellCD(heroesToDraw)
    CDTracker.UpdateSummonerCD(heroesToDraw)
end

function CDTracker.OnTick()
    local gameTime = Game.GetTime()
    if gameTime - CDTracker.LastUpdate < 0.1 then return end
    CDTracker.LastUpdate = gameTime

    CDTracker.DrawQueue = {}
    CDTracker.UpdateDrawings()
end

function CDTracker.OnDraw()
    if not CDTracker.Get("Enabled") then return end

    for _, f in ipairs(CDTracker.DrawQueue) do
        f()
    end    
end

--#endregion

--[[
    ██████  ███████  ██████  █████  ██      ██          ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██   ██ ██      ██      ██   ██ ██      ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██████  █████   ██      ███████ ██      ██             ██    ██████  ███████ ██      █████   █████   ██████  
    ██   ██ ██      ██      ██   ██ ██      ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██   ██ ███████  ██████ ██   ██ ███████ ███████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                          
]]

--#region Recall Tracker

local RecallTracker = Script.Modules.RecallTracker

RecallTracker.X = 0
RecallTracker.Y = 0
RecallTracker.Rect = {}
RecallTracker.Data = {}
RecallTracker.Fonts = {}
RecallTracker.MoveOffset = {}
RecallTracker.Time = {
    ["recall"] = 8,
    ["SuperRecall"] = 4,
    ["SummonerTeleport"] = 4,
    ["shenrchannelmanager"] = 3
}

function RecallTracker.Initialize()
    RecallTracker.LoadFonts()

    for handle, hero in pairs(SLib.Heroes) do
        RecallTracker.Data[hero.Handle] = {
            RecallTime = 0,
            Unit = SLib.Heroes[handle],
            StartTime = 0,
            Finish = nil,
            Status = "None",
            InterruptTime = 0,
            FinishTime = 0,
        }
    end
end

function RecallTracker.LoadFonts()
    RecallTracker["Fonts"]["Main"] = SLib.CreateFont("Bahnschrift.ttf", 16, 0xFFFFFFFF)
end

function RecallTracker.LoadConfig()
    Menu.NewTree("SAwareness.RecallTracker", "Recall Tracker", function()
        Common.CreateCheckbox("SAwareness.RecallTracker.Enabled", "Enabled", true)

        Menu.NewTree("SAwareness.RecallTracker.PositionSettings", "Position Settings", function()
            Common.CreateSlider("SAwareness.RecallTracker.X", "X", 500, 0, Resolution.x, 1)
            Common.CreateSlider("SAwareness.RecallTracker.Y", "Y", 100, 0, Resolution.y, 1)
            Common.CreateSlider("SAwareness.RecallTracker.Height", "Height", 400, 0, Resolution.x, 1)
            Common.CreateSlider("SAwareness.RecallTracker.Width", "Width", 20, 0, Resolution.x, 1)
            Common.CreateCheckbox("SAwareness.RecallTracker.Drag", "Allow To Drag By SHIFT + LMB", true)
        end)

        Menu.NewTree("SAwareness.RecallTracker.Bar", "Recall Bar Settings", function()
            Common.CreateColorPicker("SAwareness.RecallTracker.Bar.Color", "Bar Color", 0x000000B4)
            Common.CreateColorPicker("SAwareness.RecallTracker.Bar.BorderColor", "Border Color", 0x796C43FF)
            Common.CreateColorPicker("SAwareness.RecallTracker.Bar.RecallColor", "Active Recall Color", 0x82D2E6B4)
            Common.CreateColorPicker("SAwareness.RecallTracker.Bar.InterruptedRecallColor", "Interrupted Color", 0xFF373750)
            Common.CreateSlider("SAwareness.RecallTracker.Bar.FontSize", "Font Size", 16, 0, 50, 1)
            Common.CreateColorPicker("SAwareness.RecallTracker.Bar.FontColor", "Font Color", 0xFFFFFFFF)
        end)

        Menu.NewTree("SAwareness.RecallTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("RecallTracker")
        end)
    end)
end

function RecallTracker.Get(value)
	return Menu.Get("SAwareness.RecallTracker." .. value, true)
end

function RecallTracker.OnDraw()
    if not RecallTracker.Get("Enabled") then return end

    RecallTracker.X = RecallTracker.Get("X")
    RecallTracker.Y = RecallTracker.Get("Y")

    local x = RecallTracker.X
    local y = RecallTracker.Y
    local h = RecallTracker.Get("Height")
    local w = RecallTracker.Get("Width")
    local recallCount = 0
    local time = Game.GetTime()
    local rBarColor = RecallTracker.Get("Bar.Color") 
    local borderColor = RecallTracker.Get("Bar.BorderColor")

    for i, v in pairs(RecallTracker.Data) do
        local unit = v.Unit
        if unit and not unit.IsDead and SLib.Heroes[unit.Handle] then
            local data = SLib.Heroes[unit.Handle]
            local deadCheck = data.TimeSinceLastDeath + 5 < time
            if deadCheck then
                if v.Status == "Started" or (v.InterruptTime + 2 > time or v.FinishTime + 2 > time) then
                    if recallCount == 0 then
                        Common.DrawRectOutline({x, y, h, w}, 3, 0x000000FF)
                        Common.DrawFilledRect({x, y, h, w}, borderColor)
                        Common.DrawFilledRect({x + 3, y + 3, h - 6, w - 6}, rBarColor)
                        Common.DrawRectOutline({x + 3, y + 3, h - 6, w - 6}, 3, 0x000000FF)
                    end
                    recallCount = recallCount + 1
                end
                if v.Status == "Started" then
                    local recallTime = v.StartTime + v.RecallTime - time
                    if recallTime > 0 then
                        local text = v.Unit.CharName .. " (" .. Common.Round(recallTime, 1, true) .. "s)"
                        local len = string.len(text)
                        local perNeed = (100 / v.RecallTime * recallTime) / 100
                        local unitColor = 0xFFFFFFFF
                        local barColor = RecallTracker.Get("Bar.RecallColor")
                        if v.RecallTime == 4 then barColor = 0xAB77FF78 end
                        
                        Common.DrawFilledRect({x + 3, y + 3, (h - 6) * perNeed, w - 6}, barColor)
                        Common.DrawFilledRect({x + 3 + (h - 6) * perNeed, y - (ScreenPosPct.y * 1) * recallCount, 2, w + (ScreenPosPct.y * 1) * recallCount - 3}, unitColor)
                        
                        local font = RecallTracker.Fonts.Main
                        local textExtent = font.Font:CalcTextSize(tostring(text))
                        local textVector = Vector(x + (h * perNeed) - (textExtent.x / 2), y - 15 - (textExtent.y * recallCount))

                        font
                            :SetColor(RecallTracker.Get("Bar.FontColor"))
                            :SetSize(RecallTracker.Get("Bar.FontSize"))
                            :Draw(textVector, text)
                    end
                elseif v.Status == "Interrupted" then
                    local barColor = RecallTracker.Get("Bar.InterruptedRecallColor")
                    if v.InterruptTime + 2 > time then
                        local recallTime = v.StartTime + v.RecallTime - v.InterruptTime
                        if recallTime > 0 then
                            local text = v.Unit.CharName .. " (" .. Common.Round(recallTime, 1, true) .. "s)"
                            local len = string.len(text)
                            local perNeed = (100 / v.RecallTime * recallTime) / 100
                            
                            Common.DrawFilledRect({x + 3, y + 3, (h - 6) * perNeed, w - 6}, barColor)
                            Common.DrawFilledRect({x + 3 + (h - 6) * perNeed, y - (ScreenPosPct.y * 1) * recallCount, 2, w + (ScreenPosPct.y * 1) * recallCount - 3}, 0xFF3737F0)

                            local font = RecallTracker.Fonts.Main
                            local textExtent = font.Font:CalcTextSize(tostring(text))
                            local textVector = Vector(x + (h * perNeed) - (textExtent.x / 2), y - 15 - (textExtent.y * recallCount))

                            font
                                :SetColor(0xFF3737FF)
                                :SetSize(RecallTracker.Get("Bar.FontSize"))
                                :Draw(textVector, text)
                        end
                    end
                else
                    local barColor = RecallTracker.Get("Bar.InterruptedRecallColor")
                    if v.FinishTime + 2 > time then
                        local text = v.Unit.CharName
                        local recallTime = v.StartTime + v.RecallTime - v.FinishTime

                        Common.DrawFilledRect({x + 3, y + 3, 0, w - 6}, barColor)
                        Common.DrawFilledRect({x + 3, y - (ScreenPosPct.y * 1) * recallCount, 2, w + (ScreenPosPct.y * 1) * recallCount - 3 }, 0x0FBBFFF0)

                        local font = RecallTracker.Fonts.Main
                        local textExtent = font.Font:CalcTextSize(tostring(text))
                        local textVector = Vector(x - (textExtent.x / 2), y - 15 - (textExtent.y * recallCount))

                        font
                            :SetColor(0x0FBBFFFF)
                            :SetSize(RecallTracker.Get("Bar.FontSize"))
                            :Draw(textVector, text)
                    end
                end
                if Script.Modules.BaseUlt then
                    local BaseUlt = Script.Modules.BaseUlt
                    if BaseUlt.Active and BaseUlt.ShouldCast() then
                        local data = BaseUlt.Data
                        if data[v.Unit.Handle] and data[v.Unit.Handle].state == true then
                            local baseUltNeed = (100 / v.RecallTime * data[v.Unit.Handle].time) / 100
                            local textVector = {x + 3 + (h - 6) * baseUltNeed, y, 2, w}
                            Common.DrawFilledRect(textVector, 0xFF3737FF)
                            
                            local font = RecallTracker.Fonts.Main

                            font
                                :SetColor(0xFF3737FF)
                                :SetSize(RecallTracker.Get("Bar.FontSize"))
                                :Draw(Vector(x + 3 + (h - 6) * baseUltNeed, y - 20), "R")
                        end
                    end
                end
            end
        end
    end
    if Common.ShiftPressed and RecallTracker.Get("Drag") then
        local cursorPos = Renderer.GetCursorPos()
        RecallTracker.Rect = {
            x = RecallTracker.X - 5,
            y = RecallTracker.Y - 5,
            z = h,
            w = w
        }
        if recallCount == 0 then
            local text = "Recall Tracker Bar Position"
            if not RecallTracker.__BarTextSize then
                local textExtent = Renderer.CalcTextSize(text)
                RecallTracker.__BarTextSize = {x = textExtent.x/2, y = textExtent.y/2}
            end
            
            Common.DrawRectOutline({x, y, h, w}, 3, 0x000000FF)
            Common.DrawFilledRect({x, y, h, w}, borderColor)
            Common.DrawFilledRect({x + 3, y + 3, h - 6, w - 6}, rBarColor)
            Common.DrawRectOutline({x + 3, y + 3, h - 6, w - 6}, 3, 0x000000FF)
            Renderer.DrawText(Vector(x + (h / 2 - (RecallTracker.__BarTextSize.x)),y + (w / 2 - (RecallTracker.__BarTextSize.y))), nil, text, 0xFFFFFFFF)
        end

        local rect = RecallTracker.Rect
        if not RecallTracker.MoveOffset and rect and Common.CursorIsUnder(rect.x, rect.y, rect.z, rect.w) and Common.LMBPressed then
            RecallTracker.MoveOffset = {
                x = rect.x - cursorPos.x + 5,
                y = rect.y - cursorPos.y + 5
            }
        elseif RecallTracker.MoveOffset and not Common.LMBPressed then
            RecallTracker.MoveOffset = nil
        end

        if RecallTracker.MoveOffset and rect and rect.x and rect.y then
            rect.x = RecallTracker.MoveOffset.x + cursorPos.x
            rect.x = rect.x > 0 and rect.x or 0
            rect.x = rect.x < Resolution.x - rect.z and rect.x or Resolution.x - rect.z

            rect.y = RecallTracker.MoveOffset.y + cursorPos.y
            rect.y = rect.y > 0 and rect.y or 0
            rect.y = rect.y < (Resolution.y - rect.w + 6) and rect.y or (Resolution.y - rect.w + 6)

            if Common.LMBPressed then
                RecallTracker.X = rect.x
                RecallTracker.Y = rect.y
                Menu.Set("SAwareness.RecallTracker.X", RecallTracker.X, true)
                Menu.Set("SAwareness.RecallTracker.Y", RecallTracker.Y, true)
            end
        end
    end
end

function RecallTracker.OnTeleport(unit, name, duration_secs, status)
    if unit and unit.IsEnemy then
        if RecallTracker.Time[name] and RecallTracker.Data[unit.Handle] and SLib.Heroes[unit.Handle] then
            local data = SLib.Heroes[unit.Handle]
            RecallTracker.Data[unit.Handle].Unit = unit
            RecallTracker.Data[unit.Handle].Status = status
            RecallTracker.Data[unit.Handle].Duration = duration_secs
            if status == "Started" then
                RecallTracker.Data[unit.Handle].StartTime = Game.GetTime()
                RecallTracker.Data[unit.Handle].RecallTime = RecallTracker.Time[name]
            elseif status == "Interrupted" then
                RecallTracker.Data[unit.Handle].InterruptTime = Game.GetTime()
            elseif status == "Finished" and data.TimeSinceLastDeath + 5 < Game.GetTime() then
                RecallTracker.Data[unit.Handle].FinishTime = Game.GetTime()
            end
        end
    end
end

--#endregion

--[[
    ██████   █████  ███████ ███████ ██    ██ ██      ████████ 
    ██   ██ ██   ██ ██      ██      ██    ██ ██         ██    
    ██████  ███████ ███████ █████   ██    ██ ██         ██    
    ██   ██ ██   ██      ██ ██      ██    ██ ██         ██    
    ██████  ██   ██ ███████ ███████  ██████  ███████    ██                                                    
]]

--#region BaseUlt

local BaseUlt = Script.Modules.BaseUlt

BaseUlt.Active = false
BaseUlt.Data = {}
BaseUlt.SupportedChampions = {
    ["Ashe"] = true,
    ["Draven"] = true,
    ["Ezreal"] = true,
    ["Jinx"] = true,
    ["Karthus"] = true,
    ["Senna"] = true
}
BaseUlt.SpellData = {
    ["Ashe"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 0.25
        end,
        ---@type fun():number
        ["GetSpeed"] = function()
            return 1600
        end,
        ---@type fun(unit: GameObject, endPosition: Vector):number
        ["GetDamage"] = function(unit, endPosition)
            local collision = CollisionLib.SearchHeroes(Player.Position, endPosition, 260, 1700, 0.25)

            if collision.Result then
                return 0
            end

            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    },
    ["Draven"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 0.25
        end,
        ---@type fun():number
        ["GetSpeed"] = function()
            return 2000
        end,
        ---@type fun(unit: GameObject):number
        ["GetDamage"] = function(unit)
            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    },
    ["Ezreal"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 1
        end,
        ---@type fun():number
        ["GetSpeed"] = function()
            return 2000
        end,
        ---@type fun(unit: GameObject):number
        ["GetDamage"] = function(unit)
            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    },
    ["Jinx"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 0.65
        end,
        ---@type fun(endPosition: Vector):number
        ["GetSpeed"] = function(endPosition)
            local distance = Player:EdgeDistance(endPosition)
            return distance > 1300 and (1300 * 1700 + ((distance - 1300) * 2200)) / distance or 1700
        end,
        ---@type fun(unit: GameObject, endPosition: Vector):number
        ["GetDamage"] = function(unit, endPosition)
            local collision = CollisionLib.SearchHeroes(Player.Position, endPosition, 280, 1700, 0.65)

            if collision.Result then
                return 0
            end

            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    },
    ["Karthus"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 3
        end,
        ---@type fun():number
        ["GetSpeed"] = function()
            return 20000
        end,
        ---@type fun(unit: GameObject):number
        ["GetDamage"] = function(unit)
            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    },
    ["Senna"] = {
        ---@type fun():number
        ["GetDelay"] = function()
            return 1
        end,
        ---@type fun():number
        ["GetSpeed"] = function()
            return 20000
        end,
        ---@type fun(unit: GameObject):number
        ["GetDamage"] = function(unit)
            return DamageLib.GetSpellDamage(Player, unit, _R)
        end
    }
}

function BaseUlt.Initialize()
end

function BaseUlt.LoadConfig()
    Menu.NewTree("SAwareness.BaseUlt", "BaseUlt", function()
        Common.CreateCheckbox("SAwareness.BaseUlt.Enabled", "Enabled", true)
        Common.CreateCheckbox("SAwareness.BaseUlt.Combo", "Don't use in combo mode", false)
        Menu.Text("", true)
        Menu.Text("[Information]")
        Menu.Text("Supported Heroes: Ashe, Draven, Ezreal, Jinx, Karthus, Senna")
    end)
end

function BaseUlt.Get(value)
	return Menu.Get("SAwareness.BaseUlt." .. value, true)
end

function BaseUlt.ShouldCast()
    if BaseUlt.Get("Combo") and Orbwalker.GetMode() == "Combo" then
        return false
    end
    return BaseUlt.SpellData[Player.CharName] and Player:GetSpellState(3) == 0 and BaseUlt.Get("Enabled")
end

function BaseUlt.OnHighPriority(n)
    if not BaseUlt.ShouldCast() then return end

    if not BaseUlt.Active then
        BaseUlt.Active = true
    end

    local time = Game.GetTime()
    local data = BaseUlt.SpellData[Player.CharName]
    local basePosition = Common.GetBasePosition()
    local travelTime = Common.CalculateTravelTime(data.GetDelay(), data.GetSpeed(basePosition), basePosition)

    for handle, recallData in pairs(RecallTracker.Data) do
        local unit = recallData.Unit
        BaseUlt.Data[unit.Handle] = {state = false, time = 0}
        if recallData.Status and recallData.Status == "Started" then
            local recallTime = recallData.StartTime + recallData.Duration - time
            local damage = data.GetDamage(unit, basePosition)
            if not unit.IsDead and unit.Health > 0 and damage > unit.Health then
                if recallTime > travelTime then
                    BaseUlt.Data[unit.Handle] = {state = true, time = travelTime}
                end
                if recallTime > travelTime and recallTime < travelTime + 0.1 then
                    return Input.Cast(_R, basePosition)
                end
            end
        end
    end
end

--#endregion

--[[
    ██████   █████  ████████ ██   ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██   ██ ██   ██    ██    ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██████  ███████    ██    ███████        ██    ██████  ███████ ██      █████   █████   ██████  
    ██      ██   ██    ██    ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██      ██   ██    ██    ██   ██        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                              
]]

--#region Path Tracker

local PathTracker = Script.Modules.PathTracker

PathTracker.Data = {}
PathTracker.Scale = 1
PathTracker.Fonts = {}
PathTracker.Sprites = {}
PathTracker.ToDraw = {}

function PathTracker.Initialize()
    PathTracker.LoadSprites()
    PathTracker.LoadFonts()

    PathTracker.DrawQueue = {}
    PathTracker.LastUpdate = 0
end

function PathTracker.LoadSprites()
    for handle, hero in pairs(ObjectManager.Get("all", "heroes")) do
        local charName = hero.CharName
        PathTracker["Sprites"][charName] = SLib.CreateSprite("Champions\\" .. charName .. ".png", 35, 35)
    end
end

function PathTracker.LoadFonts()
    PathTracker["Fonts"]["Main"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
end

function PathTracker.LoadConfig()
    Menu.NewTree("SAwareness.PathTracker", "Path Tracker", function()
        Common.CreateCheckbox("SAwareness.PathTracker.Enabled", "Enabled", true)
        
        Menu.NewTree("SAwareness.PathTracker.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.PathTracker.ChampionIcon", "Champion Icon", function()
                Common.CreateSlider("SAwareness.PathTracker.ChampionIcon.Scale", "Sprite Scale", 100, 0, 200, 1)
            end)
            Menu.NewTree("SAwareness.PathTracker.IconBorder", "Icon Border", function()
                Common.CreateCheckbox("SAwareness.PathTracker.IconBorder.Enabled", "Draw Icon Border", true)
                Common.CreateColorPicker("SAwareness.PathTracker.IconBorder.Color", "Color", 0xC3C3C3A5)
                Common.CreateSlider("SAwareness.PathTracker.IconBorder.Thickness", "Thickness", 3, 1, 10, 1)
            end)
            Menu.NewTree("SAwareness.PathTracker.ETA", "ETA Timer", function()
                Common.CreateCheckbox("SAwareness.PathTracker.ETA.Enabled", "Draw ETA", true)
                Common.CreateSlider("SAwareness.PathTracker.ETA.FontSize", "Font Size", 14, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.PathTracker.ETA.FontColor", "Font Color", 0xFFFFFFFF)
            end)
            Menu.NewTree("SAwareness.PathTracker.Line", "Path Line", function()
                Common.CreateColorPicker("SAwareness.PathTracker.Line.Color", "Color", 0xC3C3C3A5)
                Common.CreateSlider("SAwareness.PathTracker.Line.Thickness", "Thickness", 3, 1, 10, 1)
            end)
        end)

        Menu.NewTree("SAwareness.PathTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("PathTracker")
        end)
    end)
end

function PathTracker.Get(value)
	return Menu.Get("SAwareness.PathTracker." .. value, true)
end

function PathTracker.GetETA(hero, waypoints, curWP)
    local res = 0
    local startPos, moveSpeed = hero.Position, hero.MoveSpeed  
    for i=(curWP or 1), (#waypoints-1) do
        local nextPos = waypoints[i+1]
        res = res + startPos:Distance(nextPos)/moveSpeed
        startPos = nextPos
    end
    return res
end

function PathTracker.UpdateDrawings()
    local gameTime = Game.GetTime()
    if gameTime - PathTracker.LastUpdate < 0.2 then return end
    PathTracker.LastUpdate = gameTime

    PathTracker.DrawQueue = {}

    local scale = PathTracker.Scale
    local lineColor = PathTracker.Get("Line.Color")
    local lineThickness = PathTracker.Get("Line.Thickness")    

    local borderDraw = PathTracker.Get("IconBorder.Enabled")
    local borderColor = PathTracker.Get("IconBorder.Color")
    local borderThickness = PathTracker.Get("IconBorder.Thickness")

    local etaDraw = PathTracker.Get("ETA.Enabled")

    for handle, data in pairs(PathTracker.Data) do
        local hero = data.Hero
        local waypoints = data.Waypoints

        local heroOnScreen = hero.IsOnScreen
        local endOnScreen = Renderer.IsOnScreen(data.EndPos)

        if hero.IsVisible and (heroOnScreen or endOnScreen) then            
            local curWP, maxWP = hero.Pathing.CurrentWaypoint, (#waypoints-1)
            for i=curWP, maxWP do
                local nextPos = waypoints[i+1]
                if i == curWP then
                    insert(PathTracker.DrawQueue, function() Renderer.DrawLine3D(hero.Position, nextPos, lineThickness, lineColor) end)
                else
                    insert(PathTracker.DrawQueue, function() Renderer.DrawLine3D(waypoints[i], nextPos, lineThickness, lineColor) end)
                end
            end

            if endOnScreen then
                local sprite = PathTracker.Sprites[hero.CharName]
                if sprite then
                    sprite:SetScale(sprite.X * scale, sprite.Y * scale)
                    insert(PathTracker.DrawQueue, function() 
                        sprite:Draw(data.EndPos:ToScreen(), nil, true) 
                    end)
                end
                
                -- //TODO: Re-enable after we have better performance on 2D Circles
                -- if borderDraw then
                --     insert(PathTracker.DrawQueue, function() Renderer.DrawCircle(data.EndPos:ToScreen(), 17 * scale, borderThickness, borderColor) end)
                -- end

                if etaDraw then
                    local font, text = PathTracker.Fonts.Main, format("%.1f", data.ETA)
                    local offX = font.Font:CalcTextSize(text, true, "0.0").x/2
                    
                    insert(PathTracker.DrawQueue, function()
                        local endPosScreen = data.EndPos:ToScreen()
                        local textVector = {x = endPosScreen.x - offX, y = endPosScreen.y + (16 * scale)}
                        font:Draw(textVector, format("%.1f", data.ETA)) 
                    end)
                end
            end
        end
    end
end

function PathTracker.OnTick()
    if not PathTracker.Get("Enabled") then return end

    PathTracker.Scale = PathTracker.Get("ChampionIcon.Scale") / 100

    local font = PathTracker.Fonts.Main
    font:SetColor(PathTracker.Get("ETA.FontColor"))
    font:SetSize(PathTracker.Get("ETA.FontSize") * PathTracker.Scale)

    local time = Game.GetTime()
    for handle, data in pairs(PathTracker.Data) do
        local hero = data.Hero
        if hero.IsDead or (time - data.StartTime > 0.5 and not hero.IsMoving) then
            PathTracker.Data[handle] = nil
        elseif hero.IsVisible then 
            data.ETA = PathTracker.GetETA(hero, data.Waypoints, hero.Pathing.CurrentWaypoint)
        end
    end

    PathTracker.UpdateDrawings()
end

function PathTracker.OnDraw()
    if not PathTracker.Get("Enabled") then return end

    for _, f in ipairs(PathTracker.DrawQueue) do
        f()
    end
end

---@param unit AIHeroClient
---@param path Pathing
function PathTracker.OnNewPath(unit, path)
    if not (unit.IsHero and unit.IsEnemy) then return end
    
    if path.WaypointCount > 1 then
        local waypoints = path.Waypoints 
        PathTracker.Data[unit.Handle] = {
            Hero = unit,
            Waypoints = waypoints,
            ETA = PathTracker.GetETA(unit, waypoints, path.CurrentWaypoint),
            StartTime = Game.GetTime(),
            EndPos = path.EndPos
        }
    end
end

--#endregion

--[[
    ███    ███ ██  █████      ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ████  ████ ██ ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██ ████ ██ ██ ███████        ██    ██████  ███████ ██      █████   █████   ██████  
    ██  ██  ██ ██ ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██      ██ ██ ██   ██        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                             
]]

--#region MIA Tracker

local MIATracker = Script.Modules.MIATracker

MIATracker.Fonts = {}
MIATracker.Data = {}
MIATracker.TickCount = 0
MIATracker.AlphaR = 0
MIATracker.Scale = 1
MIATracker.WorldScale = 1

MIATracker.Sprites = {
    ["Main"] = nil,
    ["Recall"] = nil,
    ["Champions"] = {
        ["World"] = {},
        ["Minimap"] = {},
    },
    ["Elements"] = {},
}

function MIATracker.Initialize()
    MIATracker.LoadSprites()
    MIATracker.LoadFonts()

    MIATracker.DrawQueue = {}
    MIATracker.LastUpdate = 0

    for handle, hero in pairs(SLib.Heroes) do
        MIATracker.Data[hero.Handle] = {
            Hero = SLib.Heroes[handle],
            Position = hero.Object.Position,
            Time = Game.GetTime(),
            IsVisible = false
        }
    end
end

function MIATracker.LoadSprites()
    MIATracker["Sprites"]["Main"] = SLib.CreateSprite("HUD\\MIA_HUD.png", 69, 82)
    MIATracker["Sprites"]["Recall"] = SLib.CreateSprite("HUD\\MIA_HUD_RECALL.png", 69, 82)

    for handle, hero in pairs(SLib.Heroes) do
        local charName = hero.CharName
        MIATracker["Sprites"]["Champions"]["World"][charName] = SLib.CreateSprite("Champions\\" .. charName .. ".png", 60, 60):SetColor(0xFFFFFF7A)
        MIATracker["Sprites"]["Champions"]["Minimap"][charName] = SLib.CreateSprite("Champions\\" .. charName .. ".png", 25, 25)

        MIATracker["Sprites"]["Elements"][charName] = {}
        MIATracker["Sprites"]["Elements"][charName]["HP"] = SLib.CreateSprite("HUD\\WB.png", 53, 10):SetColor(0x25882EFF)
        MIATracker["Sprites"]["Elements"][charName]["MP"] = SLib.CreateSprite("HUD\\WB.png", 53, 10):SetColor(0x3A95b9FF)
        MIATracker["Sprites"]["Elements"][charName]["C1"] = SLib.CreateSprite("HUD\\WC2.png", 26, 26)
        MIATracker["Sprites"]["Elements"][charName]["C2"] = SLib.CreateSprite("HUD\\WC2.png", 26, 26)
    end
end

function MIATracker.LoadFonts()
    MIATracker["Fonts"]["Minimap"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
    MIATracker["Fonts"]["World"] = SLib.CreateFont("Bahnschrift.ttf", 30, 0xFFFFFFFF)
end

function MIATracker.LoadConfig()
    Menu.NewTree("SAwareness.MIATracker", "MIA Tracker", function()
        Common.CreateCheckbox("SAwareness.MIATracker.Enabled", "Enabled", true)
        
        Menu.NewTree("SAwareness.MIATracker.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.MIATracker.Minimap", "MIA HUD [Minimap]", function()
                Common.CreateSlider("SAwareness.MIATracker.Minimap.X", "X Offset", 0, -100, 100, 1)
                Common.CreateSlider("SAwareness.MIATracker.Minimap.Y", "Y Offset", 0, -100, 100, 1)
                Common.CreateSlider("SAwareness.MIATracker.Minimap.Scale", "Scale", 100, 0, 200, 1)
                Common.CreateSlider("SAwareness.MIATracker.Minimap.Alpha", "Sprite Transparency", 255, 0, 255, 1)
                Common.CreateColorPicker("SAwareness.MIATracker.Minimap.BorderColor", "Border Color", 0xFFF800FF)
                Menu.Text("", true)
                Common.CreateCheckbox("SAwareness.MIATracker.Minimap.DrawTimer", "Draw MIA Timer", true)
                if MIATracker.Get("Minimap.DrawTimer") then
                    Common.CreateCheckbox("SAwareness.MIATracker.Minimap.DrawRect", "Draw Semi-transparent Rectangle Behing Font", true)
                    Common.CreateSlider("SAwareness.MIATracker.Minimap.FontSize", "Font Size", 16, 0, 50, 1)
                    Common.CreateColorPicker("SAwareness.MIATracker.Minimap.FontColor", "Font Color", 0xFFFFFFFF)
                end
            end)
            Menu.NewTree("SAwareness.MIATracker.MovementCircle", "MIA Movement Circle [Minimap]", function()
                Common.CreateCheckbox("SAwareness.MIATracker.MovementCircle.Enabled", "Draw Movement Circle [Temporarily Disabled] ", true)
                if MIATracker.Get("MovementCircle.Enabled") then
                    Common.CreateSlider("SAwareness.MIATracker.MovementCircle.Dist", "Travel Distance", 9000, 0, 15000, 1)
                    Common.CreateColorPicker("SAwareness.MIATracker.MovementCircle.Color", "Circle Color", 0xFFFC008C)
                    Common.CreateSlider("SAwareness.MIATracker.MovementCircle.Thickness", "Circle Thickness", 1, 1, 10, 1)
                end
            end)
            Menu.NewTree("SAwareness.MIATracker.World", "MIA HUD [World]", function()
                Common.CreateCheckbox("SAwareness.MIATracker.World.Enabled", "Enabled", true)
                Common.CreateCheckbox("SAwareness.MIATracker.World.FoW", "Track In FoW", true)
                Common.CreateSlider("SAwareness.MIATracker.World.Scale", "Scale", 70, 0, 200, 1)
                Common.CreateSlider("SAwareness.MIATracker.World.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.MIATracker.World.FontColor", "Font Color", 0xFFFFFFFF)
            end)
        end)

        Menu.NewTree("SAwareness.MIATracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("MIATracker")
        end)
    end)
end

function MIATracker.Get(value)
	return Menu.Get("SAwareness.MIATracker." .. value, true)
end

function MIATracker.UpdateDrawings()
    if not MIATracker.Get("Enabled") then return end

    local gameTime = Game.GetTime()
    if gameTime - MIATracker.LastUpdate < 0.05 then return end
    MIATracker.LastUpdate = gameTime

    MIATracker.DrawQueue = {}

    local mmDrawTimer = MIATracker.Get("Minimap.DrawTimer")
    local miaScale = MIATracker.Scale

    local worldEnabled = MIATracker.Get("World.Enabled")
    local fowEnabled = MIATracker.Get("World.FoW")
    local worldScale = MIATracker.WorldScale

    local hud_sprite = MIATracker.Sprites.Main
    hud_sprite:SetScale(hud_sprite.X * worldScale, hud_sprite.Y * worldScale)    

    local recall_sprite = MIATracker.Sprites.Recall
    recall_sprite:SetScale(recall_sprite.X * worldScale, recall_sprite.Y * worldScale)

    local fontWorld = MIATracker.Fonts.World
    fontWorld:SetColor(MIATracker.Get("World.FontColor"))
    fontWorld:SetSize(MIATracker.Get("World.FontSize") * miaScale)

    local fontMM = MIATracker.Fonts.Minimap
    fontMM:SetColor(MIATracker.Get("Minimap.FontColor"))
    fontMM:SetSize(MIATracker.Get("Minimap.FontSize") * miaScale)

    local mmRectDraw = MIATracker.Get("Minimap.DrawRect")
    local mmCircleDraw = MIATracker.Get("MovementCircle.Enabled")
    local mmCircleColor = MIATracker.Get("MovementCircle.Color")
    local mmCircleMaxDist = MIATracker.Get("MovementCircle.Dist")
    local mmCircleThickness = MIATracker.Get("MovementCircle.Thickness")
    local mmOffX, mmOffY = MIATracker.Get("Minimap.X"), MIATracker.Get("Minimap.Y")
    local mmColor = 0xFFFFFF00 + MIATracker.Get("Minimap.Alpha")
    local mmBorderColor = MIATracker.Get("Minimap.BorderColor")

    local gameTime = Game.GetTime()
    for k, data in pairs(MIATracker.Data) do
        local hero = data.Hero
        if not data.IsVisible and hero.IsEnemy and not hero.IsDead.Value then
            local charName = hero.CharName
            local rTime = 0
            local isRecalling = false     
            local circleColor = nil       
            
            local mm_hero_sprite = MIATracker.Sprites.Champions.Minimap[charName]
            mm_hero_sprite:SetScale(mm_hero_sprite.X * miaScale, mm_hero_sprite.Y * miaScale)            
            
            local mm_c1 = MIATracker.Sprites.Elements[charName]["C1"]
            local mm_c2 = MIATracker.Sprites.Elements[charName]["C2"]
            mm_c1:SetScale(mm_c1.X * miaScale, mm_c1.Y * miaScale)
            mm_c2:SetScale(mm_c2.X * miaScale, mm_c2.Y * miaScale)
            
            local recallTracker = Script.Modules.RecallTracker
            local recallData = recallTracker and recallTracker.Data[hero.Handle]
            if recallData then                
                if recallData.Status == "Started" then
                    isRecalling = true
                    rTime = recallData.StartTime + recallData.RecallTime - gameTime
                    circleColor = (rTime == 4 and 0xAB77FF00 or 0x00FFFF00) + MIATracker.AlphaR 
                end   
                
                local mPos = data.Position:ToMM()                

                insert(MIATracker.DrawQueue, function()
                    if isRecalling then
                        mm_hero_sprite:Draw(mPos, nil, true)
                        mm_c2:SetColor(circleColor):Draw(mPos, nil, true)  
                    else
                        -- //TODO: Disabled Until We Have More Performant 2D Circles
                        -- if mmCircleDraw then
                        --     local dist = (gameTime - data.Time) * hero.Object.MoveSpeed
                        --     if dist < mmCircleMaxDist then
                        --         Renderer.DrawCircleMM(data.Position, dist, mmCircleThickness, mmCircleColor, false)
                        --     end
                        -- end

                        mm_hero_sprite:SetColor(mmColor):Draw(mPos, nil, true)
                        mm_c1:SetColor(mmBorderColor):Draw(mPos, nil, true)
                    end                    
                end)

                if mmDrawTimer then
                    local text = isRecalling and format("%.1f", rTime) or format("%d", gameTime - data.Time)                                        
                    local tX, tY = mPos.x + mmOffX, mPos.y + (10 * miaScale) + mmOffY

                    insert(MIATracker.DrawQueue, function()
                        local textExtent = fontWorld.Font:CalcTextSize(text)
                        if mmRectDraw then
                            Renderer.DrawFilledRect({x = tX, y = tY}, textExtent, 0, 0x00000069)
                        end    
                        fontMM:Draw({x = tX - (textExtent.x / 2), y = tY - (textExtent.y / 2)}, text)
                    end)
                end
            end

            if worldEnabled then
                if hero.Object.IsOnScreen then
                    hero.Object:ForceVisible(fowEnabled)
                    
                    local hero_sprite = MIATracker.Sprites.Champions.World[charName]
                    hero_sprite:SetScale(hero_sprite.X * worldScale, hero_sprite.Y * worldScale)

                    local hp_sprite = MIATracker.Sprites.Elements[charName]["HP"]
                    hp_sprite:SetScale((hp_sprite.X * hero.HealthPercent.Value) * worldScale, hp_sprite.Y * worldScale)                    

                    local mp_sprite = MIATracker.Sprites.Elements[charName]["MP"]
                    mp_sprite:SetScale((mp_sprite.X * hero.ManaPercent.Value) * worldScale, mp_sprite.Y * worldScale)

                    local text = isRecalling and format("%.1f", rTime) or format("%d", gameTime - data.Time)    
                    insert(MIATracker.DrawQueue, function()
                        local pos = data.Position:ToScreen()
                        local x, y = pos.x - 31, pos.y - 41

                        hero_sprite:Draw({x = x + (3 * worldScale), y = y + (3 * worldScale)})

                        if isRecalling then
                            recall_sprite:SetColor(circleColor):Draw({x = x, y = y})
                        else
                            hud_sprite:Draw({x = x, y = y})
                        end
                        
                        hp_sprite:Draw({x = x + (8 * worldScale), y = y + (56 * worldScale)})
                        mp_sprite:Draw({x = x + (8 * worldScale), y = y + (67 * worldScale)})  

                        local textExtent = fontWorld.Font:CalcTextSize(text)
                        local textOffX, textOffY = (35 * worldScale) - textExtent.x/2, (34 * worldScale) - textExtent.y/2
                        fontWorld:Draw({x = x + textOffX, y = y + textOffY}, text)
                    end)
                end
            end
        end
    end
end

function MIATracker.OnTick()
    local tick = clock()

    MIATracker.Scale = MIATracker.Get("Minimap.Scale") / 100
    MIATracker.WorldScale = MIATracker.Get("World.Scale") / 100

    if MIATracker.TickCount < tick then
        MIATracker.TickCount = tick + 0
        for handle, hero in pairs(SLib.Heroes) do
            if hero.IsEnemy and not hero.IsDead.Value then
                local data = MIATracker.Data[hero.Handle]
                local position = data.IsTeleported and Common.GetBasePosition(hero) or hero.Object.Position

                if hero.IsVisible.Value then
                    data.Time = 0
                    data.Position = position                        
                    data.IsVisible = true
                    data.IsTeleported = false
                else
                    if hero.IsMoving.Value then
                        data.Time = 0
                        data.Position = position                        
                        data.IsVisible = true
                        data.IsTeleported = false
                    end
                    if data.IsVisible == true then
                        data.Time = Game.GetTime()
                        data.Position = position                            
                        data.IsVisible = false
                        data.IsTeleported = false
                    end
                end

                if data.Position:Distance(position) > 5 then
                    data.Position = position
                    data.Time = Game.GetTime()
                end
            end
        end
    end

    if not MIATracker.AlphaR then
        MIATracker.AlphaR = 0
    end

    MIATracker.AlphaR = MIATracker.AlphaR + 10
    if MIATracker.AlphaR > 255 then
        MIATracker.AlphaR = 0
    end

    MIATracker.UpdateDrawings()
end

function MIATracker.OnDraw()
    if not MIATracker.Get("Enabled") then return end

    for _, f in ipairs(MIATracker.DrawQueue) do
        f()
    end
end

function MIATracker.OnTeleport(unit, name, duration_secs, status)
    if status ~= "Finished" then return end
    
    local data = MIATracker.Data[unit.Handle]
    if data then
        data.Position = Common.GetBasePosition(unit)
        data.Time = Game.GetTime()
        data.IsVisible = false
        data.IsTeleported = true
    end
end

--#endregion

--[[
    ██     ██  █████  ██████  ██████      ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██     ██ ██   ██ ██   ██ ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██  █  ██ ███████ ██████  ██   ██        ██    ██████  ███████ ██      █████   █████   ██████  
    ██ ███ ██ ██   ██ ██   ██ ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
     ███ ███  ██   ██ ██   ██ ██████         ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                        
]]

--#region Ward Tracker

local WardTracker = Script.Modules.WardTracker

WardTracker.Scale = 1
WardTracker.WorldScale = 1
WardTracker.Font = nil
WardTracker.Sprites = {
    ["World"] = {},
    ["Minimap"] = {},
}
WardTracker.ActiveWards = {}
WardTracker.MenuItems = {
    ["Totem_Ward_icon"] = "Totem Ward (Yellow Trinket)",
    ["Stealth_Ward_icon"] = "Stealth Ward",
    ["Control_Ward_icon"] = "Control Ward",
    ["Blue_Ward_icon"] = "Farsight Ward (Blue Trinket)",
    ["TeemoMushroom_icon"] = "Teemo's Mushroom",
    ["ShacoBox_icon"] = "Shaco's Box",
    ["FiddleSticksEffigy_icon"] = "FiddleSticks Effigy"
}
WardTracker.WardData = {
    ["YellowTrinket"] = {Color = 0xFFFF004B, Duration = 90, IsWard = true, Type = "Totem_Ward_icon"},
    ["SightWard"] = {Color = 0x00C8004B, Duration = 150, IsWard = true, Type = "Stealth_Ward_icon"},
    ["JammerDevice"] = {Color = 0xFF00004B, Duration = huge, IsWard = true, Type = "Control_Ward_icon"},
    ["BlueTrinket"] = {Color = 0x0064FF4B, Duration = huge, IsWard = true, Type = "Blue_Ward_icon"},
    ["TeemoMushroom"] = {Color = 0x64FF004B, Duration = 300, IsWard = false, Type = "TeemoMushroom_icon"},
    ["ShacoBox"] = {Color = 0xFF32004B, Duration = 40, IsWard = false, Type = "ShacoBox_icon"},
    ["FiddleSticksEffigy"] = {Color = 0xFF32004B, Duration = 115, IsWard = false, Type = "FiddleSticksEffigy_icon"}
}
WardTracker.WardOnSpell = {
    ["TrinketTotemLvl1"] = {Color = 0xFFFF004B, Duration = 90, IsWard = true, Type = "Totem_Ward_icon"},
    ["JammerDevice"] = {Color = 0xFF00004B, Duration = huge, IsWard = true, Type = "Control_Ward_icon"},
    ["TrinketOrbLvl3"] = {Color = 0x0064FF4B, Duration = huge, IsWard = true, Type = "Blue_Ward_icon"},
    ["ItemGhostWard"] = {Color = 0x00C8004B, Duration = 150, IsWard = true, Type = "Stealth_Ward_icon"},
    ["TeemoRCast"] = {Color = 0x64FF004B, Duration = 300, IsWard = false, Type = "TeemoMushroom_icon"},
    ["JackInTheBox"] = {Color = 0xFF32004B, Duration = 40, IsWard = false, Type = "ShacoBox_icon"},
    ["FiddleSticksScarecrowEffigy"] = {Color = 0xFF32004B, Duration = 115, IsWard = false, Type = "FiddleSticksEffigy_icon"}
}
WardTracker.SpriteNames = {
    ["World"] = {
        "Totem_Ward_icon_2",
        "Control_Ward_icon_2",
        "Stealth_Ward_icon_2",
        "Blue_Ward_icon_2",
        "TeemoMushroom_icon_2",
        "ShacoBox_icon_2",
        "FiddleSticksEffigy_icon_2"
    },
    ["Minimap"] = {
        "Totem_Ward_icon",
        "Control_Ward_icon",
        "Blue_Ward_icon"
    }
}
WardTracker.VisionPolygons = {}

function WardTracker.Initialize()
    WardTracker.LoadFonts()
    WardTracker.LoadSprites()

    for k, v in pairs(ObjectManager.Get("all", "wards")) do
        WardTracker.ProcessWard(v)
    end
end

function WardTracker.LoadFonts()
    WardTracker["Font"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
end

function WardTracker.LoadSprites()
    for k, name in pairs(WardTracker.SpriteNames.World) do
        local x, y = 40, 40
        if name == "Stealth_Ward_icon_2" then
            x, y = 28, 28
        elseif name == "TeemoMushroom_icon_2" or name == "ShacoBox_icon_2" or name == "FiddleSticksEffigy_icon_2" then
            x, y = 32, 32
        end
        WardTracker["Sprites"]["World"][name] = SLib.CreateSprite("Wards\\" .. name .. ".png", x, y)
    end
    for k, name in pairs(WardTracker.SpriteNames.Minimap) do
        WardTracker["Sprites"]["Minimap"][name] = SLib.CreateSprite("Wards\\" .. name .. ".png", 32, 32)
    end
end

function WardTracker.LoadConfig()
    Menu.NewTree("SAwareness.WardTracker", "Ward Tracker", function()
        Common.CreateCheckbox("SAwareness.WardTracker.Enabled", "Enabled", true)
        Common.CreateCheckbox("SAwareness.WardTracker.DrawVision", "Draw FOV", false)
        
        Menu.NewTree("SAwareness.WardTracker.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.WardTracker.Objects", "Track Objects", function()
                for k, v in pairs(WardTracker.MenuItems) do
                    Common.CreateCheckbox("SAwareness.WardTracker.Objects." .. k, v, true)
                end
            end)
            Menu.NewTree("SAwareness.WardTracker.Minimap", "Ward [Minimap]", function()
                Common.CreateCheckbox("SAwareness.WardTracker.Minimap.Enabled", "Draw On Minimap", true)
                Common.CreateSlider("SAwareness.WardTracker.Minimap.Scale", "Scale", 100, 0, 200, 1)
            end)
            Menu.NewTree("SAwareness.WardTracker.World", "Ward [World]", function()
                Common.CreateCheckbox("SAwareness.WardTracker.World.Enabled", "Draw On Object", true)
                Common.CreateSlider("SAwareness.WardTracker.World.Scale", "Scale", 100, 0, 200, 1)
                Common.CreateSlider("SAwareness.WardTracker.World.FontSize", "Font Size", 20, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.WardTracker.World.FontColor", "Font Color", 0xFFFFFFFF)
                Common.CreateSlider("SAwareness.WardTracker.World.FontOffsetX", "Font X Offset", 0, -200, 200, 1)
                Common.CreateSlider("SAwareness.WardTracker.World.FontOffsetY", "Font Y Offset", 0, -200, 200, 1)
            end)
        end)

        Menu.NewTree("SAwareness.WardTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("WardTracker")
        end)
    end)
end

function WardTracker.Get(value)
	return Menu.Get("SAwareness.WardTracker." .. value, true)
end

function WardTracker.OnProcessSpell(unit, spell)
    local sD = spell.SpellData
    local name = (sD and sD.Name) or ""
    local wardData = WardTracker.WardOnSpell[name]
    if wardData and unit.IsEnemy then        
        local position = spell.EndPos
        local duration =
            name == "TrinketTotemLvl1" and Common.YellowTrinketDuration or
            name == "JackInTheBox" and 40 + (0.05 * unit.TotalAP) or
            name == "FiddleSticksScarecrowEffigy" and 120 - 5 * unit.Level or
            wardData.Duration

        WardTracker.ActiveWards[#WardTracker.ActiveWards + 1] = {
            ["EndTime"] = Game.GetTime() + duration,
            ["Obj"] = nil,
            ["Position"] = position,
            ["IsWard"] = wardData.IsWard,
            ["Color"] = wardData.Color,
            ["Type"] = wardData.Type,
        }
    end
end

function WardTracker.OnCreateObject(obj)
    delay(500, function()
        if obj.IsValid then
            WardTracker.ProcessWard(obj, 0.5)
        end
    end)
end

function WardTracker.GetWardVision(obj)
    local points, pCount, range = {}, 36, 1000

    local pos = obj.Position    
    for i=1, pCount do
        local angle = i * (360/pCount) * pi/180
        local endPos = Vector(pos.x + range * cos(angle), pos.y, pos.z + range * sin(angle))

        for j=25, range, 50 do
            local pointToCheck = pos:Extended(endPos, j)
            if pointToCheck:IsWall() or pointToCheck:IsGrass() then 
                endPos = pointToCheck
                break
            end
        end
        points[i] = endPos:SetHeight()
    end
    return Geometry.Polygon(points)
end

function WardTracker.ProcessWard(obj, delayedAmount)
    local obj = obj.AsMinion
    local wardData =  obj and WardTracker.WardData[obj.CharName]
    if wardData and obj.IsEnemy then
        local objPos = obj.Position
        for k, v in pairs(WardTracker.ActiveWards) do
            if v.IsWard then
                if v and not v.Obj and v.Position and v.Position:Distance(objPos) < 700 then
                    table.remove(WardTracker.ActiveWards, k)
                    break
                end
            else
                if v and not v.Obj and v.Position and v.Position:Distance(objPos) < 1000 then
                    table.remove(WardTracker.ActiveWards, k)
                    break
                end
            end
        end

        WardTracker.VisionPolygons[obj.Handle] = WardTracker.GetWardVision(obj)

        WardTracker.ActiveWards[#WardTracker.ActiveWards + 1] = {
            ["EndTime"] = (wardData.Duration == huge and huge) or (Game.GetTime() + obj.AsAttackableUnit.Mana - (delayedAmount or 0)),
            ["Obj"] = obj,
            ["Position"] = objPos,
            ["IsWard"] = wardData.IsWard,
            ["Color"] = wardData.Color,
            ["Type"] = wardData.Type,
        }
    end
end

function WardTracker.OnDeleteObject(obj)
    WardTracker.VisionPolygons[obj.Handle] = nil

    local obj = obj.AsMinion
    if obj and WardTracker.WardData[obj.CharName] and obj.IsEnemy then
        for k, v in pairs(WardTracker.ActiveWards) do
            if v.Obj and v.Obj == obj then
                table.remove(WardTracker.ActiveWards, k)
            end
        end
    end
end

function WardTracker.OnTick()
    WardTracker.Scale = WardTracker.Get("Minimap.Scale") / 100
    WardTracker.WorldScale = WardTracker.Get("World.Scale") / 100
end

function WardTracker.OnDraw()
    if not WardTracker.Get("Enabled") then return end

    local drawMM = WardTracker.Get("Minimap.Enabled")
    local drawFOV = WardTracker.Get("DrawVision")
    local drawWorld = WardTracker.Get("World.Enabled")

    local xOff = WardTracker.Get("World.FontOffsetX")
    local yOff = WardTracker.Get("World.FontOffsetY")
    local font = WardTracker.Font
    font:SetColor(WardTracker.Get("World.FontColor"))
    font:SetSize(WardTracker.Get("World.FontSize") * WardTracker.Scale)

    local gameTime = Game.GetTime()
    for k, ward in pairs(WardTracker.ActiveWards) do
        if ward and ward.Position and ward.Type ~= "Control_Ward_icon" then
            local wardObj = ward.Obj ~= nil and ward.Obj.IsValid and ward.Obj
            local time = (wardObj and wardObj.IsVisible and wardObj.Mana) or (ward.EndTime - gameTime)

            if WardTracker.Get("Objects." .. ward.Type) then
                if drawMM then
                    local wardType = ward.Type
                    local wardSprite = WardTracker.Sprites.Minimap[wardType]
                    if wardType == "Stealth_Ward_icon" then
                        wardType = "Totem_Ward_icon"
                    end
                    if wardSprite then
                        local w2m = Renderer.WorldToMinimap(ward.Position)
                        wardSprite
                            :SetScale(wardSprite.X * WardTracker.Scale, wardSprite.Y * WardTracker.Scale)
                            :Draw(w2m, nil, true)
                    end
                end

                local w2s = Renderer.WorldToScreen(ward.Position) 
                if drawWorld and Renderer.IsOnScreen2D(w2s) then
                    local wardSprite = WardTracker.Sprites.World[ward.Type .. "_2"]
                    wardSprite
                        :SetScale(wardSprite.X * WardTracker.WorldScale, wardSprite.Y * WardTracker.WorldScale)
                        :Draw(w2s, nil, true)

                    if time < 600 then                        
                        local text = Common.DecToMin(time)
                        local textExtent = font.Font:CalcTextSize(text)
                        local textVector = {x = w2s.x - (textExtent.x / 2) + xOff, y = w2s.y - (textExtent.y / 2) + yOff + 21}
                        font:Draw(textVector, text)
                    end

                    if wardObj then ward.Position.y = wardObj.Position.y end
                    Renderer.DrawCircle3D(ward.Position, 60, 10, 3, ward.Color)

                    local fovPolygon = wardObj and WardTracker.VisionPolygons[wardObj.Handle]
                    if drawFOV and fovPolygon then fovPolygon:Draw(0xFFFFFF70) end
                end
            end

            if time < 0 then
                table.remove(WardTracker.ActiveWards, k)
                return
            end
        end
    end

    for k, ward in pairs(WardTracker.ActiveWards) do
        if ward and ward.Position and ward.Type == "Control_Ward_icon" then
            if WardTracker.Get("Objects." .. ward.Type) then
                if drawMM then
                    local wardSprite = WardTracker.Sprites.Minimap[ward.Type]
                    if wardSprite then
                        local w2m = Renderer.WorldToMinimap(ward.Position)
                        wardSprite
                            :SetScale(wardSprite.X * WardTracker.Scale, wardSprite.Y * WardTracker.Scale)
                            :Draw(w2m, nil, true)
                    end
                end

                local w2s = Renderer.WorldToScreen(ward.Position)
                if drawWorld and Renderer.IsOnScreen2D(w2s) then
                    ward.Position.y = ward.Obj ~= nil and ward.Obj.Position.y or ward.Position.y
                    Renderer.DrawCircle3D(ward.Position, 60, 10, 3, ward.Color)
                    local wardSprite = WardTracker.Sprites.World[ward.Type .. "_2"]
                    wardSprite
                        :SetScale(wardSprite.X * WardTracker.WorldScale, wardSprite.Y * WardTracker.WorldScale)
                        :Draw(w2s, nil, true)
                end
            end
        end
    end
end

--#endregion

--[[
         ██ ██    ██ ███    ██  ██████  ██      ███████     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
         ██ ██    ██ ████   ██ ██       ██      ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
         ██ ██    ██ ██ ██  ██ ██   ███ ██      █████          ██    ██████  ███████ ██      █████   █████   ██████  
    ██   ██ ██    ██ ██  ██ ██ ██    ██ ██      ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
     █████   ██████  ██   ████  ██████  ███████ ███████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                 
]]

--#region Jungle Tracker

local JungleTracker = Script.Modules.JungleTracker

JungleTracker.Sprites = {
    ["World"] = nil,
}
JungleTracker.Fonts = {
    ["World"] = nil,
    ["Minimap"] = nil
}
JungleTracker.Scale = 1
JungleTracker.Camps = {
    [1] = {
        Position = Vector(6943.41, 52.62, 5422.61),
        Objects = {
            "SRU_RazorbeakMini3.1.6",
            "SRU_RazorbeakMini3.1.5",
            "SRU_RazorbeakMini3.1.4",
            "SRU_RazorbeakMini3.1.3",
            "SRU_RazorbeakMini3.1.2",
            "SRU_Razorbeak3.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 61
    },
    [2] = {
        Position = Vector(2164.34, 51.78, 8383.02),
        Objects = {
            "SRU_Gromp13.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 288
    },
    [3] = {
        Position = Vector(8370.58, 51.09, 2718.15),
        Objects = {
            "SRU_KrugMini5.1.2",
            "SRU_Krug5.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 394
    },
    [4] = {
        Position = Vector(4285.04, -67.6, 9597.52),
        Objects = {
            "Sru_Crab16.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 150000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 400
    },
    [5] = {
        Position = Vector(6476.17, 56.48, 12142.51),
        Objects = {
            "SRU_KrugMini11.1.2",
            "SRU_Krug11.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 499
    },
    [6] = {
        Position = Vector(10983.83, 62.22, 8328.73),
        Objects = {
            "SRU_MurkwolfMini8.1.3",
            "SRU_MurkwolfMini8.1.2",
            "SRU_Murkwolf8.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 59
    },
    [7] = {
        Position = Vector(12671.83, 51.71, 6306.6),
        Objects = {
            "SRU_Gromp14.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 703
    },
    [8] = {
        Position = Vector(3800.99, 52.18, 7883.53),
        Objects = {
            "SRU_Blue1.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 300000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 821
    },
    [9] = {
        Position = Vector(4993.14, -71.24, 10491.92),
        Objects = {
            ""
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 0,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 7
    },
    [10] = {
        Position = Vector(7852.38, 52.3, 9562.62),
        Objects = {
            "SRU_RazorbeakMini9.1.6",
            "SRU_RazorbeakMini9.1.5",
            "SRU_RazorbeakMini9.1.4",
            "SRU_RazorbeakMini9.1.3",
            "SRU_RazorbeakMini9.1.2",
            "SRU_Razorbeak9.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 820
    },
    [11] = {
        Position = Vector(10984.11, 51.72, 6960.31),
        Objects = {
            "SRU_Blue7.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 300000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 131
    },
    [12] = {
        Position = Vector(10647.7, -62.81, 5144.68),
        Objects = {
            "Sru_Crab15.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 150000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 500
    },
    [13] = {
        Position = Vector(4993.14, -71.24, 10491.92),
        Objects = {
            "SRU_Baron12.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 360000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 7
    },
    [14] = {
        Position = Vector(3849.95, 52.46, 6504.36),
        Objects = {
            "SRU_MurkwolfMini2.1.3",
            "SRU_MurkwolfMini2.1.2",
            "SRU_Murkwolf2.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 120000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 783
    },
    [15] = {
        Position = Vector(7813.07, 53.81, 4051.33),
        Objects = {
            "SRU_Red4.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 300000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 762
    },
    [16] = {
        Position = Vector(9813.83, -71.24, 4360.19),
        Objects = {
            ""
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 0,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 866
    },
    [17] = {
        Position = Vector(7139.29, 56.38, 10779.34),
        Objects = {
            "SRU_Red10.1.1"
        },
        ObjectsAlive = {},
        ObjectsDead = {},
        IsDead = true,
        BaseRespawnTime = 300000,
        RespawnTime = 0,
        CampRespawn = false,
        CampRespawnObject = nil,
        Hash = 66
    }
}

function JungleTracker.Initialize()
    JungleTracker.LoadSprites()
    JungleTracker.LoadFonts()

    JungleTracker.DrawQueue = {}
    JungleTracker.LastUpdate = 0

    for handle, minion in pairs(ObjectManager.Get("all", "minions")) do
        JungleTracker.OnCreateObject(minion)
    end
end

function JungleTracker.LoadSprites()
    JungleTracker["Sprites"]["World"] = SLib.CreateSprite("Icons\\button-hover.png", 64, 64)
end

function JungleTracker.LoadFonts()
    JungleTracker["Fonts"]["World"] = SLib.CreateFont("Bahnschrift.ttf", 18, 0xFFFFFFFF)
    JungleTracker["Fonts"]["Minimap"] = SLib.CreateFont("Bahnschrift.ttf", 15, 0xFFFFFFFF)
end

function JungleTracker.LoadConfig()
    Menu.NewTree("SAwareness.JungleTracker", "Jungle Tracker", function()
        Common.CreateCheckbox("SAwareness.JungleTracker.Enabled", "Enabled", true)

        Menu.NewTree("SAwareness.JungleTracker.ElementSettings", "Element Settings", function()
            Menu.NewTree("SAwareness.JungleTracker.World", "Jungle Timer [World]", function()
                Common.CreateCheckbox("SAwareness.JungleTracker.World.Enabled", "Draw On Camp", true)
                Common.CreateCheckbox("SAwareness.JungleTracker.World.DrawSprite", "Draw Sprite", true)
                if JungleTracker.Get("World.DrawSprite") then
                    Common.CreateSlider("SAwareness.JungleTracker.World.Scale", "Scale", 100, 0, 200, 1)
                    Common.CreateSlider("SAwareness.JungleTracker.World.Alpha", "Transparency", 255, 0, 255, 1)
                end
                Common.CreateSlider("SAwareness.JungleTracker.World.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.JungleTracker.World.FontColor", "Font Color", 0xFFFFFFFF)
            end)
            Menu.NewTree("SAwareness.JungleTracker.Minimap", "Jungle Timer [Minimap]", function()
                Common.CreateCheckbox("SAwareness.JungleTracker.Minimap.Enabled", "Draw On Minimap", true)
                Common.CreateCheckbox("SAwareness.JungleTracker.Minimap.DrawRect", "Draw Semi-transparent Rectangle Behing Font", true)
                Common.CreateSlider("SAwareness.JungleTracker.Minimap.FontSize", "Font Size", 16, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.JungleTracker.Minimap.FontColor", "Font Color", 0xFFFFFFFF)
            end)
        end)
        Menu.NewTree("SAwareness.JungleTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("JungleTracker")
        end)
    end)
end

function JungleTracker.Get(value)
	return Menu.Get("SAwareness.JungleTracker." .. value, true)
end

function JungleTracker.OnTick()    
    if not JungleTracker.Get("Enabled") then JungleTracker.DrawQueue = {}; return end

    JungleTracker.Scale = JungleTracker.Get("World.Scale") / 100
    JungleTracker.UpdateDrawings()
end

function JungleTracker.UpdateDrawings()
    local gameTime = Game.GetTime()
    if gameTime - JungleTracker.LastUpdate < 0.2 then return end
    JungleTracker.LastUpdate = gameTime

    JungleTracker.DrawQueue = {}

    local drawMM = JungleTracker.Get("Minimap.Enabled")
    local drawWorld = JungleTracker.Get("World.Enabled")
    if not (drawMM or drawWorld) then return end

    local mm_DrawRect = JungleTracker.Get("Minimap.DrawRect")
    local mm_Font = JungleTracker.Fonts.Minimap    
    mm_Font:SetColor(JungleTracker.Get("Minimap.FontColor"))
    mm_Font:SetSize(JungleTracker.Get("Minimap.FontSize"))

    local world_DrawSprite = JungleTracker.Get("World.DrawSprite")
    local world_Sprite = JungleTracker.Sprites.World
    world_Sprite:SetScale(world_Sprite.X * JungleTracker.Scale, world_Sprite.Y * JungleTracker.Scale)
    world_Sprite:SetColor(0xFFFFFF00 + JungleTracker.Get("World.Alpha"))

    local world_Font = JungleTracker.Fonts.World
    world_Font:SetColor(JungleTracker.Get("World.FontColor"))
    world_Font:SetSize(JungleTracker.Get("World.FontSize") * JungleTracker.Scale)

    local mousePos = Renderer.GetMousePos()    
    for campID, camp in pairs(JungleTracker.Camps) do
        if camp.IsDead and camp.RespawnTime - gameTime > 0 then            
            local text = Common.DecToMin(camp.RespawnTime - gameTime)
            
            if drawMM then
                local pos = Renderer.WorldToMinimap(camp.Position)    

                insert(JungleTracker.DrawQueue, function()
                    local textExtent = mm_Font.Font:CalcTextSize(text)
                    local textVector = {x = pos.x - (textExtent.x / 2), y = pos.y - (textExtent.y / 2)}
    
                    if mm_DrawRect then
                        local p1 = {x = pos.x - (textExtent.x / 2), y = pos.y}
                        local p2 = {x = pos.x + (textExtent.x / 2), y = pos.y}
                        local height = textExtent.y
                        Renderer.DrawLine(p1, p2, height, 0x00000069)
                    end
                    mm_Font:Draw(textVector, text)
                end)                
            end

            if drawWorld and camp.Position:Distance(mousePos) < 3000 and Renderer.IsOnScreen(camp.Position) then   
                insert(JungleTracker.DrawQueue, function() 
                    local pos = Renderer.WorldToScreen(camp.Position)
                    if Renderer.IsOnScreen2D(pos) then               
                        if world_DrawSprite then
                            world_Sprite:Draw(pos, nil, true)
                        end
                        
                        local textExtent = world_Font.Font:CalcTextSize(text) 
                        local offX, offY = textExtent.x * 0.5, textExtent.y * 0.5
                        world_Font:Draw({x = pos.x - offX, y = pos.y - offY}, text) 
                    end
                end)
            end
        end
    end
end

function JungleTracker.OnDraw()
    if not JungleTracker.Get("Enabled") then return end

    for _, f in ipairs(JungleTracker.DrawQueue) do
        f()
    end
end

function JungleTracker.OnCreateObject(obj)
    local time = Game.GetTime()
    local isCampRespawn = obj.Name == "CampRespawn"
    if not (obj.IsMinion or isCampRespawn) then return end
    
    local isAI = obj.IsAI
    local campHash = isCampRespawn and Common.GetHash(obj.Position.x) or -1
    for campID, camp in pairs(JungleTracker.Camps) do
        if campHash == camp.Hash then
            camp.IsDead = true
            camp.CampRespawn = true
            camp.CampRespawnObject = obj

            if isAI then
                delay(500, function()
                    if not obj.IsValid then return end

                    local buff1 = obj:GetBuff("camprespawncountdownhidden")
                    local buff = buff1 or obj:GetBuff("camprespawncountdownvisible")
                    if buff then
                        camp.RespawnTime = time + buff.DurationLeft + (buff1 and 60 or 0)
                    end
                end)
            end
        end
        if Common.Contains(camp.Objects, obj.name) then
            table.insert(camp.ObjectsAlive, obj.name)
            for key, deadObject in pairs(camp.ObjectsDead) do
                if obj.name == deadObject then
                    table.remove(camp.ObjectsDead, key)
                end
            end
            if #camp.ObjectsAlive > 0 then
                camp.IsDead = false
                camp.RespawnTime = 0
            end
        end
    end
end

function JungleTracker.OnDeleteObject(obj)
    local time = Game.GetTime()
    if obj and obj.IsMinion then
        for campID, camp in pairs(JungleTracker.Camps) do
            if Common.Contains(camp.Objects, obj.name) then
                table.insert(camp.ObjectsDead, obj.name)
                for key, aliveObject in pairs(camp.ObjectsAlive) do
                    if obj.name == aliveObject then
                        table.remove(camp.ObjectsAlive, key)
                    end
                end
                if #camp.ObjectsDead == #camp.Objects then
                    camp.IsDead = true
                    if not camp.CampRespawn then
                        camp.RespawnTime = time + camp.BaseRespawnTime / 1000 - 3
                    end
                end
            end
            if camp.CampRespawn and camp.CampRespawnObject and camp.CampRespawnObject == obj then
                camp.CampRespawn = false
                camp.CampRespawnObject = nil
            end
        end
    end
end

--#endregion

--[[
    ██████   █████  ██████   ██████  ███    ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██   ██ ██   ██ ██   ██ ██    ██ ████   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██████  ███████ ██████  ██    ██ ██ ██  ██        ██    ██████  ███████ ██      █████   █████   ██████  
    ██   ██ ██   ██ ██   ██ ██    ██ ██  ██ ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██████  ██   ██ ██   ██  ██████  ██   ████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                     
]]

--#region Baron Tracker

local BaronTracker = Script.Modules.BaronTracker

BaronTracker.Fonts = {
    ["Main"] = nil,
}
BaronTracker.X = 0
BaronTracker.Y = 0
BaronTracker.MoveOffset = {}
BaronTracker.Rect = {}
BaronTracker.IsUnderAttack = {
    Dragon = {
        Status = false,
        Time = 0
    },
    Baron = {
        Status = false,
        Time = 0
    },
    Herald = {
        Status = false,
        Time = 0
    }
}

function BaronTracker.Initialize()
    BaronTracker.LoadFonts()
end

function BaronTracker.LoadFonts()
    BaronTracker["Fonts"]["Main"] = SLib.CreateFont("Bahnschrift.ttf", 30, 0xFFFFFFFF)
end

function BaronTracker.LoadConfig()
    Menu.NewTree("SAwareness.BaronTracker", "Baron Tracker", function()
        Common.CreateCheckbox("SAwareness.BaronTracker.Enabled", "Enabled", true)
        Menu.NewTree("SAwareness.BaronTracker.PositionSettings", "Position Settings", function()
            Common.CreateSlider("SAwareness.BaronTracker.X", "X", 100, 0, Resolution.x, 1)
            Common.CreateSlider("SAwareness.BaronTracker.Y", "Y", 100, 0, Resolution.y, 1)
            Common.CreateCheckbox("SAwareness.BaronTracker.Drag", "Allow To Drag By SHIFT + LMB", true)
        end)
        Menu.NewTree("SAwareness.BaronTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("BaronTracker")
        end)
    end)
end

function BaronTracker.Get(value)
	return Menu.Get("SAwareness.BaronTracker." .. value, true)
end

function BaronTracker.OnTick()
    BaronTracker.X = BaronTracker.Get("X")
    BaronTracker.Y = BaronTracker.Get("Y")
end

function BaronTracker.OnDraw()
    if not BaronTracker.Get("Enabled") then return end

    local x = BaronTracker.X
    local y = BaronTracker.Y
    local text = "Dragon & Baron Tracker Bar Position"
    local cursorPos = Renderer.GetCursorPos()
    local shouldDraw = false

    BaronTracker.Rect = {x = x - 5, y = y - 5, z = ScreenPosPct.x * 25, w = ScreenPosPct.y * 5}

    if Common.ShiftPressed then
        shouldDraw = true
        if BaronTracker.Get("Drag") then
            local rect = BaronTracker.Rect
            if not BaronTracker.MoveOffset and rect and Common.CursorIsUnder(rect.x, rect.y, rect.z, rect.w) and Common.LMBPressed then
                BaronTracker.MoveOffset = {
                    x = rect.x - cursorPos.x + 5,
                    y = rect.y - cursorPos.y + 5
                }
            elseif BaronTracker.MoveOffset and not Common.LMBPressed then
                BaronTracker.MoveOffset = nil
            end

            if BaronTracker.MoveOffset then
                rect.x = BaronTracker.MoveOffset.x + cursorPos.x
                rect.x = rect.x > 0 and rect.x or 0
                rect.x = rect.x < Resolution.x - rect.z and rect.x or Resolution.x - rect.z

                rect.y = BaronTracker.MoveOffset.y + cursorPos.y
                rect.y = rect.y > 0 and rect.y or 0
                rect.y = rect.y < (Resolution.y - rect.w + 6) and rect.y or (Resolution.y - rect.w + 6)

                if Common.LMBPressed then
                    BaronTracker.X = rect.x
                    BaronTracker.Y = rect.y
                    Menu.Set("SAwareness.BaronTracker.X", BaronTracker.X, true)
                    Menu.Set("SAwareness.BaronTracker.Y", BaronTracker.Y, true)
                end
            end
        end
    end

    for k, v in pairs(BaronTracker.IsUnderAttack) do
        if v.Status and v.Time + 5 > Game.GetTime() then
            text = k .. " Is Under Attack"
            shouldDraw = true
        end
    end

    if shouldDraw then
        local fontData = BaronTracker.Fonts.Main
        local textExtent = fontData.Font:CalcTextSize(text, true)
        Common.DrawRectOutline({x, y, ScreenPosPct.x * 25, ScreenPosPct.y * 5}, 3, 0x000000FF)
        Common.DrawFilledRect({x, y, ScreenPosPct.x * 25, ScreenPosPct.y * 5}, 0x796C43FF)
        Common.DrawFilledRect({x + 3, y + 3, ScreenPosPct.x * 25 - 6, ScreenPosPct.y * 5 - 6}, 0x000000B4)
        Common.DrawRectOutline({x + 3, y + 3, ScreenPosPct.x * 25 - 6, ScreenPosPct.y * 5 - 6}, 3, 0x000000FF)
        fontData.Font:DrawText(Vector(x + ((ScreenPosPct.x * 25 - textExtent.x) * 0.5),y + ((ScreenPosPct.y * 5  - textExtent.y) * 0.5)), text, 0xFFFFFFFF)
    end
end

function BaronTracker.OnCreateObject(obj)
    local time = Game.GetTime()
    local dragon = BaronTracker.IsUnderAttack.Dragon
    local baron = BaronTracker.IsUnderAttack.Baron
    local herald = BaronTracker.IsUnderAttack.Herald
    if obj.Name == "SRU_Dragon_Spawn_Praxis.troy" then
        dragon.Status = true
        dragon.Time = time
    elseif obj.Name == "SRU_Baron_Base_BA1_tar.troy" then
        baron.Status = true
        baron.Time = time
    end
    if obj.Name == "SRU_Dragon_idle1_landing_sound.troy" or obj.Name == "SRU_Dragon_death_sound.troy" or obj.Name == "SRU_Dragon_Elder_death_sound.troy" then
        dragon.Status = false
        dragon.Time = 0
    end
    if obj.Name == "SRU_Baron_death_sound.troy" or obj.Name == "SRU_Baron_idle1_sound.troy" then
        baron.Status = false
        baron.Time = 0
    end
    if obj.Name == "SRU_RiftHerald_BA_1_fistslam.troy" then
        herald.Status = true
        herald.Time = time
    end
end

--#endregion

--[[
     ██████ ██       ██████  ███    ██ ███████     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██      ██      ██    ██ ████   ██ ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██      ██      ██    ██ ██ ██  ██ █████          ██    ██████  ███████ ██      █████   █████   ██████  
    ██      ██      ██    ██ ██  ██ ██ ██             ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
     ██████ ███████  ██████  ██   ████ ███████        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                     
]]

--#region Clone Tracker

local CloneTracker = Script.Modules.CloneTracker

CloneTracker.Sprites = {
    ["Main"] = nil
}
CloneTracker.Clones = {}
CloneTracker.Data = {
    ["Shaco"] = true,
    ["Leblanc"] = true,
    ["MonkeyKing"] = true,
    ["Neeko"] = true,
    ["FiddleSticksEffigy"] = true
}

function CloneTracker.Initialize()
    CloneTracker.LoadSprites()
end

function CloneTracker.LoadSprites()
    CloneTracker["Sprites"]["Main"] = SLib.CreateSprite("Icons\\icon-position-none-disabled.png", 136, 136):SetColor(0xFF0000FF)
end

function CloneTracker.LoadConfig()
    Menu.NewTree("SAwareness.CloneTracker", "Clone Tracker", function()
        Common.CreateCheckbox("SAwareness.CloneTracker.Enabled", "Enabled", true)
        Menu.NewTree("SAwareness.CloneTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("CloneTracker")
        end)
    end)
end

function CloneTracker.Get(value)
	return Menu.Get("SAwareness.CloneTracker." .. value, true)
end

function CloneTracker.OnCreateObject(obj)
    if obj and obj.IsAI then
        if CloneTracker.Data[obj.AsAI.CharName] and obj.IsEnemy then
            table.insert(CloneTracker.Clones, obj)
        end
    end
end

function CloneTracker.OnDraw()
    if not CloneTracker.Get("Enabled") then return end

    for k, v in pairs(CloneTracker.Clones) do
        if v and v.IsValid and not v.IsDead then
            if v.Position:IsOnScreen() then
                local pos = Renderer.WorldToScreen(v.Position)
                CloneTracker.Sprites.Main
                    :Draw(Vector(pos.x - (136 * 0.5), pos.y - (136 * 0.5) - 50))
            end
        else
            table.remove(CloneTracker.Clones, k)
        end
    end
end

--#endregion

--[[
    ██████   █████  ██████   █████  ██████  
    ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
    ██████  ███████ ██   ██ ███████ ██████  
    ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
    ██   ██ ██   ██ ██████  ██   ██ ██   ██                                      
]]

--#region Radar

local Radar = Script.Modules.Radar

Radar.Fonts = {}
Radar.Sprites = {
    ["Champions"] = {},
    ["Border"] = nil
}

function Radar.Initialize()
    Radar.LoadSprites()
    Radar.LoadFonts()
end

function Radar.LoadSprites()
    Radar["Sprites"]["Border"] = SLib.CreateSprite("Icons\\icon-red-border.png", 64, 64)
    for handle, hero in pairs(ObjectManager.Get("all", "heroes")) do
        local charName = hero.CharName
        Radar["Sprites"]["Champions"][charName] = SLib.CreateSprite("Champions\\" .. charName .. ".png", 60, 60)
    end
end

function Radar.LoadFonts()
    Radar["Fonts"]["Main"] = SLib.CreateFont("Bahnschrift.ttf", 20, 0xFFFFFFFF)
end

function Radar.LoadConfig()
    Menu.NewTree("SAwareness.Radar", "Radar", function()
        Common.CreateCheckbox("SAwareness.Radar.Enabled", "Enabled", true)
        
        Menu.NewTree("SAwareness.Radar.AppearanceSettings", "Appearance Settings", function()
            Common.CreateDropdown("SAwareness.Radar.Style", "Style", 0, { "ESP Lines", "Round Sprites" })
        end)

        Menu.NewTree("SAwareness.Radar.ElementSettings", "Element Settings", function()
            Common.CreateSlider("SAwareness.Radar.Range", "Max Distance", 3000, 1000, 5000, 1)
            if Radar.Get("Style") == 0 then
                Common.CreateColorPicker("SAwareness.Radar.LineColor", "Line Color", 0xFF00003E)
                Common.CreateSlider("SAwareness.Radar.FontSize", "Font Size", 18, 0, 50, 1)
                Common.CreateColorPicker("SAwareness.Radar.FontColor", "Font Color", 0xFFFFFFFF)
            end
        end)

        Menu.NewTree("SAwareness.Radar.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("Radar")
        end)
    end)
end

function Radar.Get(value)
	return Menu.Get("SAwareness.Radar." .. value, true)
end

function Radar.OnDraw()
    if not Radar.Get("Enabled") then return end

    local gameTime = Game.GetTime()
    local myPosition = Player.Position
    local counter = 0

    local color = Radar.Get("LineColor")
    local style = Radar.Get("Style")
    local maxRange = Radar.Get("Range")

    local font = Radar.Fonts.Main
    font:SetColor(Radar.Get("FontColor"))
    font:SetSize(Radar.Get("FontSize"))

    for k, data in pairs(Script.Modules.MIATracker.Data) do
        local hero = data.Hero
        local enemyPos = hero.Object.Position
        local dist = enemyPos:Distance(myPosition)
        
        if hero.IsEnemy and not hero.IsDead.Value and dist < maxRange then
            local timeSinceMIA = gameTime - data.Time
            if (not data.IsVisible and timeSinceMIA < 5) or (data.IsVisible and not hero.IsOnScreen.Value) then
                local ringPos = myPosition:Extended(enemyPos, 500 - counter * 130)                
                local screenPos = Renderer.WorldToScreen(ringPos)

                if style == 0 then
                    Renderer.DrawLine3D(myPosition, enemyPos, (maxRange - dist)/150, color)

                    local text = hero.CharName                    
                    local textExtent = font.Font:CalcTextSize(text, true)                    
                    font:Draw({x = screenPos.x - textExtent.x/2, y = screenPos.y - textExtent.y/2}, text)
                elseif style == 1 then
                    Renderer.DrawLine3D(myPosition, ringPos, 3, 0xFF3019B4)
                    Radar.Sprites.Champions[hero.CharName]:Draw(screenPos, nil, true)
                    Radar.Sprites.Border:Draw(screenPos, nil, true)
                end
            end
            counter = counter + 1
        end
    end
end

--#endregion

--[[
    ██████   █████  ███████ ██   ██     ████████ ██████   █████   ██████ ██   ██ ███████ ██████  
    ██   ██ ██   ██ ██      ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██   ██ ███████ ███████ ███████        ██    ██████  ███████ ██      █████   █████   ██████  
    ██   ██ ██   ██      ██ ██   ██        ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██████  ██   ██ ███████ ██   ██        ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██                                                                                                                                                                                
]]

--#region Dash Tracker

local DashTracker = Script.Modules.DashTracker

DashTracker.Fonts = {}
DashTracker.Sprites = {}
DashTracker.ActiveSpells = {}
DashTracker.SpellData = {
    ["SummonerFlash"] = {
        ["DisplayName"] = "Summoner Flash",
        ["Range"] = 400,
        ["SpritePath"] = "Summoners\\SummonerFlash.png",
    },
    ["Deceive"] = {
        ["DisplayName"] = "Shaco | Q | Deceive",
        ["Range"] = 400,
        ["SpritePath"] = "Spells\\Deceive.png",
    },
    ["EzrealE"] = {
        ["DisplayName"] = "Ezreal | E | Arcane Shift",
        ["Range"] = 475,
        ["SpritePath"] = "Spells\\EzrealE.png",
    },
    ["KatarinaE"] = {
        ["DisplayName"] = "Katarina | E | Shunpo",
        ["Range"] = 725,
        ["SpritePath"] = "Spells\\KatarinaEWrapper.png",
    },
    ["KatarinaEDagger"] = {
        ["DisplayName"] = "Katarina | E | Shunpo [Dagger]",
        ["Range"] = 725,
        ["SpritePath"] = "Spells\\KatarinaEWrapper.png",
    },
    ["LeblancW"] = {
        ["DisplayName"] = "Leblanc | W | Distortion",
        ["Range"] = 600,
        ["SpritePath"] = "Spells\\LeblancW.png",
    },
    ["VayneTumble"] = {
        ["DisplayName"] = "Vayne | Q | Tumble",
        ["Range"] = 300,
        ["SpritePath"] = "Spells\\VayneTumble.png", 
    },
    ["ZedW"] = {
        ["DisplayName"] = "Zed | W | Living Shadow",
        ["Range"] = 700,
        ["SpritePath"] = "Spells\\ZedW.png", 
    },
}

function DashTracker.Initialize()
    DashTracker.LoadSprites()
    DashTracker.LoadFonts()
end

function DashTracker.LoadSprites()
end

function DashTracker.LoadFonts()
end

function DashTracker.LoadConfig()
    Menu.NewTree("SAwareness.DashTracker", "Dash Tracker", function()
        Common.CreateCheckbox("SAwareness.DashTracker.Enabled", "Enabled", true)

        Menu.NewTree("SAwareness.DashTracker.ModuleSettings", "Module Settings", function()
            Common.CreateResetButton("DashTracker")
        end)
    end)
end

function DashTracker.Get(value)
	return Menu.Get("SAwareness.DashTracker." .. value, true)
end

function DashTracker.OnDraw()
    if not DashTracker.Get("Enabled") then return end

    for k, v in pairs(DashTracker.ActiveSpells) do
        local remainingTime = v.EndTime - Game.GetTime()
        if remainingTime > 0 then
            local startPos = Renderer.WorldToScreen(v.StartPos)
            local endPos = Renderer.WorldToScreen(v.EndPos)
            local lineColor = 0xFFFFFFFF
            --[[
            DrawSprite(v.SpellSprite, endPos, 60, true)
            DrawSprite(v.CasterSprite, startPos, 60, true)
            DrawSprite(v.BorderSprite, startPos, nil, true)
            DrawSprite(v.BorderSprite, endPos, nil, true)
            SetSpriteColor(v.CasterSprite, 0xFFFFFFFF)
            SetSpriteColor(v.SpellSprite, 0xFFFFFFFF)
            SetSpriteColor(v.BorderSprite, 0xFFFFFFFF)]]

            if remainingTime < 1 then
                v.Aplha = v.Aplha - 5
                if v.Aplha < 0 then v.Aplha = 0 end 
                local color = 0xFFFFFF00 + v.Aplha
                lineColor = color
                --[[
                SetSpriteColor(v.CasterSprite, color)
                SetSpriteColor(v.SpellSprite, color)
                SetSpriteColor(v.BorderSprite, color)]]
            end
            Renderer.DrawLine(startPos:Extended(endPos, 30), endPos:Extended(startPos, 30), 4, lineColor)
        else
            DashTracker.ActiveSpells[k] = nil
        end
    end
end

function DashTracker.OnProcessSpell(unit, spell)
    --GetMenuValue("S_BeAware_Whitelist_" .. unit.CharName) and GetMenuValue("S_BeAware_SpellWhitelist_" .. spell.Name)
    if DashTracker.SpellData[spell.Name] then
        local spellData = DashTracker.SpellData[spell.Name]
        local startPos = spell.StartPos
        local endPos = spell.EndPos
        local dist = startPos:Distance(endPos)
        local range = spellData.Range
        local realEndPos = dist < range and endPos or startPos:Extended(endPos, range)
        DashTracker.ActiveSpells[#DashTracker.ActiveSpells + 1] = {
            StartPos = startPos,
            EndPos = realEndPos,
            EndTime = Game.GetTime() + 3,
            Data = spellData,
            CharName = unit.CharName,
            Aplha = 255,
            SpellSprite = SLib.CreateSprite(spellData.SpritePath, 60, 60),
            BorderSprite = SLib.CreateSprite("HUD\\WC2.png", 61, 61),
            CasterSprite = SLib.CreateSprite("Champions\\" .. unit.CharName .. ".png", 60, 60)
        }
    end
end

--#endregion

--[[
    ██ ███    ██ ██ ████████ ██  █████  ██      ██ ███████ ███████ 
    ██ ████   ██ ██    ██    ██ ██   ██ ██      ██    ███  ██      
    ██ ██ ██  ██ ██    ██    ██ ███████ ██      ██   ███   █████   
    ██ ██  ██ ██ ██    ██    ██ ██   ██ ██      ██  ███    ██      
    ██ ██   ████ ██    ██    ██ ██   ██ ███████ ██ ███████ ███████                                                                                                                                                                         
]]

--#region INIT

local function Initialize()
    Menu.RegisterMenu("SAwareness", "Awareness Settings", function()
        Menu.Checkbox("SAwareness.Disable", "Disable Awareness", false)

        Menu.Separator()

        if Script.Disabled and not Menu.Get("SAwareness.Disable") then
            Menu.ColoredText("Now Press F5 To Load Awareness!", 0xFF0000FF, true)
            return true
        end

        if Script.Disabled then
            Menu.ColoredText("Awareness Disabled", 0xFF0000FF, true)
            return true
        end

        if not Script.Disabled and Menu.Get("SAwareness.Disable") then
            Menu.ColoredText("Now Press F5 To Unload Awareness!", 0xFF0000FF, true)
            return true
        end

        for _, module in Common.OrderedPairs(Script.Modules) do
        	module.LoadConfig()
        end

        Menu.Separator()

        Menu.Text("Version: " .. Script.Version)
        Menu.Text("Last Update: " .. Script.LastUpdate)
        Menu.Text("Author: Shulepin")

        Menu.Separator()
    end)

    if Menu.Get("SAwareness.Disable") then
        Script.Disabled = true
        return true
    end

    for moduleName, module in pairs(Script.Modules) do
        module.Initialize()
        for eventName, eventID in pairs(Enums.Events) do
            if Script.Modules[moduleName][eventName] then
                EventManager.RegisterCallback(eventID, Script.Modules[moduleName][eventName])
            end
        end
    end

    Script.Initialized = true
    return true
end

Initialize()

--#endregion
