function UpdateSave()
  local dataToSave = {
    ["allStoresGUID"] = allStoresGUID,
    ["replacementXml"] = self.UI.getXml(), ["previousStoreId"] = previousStoreId
  }
  local savedData = JSON.encode(dataToSave)
  self.script_state = savedData
end

function CreateGlobalVariable()
  readyScriptUnderBag = [[
function UpdateSave()
  local dataToSave = {
    ["allObjMeta"] = allObjMeta
  }
  local savedData = JSON.encode(dataToSave)
  self.script_state = savedData
end

function onLoad(savedData)
  allObjMeta = {}
  if(savedData ~= "") then
    local loadedData = JSON.decode(savedData)
    allObjMeta = loadedData.allObjMeta or allObjMeta
  end
end

function SetObjMetaBag(parametrs)
  local pos, rot
  for i = 1, #parametrs.positions do
    pos = parametrs.positions[i].x.." "..parametrs.positions[i].y.." "..parametrs.positions[i].z
    rot = parametrs.rotations[i].x.." "..parametrs.rotations[i].y.." "..parametrs.rotations[i].z

    table.insert(allObjMeta, {parametrs.objGUID[i], pos, rot, self.getGUID()})
    allObjMeta[i][1] = parametrs.objGUID[i]
  end
  UpdateSave()
end

function GetObjectMetaBag()
  return allObjMeta
end
]]
  readyScriptUnderItem = [[
function CreateButton()
  self.createButton({
    click_function = "SelectItem", function_owner = self,
    position = {0, 0.1, 0}, height = 500, width = 500,
    color = {0.75, 0.25, 0.25, 0.6},
  })
end

function onLoad()
  Wait.frames(|| CreateButton(), 10)
  itemCostDiscount = nil
  thingsInBasket, countItem, itemCost = {}, 0, -1

  local prev_flag = false
  for word in string.gmatch(self.getDescription(), "%S+") do
    if(prev_flag) then
      word = word:gsub(",", ".")
      itemCost = tonumber(word)
      break
    end
    if(word:lower() == "cost:" or word:lower() == "цена:") then
      prev_flag = true
    end
  end
  if(itemCost < 0) then
    print("Предмету не задана стоимость(либо стоимость предмета ниже нуля)")
    print("После задания стоимости пересоздайте магазин, дабы цена вступила в силу")
  end
end

function GiveDiscountItem(parametrs)
  itemCostDiscount = itemCost + itemCost*parametrs.discount/100
end

function EndTrade()
  thingsInBasket, countItem = {}, 0
  itemCostDiscount = nil
end

function SetCoinPouchGUID(parametrs)
  local CoinPouchGUID = parametrs.guid
  CoinPouch = getObjectFromGUID(CoinPouchGUID)
end

function SelectItem(obj, playerColor, altClick)
  if(altClick and countItem > 0) then
    if(CoinPouch) then
      CoinPouch.call("UpdateCountMoney", {value = itemCostDiscount or itemCost})
      broadcastToColor("Вы отказались от товара", playerColor)
      broadcastToColor("Сейчас у вас: " .. CoinPouch.call("GetAvailableMoney"), playerColor)

      local delItem = thingsInBasket[countItem]
      destroyObject(delItem)
      table.remove(thingsInBasket, countItem)
      countItem = countItem - 1
    end
    return
  end
        
  if(CoinPouch) then
    local availableMoney = CoinPouch.call("GetAvailableMoney")
    if(CoinPouch and itemCost <= availableMoney) then
      CoinPouch.call("UpdateCountMoney", {value = -(itemCostDiscount or itemCost)})
      broadcastToColor("Вы приобрели товар", playerColor)
      broadcastToColor("У вас осталось: " .. CoinPouch.call("GetAvailableMoney"), playerColor)

      SpawnItemObject()
    else
      broadcastToColor("Вам не хватает средств", playerColor)
    end
  else
    print("А чем расплачиваться собрались?")
  end
end
function SpawnItemObject()
  local selfPosition = CoinPouch.getPosition()
  local selfRotation = CoinPouch.getRotation()
  local spawnParametrs = {
    json = self.getJSON(),
    position = {x = selfPosition.x - 5, y = selfPosition.y + countItem + 2, z = selfPosition.z},
    rotation = selfRotation,
    scale = {x = 1, y = 1, z = 1},
    sound = false,
    snap_to_grid = true,
  }
  local spawnItem = spawnObjectJSON(spawnParametrs)
  spawnItem.setLuaScript("")
  table.insert(thingsInBasket, spawnItem)
  countItem = countItem + 1
end
]]

  shopName = {
    tag = "Row",
    attributes = {
      preferredHeight = 80
    },
    children = {
      {
        tag = "Cell",
        attributes = {
        },
        children = {
          {
            tag = "InputField",
            attributes = {
              id = "00",
              text = "storename",
              resizeTextForBestFit = "True",
              resizeTextMaxSize = "60",
              onEndEdit = "UpdateXMLSave"
            }
          }
        },
      }
    }
  }
  shopButton = {
    tag = "Row",
    attributes = {
      preferredHeight = 80
    },
    children = {
      {
        tag = "Cell",
        attributes = {
        },
        children = {
          {
            tag = "Button",
            attributes = {
              id = "00",
              text = "↑",
              resizeTextForBestFit = "True",
              resizeTextMaxSize = "60",
              onClick = "ShowcaseMerchandise"
            }
          },
          {
            tag = "Button",
            attributes = {
              text = "↓",
              resizeTextForBestFit = "True",
              resizeTextMaxSize = "60",
              onClick = "HidecaseMerchandise"
            }
          },
          {
            tag = "Button",
            attributes = {
              id = "00",
              text = "+",
              resizeTextForBestFit = "True",
              resizeTextMaxSize = "60",
              onClick = "TestAddNewList"
            }
          },
        },
      }
    }
  }

  allStoresGUID = {}
  showGUIDBag = ""

  allObjectsItemGUID = {}
  watchword = {"sell item", "coin pouch"}
  CoinPouchGUID = ""
  -- Не отнимаемое значение.
  --Нужно чтобы грамотно отлавливать новые магазины после удаления какого либо из середины списка
  previousStoreId = 1
