function UpdateSave()
  local dataToSave = {
    ["availableMoney"] = availableMoney
  }
  local savedData = JSON.encode(dataToSave)
  self.script_state = savedData
end

function onLoad(savedData)
  colorPlayer = {
    ["White"] = {r = 1, g = 1, b = 1},
    ["Red"] = {r = 0.86, g = 0.1, b = 0.09},
    ["Blue"] = {r = 0.12, g = 0.53, b = 1},
    ["Green"] = {r = 0.19, g = 0.7, b = 0.17},
    ["Yellow"] = {r = 0.9, g = 0.9, b = 0.17},
    ["Orange"] = {r = 0.96, g = 0.39, b = 0.11},
    ["Brown"] = {r = 0.44, g = 0.23, b = 0.09},
    ["Purple"] = {r = 0.63, g = 0.12, b = 0.94},
    ["Pink"] = {r = 0.96, g = 0.44, b = 0.81},
    ["Teal"] = {r = 0.13, g = 0.69, b = 0.61}
  }
  availableMoney = 0
  if(savedData ~= "") then
    local loadedData = JSON.decode(savedData)
    availableMoney = loadedData.availableMoney or availableMoney
  end

  originalXml = self.UI.getXml()
  currentColor = DenoteSth()
  totalGoods = 0
  ChangeVisibility()
end

function onFixedUpdate()
  if(currentColor ~= DenoteSth()) then
    currentColor = DenoteSth()
    ChangeVisibility()
  end
end

function ChangeVisibility()
  local allXml = originalXml

  local searchString = "visibility="
  local searchStringLength = #searchString

  local indexVisibility = allXml:find(searchString)
  local startXml = allXml:sub(1, indexVisibility + searchStringLength)
  local strVis = "Black|" .. currentColor
  local endXml = allXml:sub(indexVisibility + searchStringLength + 1)

  allXml = startXml .. strVis .. endXml

  self.UI.setXml(allXml)
end

function CheckMoney(player)
  local messageText
  if(Player[currentColor].steam_name or Player["Black"].steam_name) then
    messageText = "В кошельке " .. availableMoney .. " монет"
    local locCurrentPlayer = Player[currentColor].steam_name and currentColor
    if(locCurrentPlayer) then
      broadcastToColor(messageText, currentColor, currentColor)
    else
      locCurrentPlayer = Player["Black"].steam_name and "Black"
      if(locCurrentPlayer) then
        broadcastToColor(messageText, "Black", currentColor)
      end
    end
  elseif(Player["Black"].steam_name and CheckPlayer(player.color)) then
    messageText = (player.steam_name or currentColor) .. " проверил кошелек\n"
    messageText = messageText .. "У него сейчас " .. availableMoney
    broadcastToColor(messageText, "Black", currentColor)
  end
end

function UpdateCountMoney(parametrs)
  totalGoods = totalGoods + tonumber(parametrs.value)
end

function SetInputMoney(player, input)
  if(input ~= "") then
    local locMoney = availableMoney + tonumber(input)
    if(locMoney < 0) then
      local locCurrentColor = (Player[currentColor].steam_name and currentColor) or "Black"
      broadcastToColor("У вас недостаточно денег", locCurrentColor, currentColor)
      return
    end
    availableMoney = availableMoney + tonumber(input)
    self.UI.setAttribute("setMoney", "text", "")
    CheckMoney(player)
  end
  UpdateSave()
end

function CheckPlayer(playerColor)
	if(DenoteSth() == playerColor) then
    return true
  end
  if(playerColor ~= "Black") then
    broadcastToAll("Эта дощечка не вашего цвета!")
  end
  return false
end

function DenoteSth()
	local color = ""
  for iColor,_ in pairs(colorPlayer) do
    if(CheckColor(iColor)) then
	    color = iColor
      break
    end
  end
  return color
end

function CheckColor(color)
  local colorObject = {
    ["R"] = Round(self.getColorTint()[1], 2),
    ["G"] = Round(self.getColorTint()[2], 2),
    ["B"] = Round(self.getColorTint()[3], 2)
  }
	if(colorObject.R == colorPlayer[color].r and colorObject.G == colorPlayer[color].g and colorObject.B == colorPlayer[color].b) then
    return true
  else
    return false
  end
end

function Round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function GetAvailableMoney()
  if(totalGoods) then
    return availableMoney - totalGoods
  end
end