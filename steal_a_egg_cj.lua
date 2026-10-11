--[[
    ██████╗     ██╗
    ██╔══██╗    ██║
    ██║  ██║    ██║
    ██║  ██║██   ██║
    ╚██████╔╝╚█████╔╝
     ╚═════╝  ╚════╝
    STEAL A EGG | CUSTOM BUILD
    Author : CJ
    Build  : v1.0
--]]

--============================================================
-- SERVICES
--============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============================================================
-- CONFIG
--============================================================
local Config = {
    -- Auto Steal
    AutoSteal           = false,
    StealDelay          = 0.15,
    StealRange          = 500,
    ReturnToPlot        = true,
    ReturnMethod        = "Plot Center",

    -- Auto Place
    AutoPlace           = false,
    PlaceDelay          = 0.2,

    -- Auto Hatch
    AutoHatch           = false,
    HatchDelay          = 0.3,

    -- Auto Sell
    AutoSell            = false,
    SellDelay           = 0.5,
    SellBelowKG         = 0,

    -- Player
    AntiAFK             = true,
    AntiRagdoll         = true,
    WalkSpeed           = 16,
    JumpPower           = 50,
    InfiniteJump        = false,
    NoClip              = false,

    -- ESP
    EggESP              = false,
    PlayerESP           = false,
}

--============================================================
-- STATE
--============================================================
local State = {
    Connections = {},
    EggCache    = {},
    PlotPos     = nil,
    LastPos     = nil,
    Running     = true,
}

--============================================================
-- HELPER
--============================================================
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = duration or 3,
        })
    end)
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function teleportTo(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame.new(pos)
    end
end

--============================================================
-- AUTO STEAL CORE
--============================================================
local function findEggs()
    local list = {}
    local container = Workspace

    for _, obj in ipairs(container:GetDescendants()) do
        if not obj:IsA("Model") and not obj:IsA("Tool") and not obj:IsA("BasePart") then
            continue
        end

        local name = string.lower(obj.Name)
        if string.find(name, "egg") and not string.find(name, "eggplot") then
            local primary = obj:IsA("BasePart") and obj or obj.PrimaryPart
            if primary then
                table.insert(list, { obj = obj, part = primary })
            end
        end
    end
    return list
end

local function stealEgg(eggData)
    local hrp = getHRP()
    if not hrp or not eggData or not eggData.part then return false end

    State.LastPos = hrp.CFrame

    -- Teleport ke telur
    hrp.CFrame = CFrame.new(eggData.part.Position + Vector3.new(0, 3, 0))
    task.wait(0.05)

    -- Cari prompt / proximity
    local prompt = eggData.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
        return true
    end

    -- Fallback: klik manual via VirtualUser
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
    return true
end

local function returnToPlot()
    if not Config.ReturnToPlot then return end
    if State.PlotPos then
        teleportTo(State.PlotPos)
    elseif State.LastPos then
        getHRP().CFrame = State.LastPos
    end
end

task.spawn(function()
    while State.Running do
        if Config.AutoSteal then
            local eggs = findEggs()
            -- sort by jarak terdekat
            local hrp = getHRP()
            if hrp then
                table.sort(eggs, function(a, b)
                    local da = (a.part.Position - hrp.Position).Magnitude
                    local db = (b.part.Position - hrp.Position).Magnitude
                    return da < db
                end)
            end

            for _, egg in ipairs(eggs) do
                if not Config.AutoSteal then break end
                local hrp2 = getHRP()
                if hrp2 and (egg.part.Position - hrp2.Position).Magnitude <= Config.StealRange then
                    stealEgg(egg)
                    task.wait(Config.StealDelay)
                end
            end

            returnToPlot()
            task.wait(0.1)
        else
            task.wait(0.3)
        end
    end
end)

--============================================================
-- AUTO PLACE
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoPlace then
            pcall(function()
                local plot = Workspace:FindFirstChild(LocalPlayer.Name .. "Plot")
                    or Workspace:FindFirstChild(LocalPlayer.Name .. "'s Plot")
                if plot then
                    local placePrompt = plot:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if placePrompt then
                        fireproximityprompt(placePrompt)
                    end
                end
            end)
            task.wait(Config.PlaceDelay)
        else
            task.wait(0.3)
        end
    end
end)

--============================================================
-- AUTO HATCH
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoHatch then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and string.find(string.lower(obj.ActionText or ""), "hatch") then
                        fireproximityprompt(obj)
                        task.wait(0.05)
                    end
                end
            end)
            task.wait(Config.HatchDelay)
        else
            task.wait(0.3)
        end
    end
end)