end

function onLoad(savedData)
  CreateGlobalVariable()
  if(savedData ~= "") then
    local loadedData = JSON.decode(savedData)
    allStoresGUID = loadedData.allStoresGUID or allStoresGUID
    previousStoreId = loadedData.previousStoreId or previousStoreId
    if(loadedData.replacementXml and #loadedData.replacementXml > 0) then
      self.UI.setXml(loadedData.replacementXml)
    end
  end
  Wait.frames(|| WasteRemoval(), 5)
end

function WasteRemoval()
  local countBags = 0
  for index, guid in pairs(allStoresGUID) do
    countBags = 1
    if(not getObjectFromGUID(guid)) then
      allStoresGUID[tostring(index)] = nil
    end
  end
  if(countBags == 0) then previousStoreId = 1 end
  UpdateSave()
end
-- Хз как реализовать
function TestAddNewList(_, _, idStoreGUID)
  print("Пока в разработке")
end

function onCollisionEnter(info)
  if(info.collision_object.getGMNotes():lower():find(watchword[1])) then
    for _, v in ipairs(allObjectsItemGUID) do
      if(v == info.collision_object.getGUID()) then
        return
      end
    end
    table.insert(allObjectsItemGUID, info.collision_object.getGUID())
  elseif(info.collision_object.getGMNotes():lower():find(watchword[2])) then
    Wait.frames(|| SetNumberCoinsObjects(info), 5)
  end
end
function onCollisionExit(info)
  if(allObjectsItemGUID) then
    if(info.collision_object.getGMNotes():lower():find(watchword[1])) then
      local removeId = -1
      for i, v in ipairs(allObjectsItemGUID) do
        if(v == info.collision_object.getGUID()) then
          removeId = i
        end
      end
      if(removeId > 0) then
        table.remove(allObjectsItemGUID, removeId)
      end
    elseif(info.collision_object.getGMNotes():lower():find(watchword[2])) then
      Wait.frames(|| SetNumberCoinsObjects(), 5)
    end
  end
end
function SetNumberCoinsObjects(info)
  CoinPouchGUID = (info and info.collision_object.getGUID()) or ""
  for _, guid in ipairs(allObjectsItemGUID) do
    Wait.frames(|| SetCoinPouchGUIDIn(guid), 30)
  end
end
function SetCoinPouchGUIDIn(guidItem)
  getObjectFromGUID(guidItem).call("SetCoinPouchGUID", {guid = CoinPouchGUID})
end

function onObjectDestroy(info)
  DeleteItem(info.getGUID())
  DeleteBag(info.getGUID())
end
function DeleteItem(guid)
  for i, v in ipairs(allObjectsItemGUID) do
    if(v == guid) then
      table.remove(allObjectsItemGUID, i)
    end
  end
end
function DeleteBag(guid)
  -- lua не умеет выдергивать длину массива если он не проходит через ipairs
  local indexStoreId = 1
  for _, g in pairs(allStoresGUID) do
    if(g == guid) then
      XMLReplacementDelete((indexStoreId - 1)*2 + 1)
      Wait.frames(|| WasteRemoval(), 5)
      Wait.frames(|| UpdateSave(), 7)
      return
    end
    indexStoreId = indexStoreId + 1
  end
end

function CreateBag()
  if(#allObjectsItemGUID > 0) then
    Wait.frames(|| CreateScriptInItem(), 30)
    Wait.frames(|| PutObjectsInBag(), 60)
  end
end
function CreateScriptInItem()
  print("Adding scripts from item")
  for _, guid in ipairs(allObjectsItemGUID) do
    getObjectFromGUID(guid).setLuaScript(readyScriptUnderItem)
  end
  UpdateSave()
end
function PutObjectsInBag()
  local selfPosition = self.getPosition()
  local spawnParametrs = {
    type = "Bag",
    position = {x = selfPosition.x, y = selfPosition.y + 2, z = selfPosition.z - 7},
    rotation = {x = 0, y = 0, z = 0},
    scale = {x = 0.5, y = 0.5, z = 0.5},
    sound = false,
    snap_to_grid = true,
  }
  local locBoardObjectsPos, locBoardObjectsRot, locObjGUID = {}, {}, {}
  local spawnBag = spawnObject(spawnParametrs)
  Wait.frames(|| CreateScriptInBag(spawnBag), 2)
  for _, v in ipairs(allObjectsItemGUID) do
    local locObj = getObjectFromGUID(v)

    spawnBag.putObject(locObj)

    table.insert(locBoardObjectsPos, locObj.getPosition() - self.getPosition())
    table.insert(locBoardObjectsRot, locObj.getRotation())
    Wait.frames(|| table.insert(locObjGUID, locObj.getGUID()), 3)
  end
  Wait.frames(function() allStoresGUID[tostring(previousStoreId)] = spawnBag.getGUID() end, 4)
  Wait.frames(|| SetObjMeta(spawnBag, locObjGUID, locBoardObjectsPos, locBoardObjectsRot), 5)
  Wait.frames(|| XMLReplacementAdd(), 6)
  Wait.frames(|| UpdateSave(), 7)
end
function CreateScriptInBag(bag)
  print("Adding scripts from bag")
  bag.setLuaScript(readyScriptUnderBag)
end
function SetObjMeta(bag, objGUID, locBoardObjectsPos, locBoardObjectsRot)
  local parametrs = {rotations = locBoardObjectsRot, positions = locBoardObjectsPos, objGUID = objGUID}
  bag.call("SetObjMetaBag", parametrs)
  showGUIDBag = ""
end

function ShowcaseMerchandise(player, _, idStoreGUID)
  local storeGUID = allStoresGUID[idStoreGUID]
  local store = getObjectFromGUID(storeGUID)
  if(store) then
    showGUIDBag = storeGUID
    GetObjectsBag(storeGUID, store)
  else
    print("Этот магазин был удален")
    local indexStoreId = 1
    for _, g in pairs(allStoresGUID) do
      if(g == guid) then
        XMLReplacementDelete((indexStoreId - 1)*2 + 1)
        Wait.frames(|| UpdateSave(), 5)
        break
      end
      indexStoreId = indexStoreId + 1
    end
  end
  UpdateSave()
end
function GetObjectsBag(storeGUID, store)
  local allObjMeta = store.call("GetObjectMetaBag")
  if(not next(allObjectsItemGUID)) then
    for _,v in ipairs(allObjMeta) do
      if(v[4] == storeGUID) then
        local objGUID = v[1]

        local locText, count = v[2], 1
        local objPos = {}
        for digital in locText:gmatch("%S+") do
          table.insert(objPos, digital + self.getPosition()[count])
          count = count + 1
        end
        objPos[2] = self.getPosition().y + 0.5
      
        locText, count = v[3], 1
        local objRot = {}
        for digital in locText:gmatch("%S+") do
          table.insert(objRot, digital)
          count = count + 1
        end

        local takeParametrs = {
          smooth = false,
          guid = objGUID,
          position = {x = objPos[1], y = objPos[2], z = objPos[3]},
          rotation = {x = objRot[1], y = objRot[2], z = 0}
        }
        local storItem = store.takeObject(takeParametrs)
        -- Пока хз, добавить это или нет
        --storItem.locked = true
        --print(storItem.locked)
      end
    end
  end
end

function HidecaseMerchandise()
  local store = getObjectFromGUID(showGUIDBag)
  if(store) then
    local allObjMeta = store.call("GetObjectMetaBag")
    for _, objGUID in ipairs(allObjectsItemGUID) do
      for _, objMeta in ipairs(allObjMeta) do
        if(store and objGUID == objMeta[1] and showGUIDBag == objMeta[4]) then
          getObjectFromGUID(objGUID).call("EndTrade")
          store.putObject(getObjectFromGUID(objMeta[1]))
        end
      end
    end
  end
  self.UI.setAttribute("discountField", "text", "")
end

function UpdateXMLSave(_, input, id)
  id = tostring(id)
  local currentXml = self.UI.getXml()
  if(currentXml:find("storename" .. id)) then
    local firstIndex = currentXml:find("storename" .. id) - 1
    local locXml = currentXml:sub(0, firstIndex)
    locXml = locXml .. input
    local lastIndex = firstIndex + #("storename" .. id) + 1
    locXml = locXml .. currentXml:sub(lastIndex)
    self.UI.setXml(locXml)
	  Wait.frames(|| UpdateSave(), 5)
  end
end

function GiveDiscount(_, input)
  if(input and input == "") then return end

  local numInput = math.abs(tonumber(input))
  if(numInput > 0) then
    broadcastToColor("The cost of the items has been increased by "..numInput.."%", "Black")
  else
    broadcastToColor("The cost of the items has been decreased by "..numInput.."%", "Black")
  end

  for _,guid in pairs(allObjectsItemGUID) do
    local item = getObjectFromGUID(guid)
    if(item) then
      item.call("GiveDiscountItem", {discount = input})
    else
      print("Какие то проблемы с выдачей скидки")
    end
  end
end

function EnlargeHeightPanelStat(countStatisticIndex)
  if(countStatisticIndex > 4 * 2) then
    --preferredHeight=160 cellSpacing=5
    local newHeightPanel = countStatisticIndex * 160 + countStatisticIndex * 5
    Wait.Frames(|| self.UI.setAttribute("tableLayoutShop", "height", newHeightPanel), 5)
  end
end

function XMLReplacementAdd()
  local xmlTable, desiredTable = {}, false
  xmlTable = self.UI.getXmlTable()
  for _,xml in pairs(xmlTable) do
	  for _,parent in pairs(xml) do
      if(type(parent) == "table") then
        for _,children in pairs(parent) do
          if(type(children) == "table") then
            for _,child in pairs(children) do
              if(type(child) == "table") then
                for _,ch in pairs(child) do
                  if(type(ch) == "table") then
                    for title,attribute in pairs(ch) do
                      -- Сложно не понятная фигня. Уже и забыл как работает
                      if(attribute["id"] and attribute["id"]:find("tableLayoutShop")) then
                        desiredTable = true
                      end
                      if(desiredTable and title == "children") then
                        local shopNameText = shopName.children[1].children[1].attributes.text
                        if(shopNameText == "storename") then shopName.children[1].children[1].attributes.text = shopNameText .. previousStoreId end
                        shopName.children[1].children[1].attributes.id = previousStoreId
                        table.insert(attribute, shopName)

                        shopButton.children[1].children[1].attributes.id = previousStoreId
                        shopButton.children[1].children[3].attributes.id = previousStoreId
                        table.insert(attribute, shopButton)
                        self.UI.setXmlTable(xmlTable)
                        desiredTable = false

                        -- Вернем балванке стандартный текст
                        Wait.frames(function() shopName.children[1].children[1].attributes.text = "storename" end, 5)
                        Wait.frames(|| EnlargeHeightPanelStat(previousStoreId), 5)
                        Wait.frames(|| UpdateSave(), 7)
                        previousStoreId = previousStoreId + 1
                        return
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
function XMLReplacementDelete(storeId)
  local xmlTable, desiredTable = {}, false
  xmlTable = self.UI.getXmlTable()
  for _,xml in pairs(xmlTable) do
	  for _,parent in pairs(xml) do
      if(type(parent) == "table") then
        for _,children in pairs(parent) do
          if(type(children) == "table") then
            for _,child in pairs(children) do
              if(type(child) == "table") then
                for _,ch in pairs(child) do
                  if(type(ch) == "table") then
                    for title,attribute in pairs(ch) do
                      -- Сложно не понятная фигня. Уже и забыл как работает
                      if(attribute["id"] and attribute["id"]:find("tableLayoutShop")) then
                        desiredTable = true
                      end
                      if(desiredTable and title == "children") then
                        table.remove(attribute, storeId)
                        table.remove(attribute, storeId)
                        self.UI.setXmlTable(xmlTable)
                        desiredTable = false

                        Wait.frames(|| UpdateSave(), 5)
                        return
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end