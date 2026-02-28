-- Nome: Auto Lock Camera System
-- Tipo: LocalScript
-- Localização: Colocar dentro de StarterPlayerScripts ou StarterCharacterScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações do círculo (apenas referência lógica)
local CIRCLE_RADIUS = 150 -- pixels (tamanho do círculo na tela)
local CIRCLE_CENTER = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- Variáveis de estado
local currentTarget = nil
local lastTarget = nil

-- Função para verificar se um jogador está visível e tem linha de visão
local function isValidTarget(player)
    -- Ignorar próprio jogador
    if player == LocalPlayer then
        return false
    end
    
    -- Verificar se o personagem existe
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = character.HumanoidRootPart
    
    -- Verificar se está visível na tela
    local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    
    if not onScreen then
        return false
    end
    
    -- Calcular distância do centro da tela
    local screenPos2D = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (screenPos2D - CIRCLE_CENTER).Magnitude
    
    -- Verificar se está dentro do círculo
    if distanceFromCenter > CIRCLE_RADIUS then
        return false
    end
    
    -- Verificar linha de visão (Raycast)
    local cameraPos = Camera.CFrame.Position
    local direction = (rootPart.Position - cameraPos).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character, LocalPlayer.Character, Camera}
    
    local raycastResult = workspace:Raycast(cameraPos, direction * (cameraPos - rootPart.Position).Magnitude, raycastParams)
    
    -- Se não houve obstáculo, está visível
    return raycastResult == nil
end

-- Função para encontrar o melhor alvo dentro do círculo
local function findBestTarget()
    local bestTarget = nil
    local closestToCenter = CIRCLE_RADIUS + 1
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local screenPoint = Camera:WorldToViewportPoint(rootPart.Position)
                local screenPos2D = Vector2.new(screenPoint.X, screenPoint.Y)
                local distanceFromCenter = (screenPos2D - CIRCLE_CENTER).Magnitude
                
                -- Priorizar jogadores mais próximos do centro
                if distanceFromCenter < closestToCenter then
                    closestToCenter = distanceFromCenter
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget
end

-- Função para atualizar a câmera
local function updateCamera()
    -- Atualizar centro da tela (caso a janela seja redimensionada)
    CIRCLE_CENTER = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Encontrar melhor alvo
    currentTarget = findBestTarget()
    
    -- Aplicar lock na câmera se houver alvo
    if currentTarget then
        local character = currentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            -- Suavizar o movimento da câmera (opcional)
            local cameraCFrame = CFrame.new(Camera.CFrame.Position, rootPart.Position)
            Camera.CFrame = cameraCFrame
        end
    end
    
    -- Feedback visual (opcional - para debug)
    if currentTarget ~= lastTarget then
        if currentTarget then
            print("🔒 Camera locked on:", currentTarget.Name)
        elseif lastTarget then
            print("🔓 Camera unlocked from:", lastTarget.Name)
        end
        lastTarget = currentTarget
    end
end

-- Conectar ao RunService para atualização contínua
RunService.RenderStepped:Connect(updateCamera)

-- Mensagem inicial
print("✅ Auto Lock Camera System iniciado!")
print("📐 Raio do círculo:", CIRCLE_RADIUS, "pixels")