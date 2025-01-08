local Section = VisualsTab:CreateSection("Player esp")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local espEnabled = false
local tracersEnabled = false
local tracers = {}
local defaultColor = Color3.fromRGB(255, 255, 255)
local tracerColor = Color3.fromRGB(255, 255, 255)

local function createESP(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local head = character:WaitForChild("Head")

    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = false
    text.Font = 3
    text.Size = 15
    text.Color = Color3.fromRGB(255, 255, 255)

    local function removeESP()
        text.Visible = false
        text:Remove()
    end

    local function updateESP()
        if espEnabled and humanoid.Health > 0 then
            local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (head.Position - LocalPlayer.Character.Head.Position).Magnitude
                text.Position = Vector2.new(screenPosition.X, screenPosition.Y - 27)
                text.Text = string.format("[ %s | %d studs | %d/%d HP ]", player.Name, math.floor(distance), math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
                text.Visible = true
            else
                text.Visible = false
            end
        else
            text.Visible = false
        end
    end

    RunService.RenderStepped:Connect(updateESP)
    humanoid.Died:Connect(removeESP)
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP()
        end
    end)
end

local function createTracer(player)
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Transparency = 1
    line.Visible = false
    tracers[player] = line
end

local function removeTracer(player)
    if tracers[player] then
        tracers[player]:Remove()
        tracers[player] = nil
    end
end

local function updateTracers()
    if not tracersEnabled then 
        for _, line in pairs(tracers) do
            line.Visible = false
        end
        return 
    end

    for player, line in pairs(tracers) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                line.Visible = true
                line.Color = tracerColor
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(screenPosition.X, screenPosition.Y)
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        createTracer(player)
        if player.Character then
            createESP(player, player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            createESP(player, character)
        end)
    end
end

local function onPlayerRemoving(player)
    removeTracer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

RunService.RenderStepped:Connect(updateTracers)

local ToggleESP = VisualsTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        espEnabled = Value
    end,
})

local ToggleTracers = VisualsTab:CreateToggle({
    Name = "Tracers Enabled",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(Value)
        tracersEnabled = Value
    end,
})

local TracerColorPicker = VisualsTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "TracerColor",
    Callback = function(Value)
        tracerColor = Value
    end,
})

local Section = VisualsTab:CreateSection("Extra esp")

local pileFolder = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedPiles")
if not pileFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart, customName)
    if basePart:FindFirstChild("ESP_Indicator") then return end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui
    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    if espEnabled and obj.Name == "P" then
        local basePart = findBasePart(obj)
        if basePart then
            createESP(basePart, "Gift(event)")
        end
    end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(pileFolder:GetChildren()) do
        processObject(child)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

pileFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        processObject(child)
    end
end)

pileFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}
            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("%s\n%d studs", espData.label.Text:split("\n")[1], distance)
                else
                    table.insert(toRemove, basePart)
                end
            end
            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end
        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Gift ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local folder = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedTools")
if not folder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart, customName)
    if not basePart or basePart:FindFirstChild("ESP_Indicator") then return end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui
    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    if espEnabled and obj.Name == "Model" then
        local basePart = findBasePart(obj)
        if basePart then
            createESP(basePart, "tool")
        end
    end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(folder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

folder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

folder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}
            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("tool\n%d studs", distance)
                else
                    table.insert(toRemove, basePart)
                end
            end
            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end
        task.wait(0.2)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Tool ESP",
    CurrentValue = false,
    Flag = "Tool_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local breadFolder = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedBread")
if not breadFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart, customName)
    if basePart:FindFirstChild("ESP_Indicator") then return end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui
    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    if espEnabled and obj.Name == "CashDrop1" then
        local basePart = findBasePart(obj)
        if basePart then
            createESP(basePart, "Cash")
        end
    end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(breadFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

breadFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

breadFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}
            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("Cash\n%d studs", distance)
                else
                    table.insert(toRemove, basePart)
                end
            end
            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end
        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "CashDrop ESP",
    CurrentValue = false,
    Flag = "CashDrop_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local pileFolder = workspace:FindFirstChild("Filter") and workspace.Filter:FindFirstChild("SpawnedPiles")
if not pileFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart, customName)
    if basePart:FindFirstChild("ESP_Indicator") then return end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui
    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    if espEnabled and (obj.Name == "S1" or obj.Name == "S2") then
        local basePart = findBasePart(obj)
        if basePart then
            createESP(basePart, "garbage")
        end
    end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(pileFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

pileFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

pileFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}
            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("garbage\n%d studs", distance)
                else
                    table.insert(toRemove, basePart)
                end
            end
            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end
        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Trash ESP",
    CurrentValue = false,
    Flag = "Trash_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local bredFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("BredMakurz")