--============================================================
-- AUTO SELL
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoSell then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and string.find(string.lower(obj.ActionText or ""), "sell") then
                        fireproximityprompt(obj)
                        task.wait(0.05)
                    end
                end
            end)
            task.wait(Config.SellDelay)
        else
            task.wait(0.3)
        end
    end
end)

--============================================================
-- ANTI AFK
--============================================================
if Config.AntiAFK then
    table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0))
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0))
        end)
    end))
end

--============================================================
-- ANTI RAGDOLL
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AntiRagdoll then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.PlatformStand then
                    hum.PlatformStand = false
                end
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BallSocketConstraint") then
                        obj.Enabled = false
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

--============================================================
-- SPEED / JUMP OVERRIDE
--============================================================
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if hum.WalkSpeed ~= Config.WalkSpeed then
            hum.WalkSpeed = Config.WalkSpeed
        end
        if hum.JumpPower ~= Config.JumpPower then
            hum.JumpPower = Config.JumpPower
            hum.UseJumpPower = true
        end
    end
end)

--============================================================
-- INFINITE JUMP
--============================================================
table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

--============================================================
-- NOCLIP
--============================================================
RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

--============================================================
-- ESP MODULE
--============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CJ_ESP"
ESPFolder.Parent = CoreGui

local function createESP(target, color, text)
    local box = Instance.new("BillboardGui")
    box.Name = "CJ_ESP_" .. target.Name
    box.Adornee = target
    box.Size = UDim2.new(0, 100, 0, 40)
    box.AlwaysOnTop = true
    box.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or target.Name
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = box

    return box
end

task.spawn(function()
    while State.Running do
        -- clear
        for _, c in ipairs(ESPFolder:GetChildren()) do
            c:Destroy()
        end

        if Config.EggESP then
            for _, egg in ipairs(findEggs()) do
                createESP(egg.part, Color3.fromRGB(255, 215, 0), "🥚 " .. egg.obj.Name)
            end
        end

        if Config.PlayerESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        createESP(hrp, Color3.fromRGB(255, 80, 80), "👤 " .. plr.Name)
                    end
                end
            end
        end

        task.wait(0.5)
    end
end)

--============================================================
-- GET PLOT POSITION
--============================================================
task.spawn(function()
    while State.Running do
        pcall(function()
            local plot = Workspace:FindFirstChild(LocalPlayer.Name .. "Plot")
                or Workspace:FindFirstChild(LocalPlayer.Name .. "'s Plot")
            if plot then
                local base = plot:FindFirstChild("Spawn")
                    or plot:FindFirstChild("Base")
                    or plot.PrimaryPart
                if base then
                    State.PlotPos = base.Position + Vector3.new(0, 5, 0)
                end
            end
        end)
        task.wait(2)
    end
end)

--============================================================
-- UI (Draggable Custom)
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CJ_StealAEgg"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 420)
Main.Position = UDim2.new(0, 20, 0, 80)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Title.BorderSizePixel = 0
Title.Text = "🥚 STEAL A EGG | CJ BUILD"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local function makeToggle(text, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. text .. " : " .. tostring(Config[key])
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        btn.Text = "  " .. text .. " : " .. tostring(Config[key])
        btn.BackgroundColor3 = Config[key]
            and Color3.fromRGB(40, 90, 60)
            or Color3.fromRGB(30, 30, 40)
    end)
end

local function makeSlider(text, key, min, max)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 6)
    hc.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. " : " .. tostring(Config[key])
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = fill

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            Config[key] = val
            label.Text = text .. " : " .. tostring(val)
        end
    end)
end

--============================================================
-- BUILD UI
--============================================================
makeToggle("Auto Steal",    "AutoSteal")
makeSlider("Steal Delay",   "StealDelay", 0, 2)
makeSlider("Steal Range",   "StealRange", 50, 2000)
makeToggle("Return To Plot","ReturnToPlot")

makeToggle("Auto Place",    "AutoPlace")
makeToggle("Auto Hatch",    "AutoHatch")

makeToggle("Auto Sell",     "AutoSell")
makeSlider("Sell Delay",    "SellDelay", 0, 3)

makeToggle("Anti AFK",      "AntiAFK")
makeToggle("Anti Ragdoll",  "AntiRagdoll")
makeToggle("Infinite Jump", "InfiniteJump")
makeToggle("NoClip",        "NoClip")

makeSlider("WalkSpeed",     "WalkSpeed", 16, 200)
makeSlider("JumpPower",     "JumpPower", 50, 300)

makeToggle("Egg ESP",       "EggESP")
makeToggle("Player ESP",    "PlayerESP")

--============================================================
-- CLEANUP ON UNLOAD
--============================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    State.PlotPos = nil
end)

notify("CJ Build", "Script loaded. Gas lek. ☠️", 4)