if not bredFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function determineCustomName(name)
    if name:match("^MediumSafe") then
        return "MediumSafe"
    elseif name:match("^SmallSafe") then
        return "SmallSafe"
    elseif name:match("^Register") then
        return "Register"
    end
    return nil
end

local function createESP(basePart, customName)
    if basePart:FindFirstChild("ESP_Indicator") then return end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui
    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel,
        customName = customName
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    local customName = determineCustomName(obj.Name)
    if not customName then return end
    local basePart = findBasePart(obj)
    if basePart then createESP(basePart, customName) end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(bredFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

bredFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

bredFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}
            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("%s\n%d studs", espData.customName, distance)
                else
                    table.insert(toRemove, basePart)
                end
            end
            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end
        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Safes and Registers ESP",
    CurrentValue = false,
    Flag = "Safes_Registers_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local shopFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shopz")
if not shopFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function getCustomName(objName)
    if objName == "Dealer" then
        return "Dealer"
    elseif objName == "ArmoryDealer" then
        return "ArmoryDealer"
    end
    return nil
end

local function createESP(basePart, customName)
    if basePart:FindFirstChild("ESP_Indicator") then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = customName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui

    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    local customName = getCustomName(obj.Name)
    if customName then
        local basePart = findBasePart(obj)
        if basePart then
            createESP(basePart, customName)
        end
    end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(shopFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

shopFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

shopFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}

            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("%s\n%d studs", espData.label.Text:split("\n")[1], distance)
                else
                    table.insert(toRemove, basePart)
                end
            end

            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end

        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Dealers ESP",
    CurrentValue = false,
    Flag = "Dealers_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local vendingMachinesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("VendingMachines")
if not vendingMachinesFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart)
    if basePart:FindFirstChild("ESP_Indicator") then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = "VendingMachine"
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui

    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    local basePart = findBasePart(obj)
    if basePart then createESP(basePart) end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(vendingMachinesFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

vendingMachinesFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

vendingMachinesFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}

            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("VendingMachine\n%d studs", distance)
                else
                    table.insert(toRemove, basePart)
                end
            end

            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end

        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "Vending Machines ESP",
    CurrentValue = false,
    Flag = "VendingMachines_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

local atmFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ATMz")
if not atmFolder then return end

local player = game.Players.LocalPlayer
local humanoidRootPart
local espObjects = {}
local espEnabled = false

local function updateHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

updateHumanoidRootPart()
player.CharacterAdded:Connect(updateHumanoidRootPart)

local function findBasePart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
end

local function createESP(basePart)
    if basePart:FindFirstChild("ESP_Indicator") then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Indicator"
    billboardGui.Adornee = basePart
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = basePart

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = "ATM"
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Parent = billboardGui

    espObjects[basePart] = {
        gui = billboardGui,
        label = textLabel
    }
end

local function removeESP(basePart)
    if espObjects[basePart] then
        espObjects[basePart].gui:Destroy()
        espObjects[basePart] = nil
    end
end

local function processObject(obj)
    local basePart = findBasePart(obj)
    if basePart then createESP(basePart) end
end

local function enableESP()
    espEnabled = true
    for _, child in ipairs(atmFolder:GetChildren()) do
        task.defer(function()
            processObject(child)
        end)
    end
end

local function disableESP()
    espEnabled = false
    for basePart, _ in pairs(espObjects) do
        removeESP(basePart)
    end
end

atmFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.defer(function()
            processObject(child)
        end)
    end
end)

atmFolder.ChildRemoved:Connect(function(child)
    local basePart = findBasePart(child)
    if basePart then removeESP(basePart) end
end)

task.spawn(function()
    while true do
        if espEnabled and humanoidRootPart then
            local humanoidPosition = humanoidRootPart.Position
            local toRemove = {}

            for basePart, espData in pairs(espObjects) do
                if basePart:IsDescendantOf(workspace) then
                    local distance = math.floor((humanoidPosition - basePart.Position).Magnitude)
                    espData.label.Text = string.format("ATM\n%d studs", distance)
                else
                    table.insert(toRemove, basePart)
                end
            end

            for _, basePart in ipairs(toRemove) do
                removeESP(basePart)
            end
        end

        task.wait(1)
    end
end)

local Toggle = VisualsTab:CreateToggle({
    Name = "ATM ESP",
    CurrentValue = false,
    Flag = "ATM_ESP_Toggle",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})
