function UpdateSave()
  local dataToSave = {
    ["allStoresGUID"] = allStoresGUID,
    ["newXml"] = self.UI.getXml(), ["lastIdStore"] = lastIdStore
  }
  local savedData = JSON.encode(dataToSave)
  self.script_state = savedData
end

local shopName = {
  tag = "Row",
  attributes = {
    preferredHeight = 80,
    characterValidation = Name
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
            resizeTextForBestFit = "True",
            resizeTextMaxSize = "60"
          }
        }
      },
    }
  }
}

local shopButton = {
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
            text = "Выложить",
            resizeTextForBestFit = "True",
            resizeTextMaxSize = "60",
            onClick = "ShowcaseMerchandise"
          }
        },
        {
          tag = "Button",
          attributes = {
            text = "Сложить",
            resizeTextForBestFit = "True",
            resizeTextMaxSize = "60",
            onClick = "HidecaseMerchandise"
          }
        },
      },
    }
  }
}

function onLoad(savedData)
  allStoresGUID = {}
  lastIdStore = 1
  showGUIDBag = ""
  if(savedData ~= "") then
    local loadedData = JSON.decode(savedData)
    allStoresGUID = loadedData.allStoresGUID or allStoresGUID
    if(loadedData.newXml and #loadedData.newXml > 0) then
      self.UI.setXml(loadedData.newXml)
    end
  end
  allObjectsGUID = {}
  watchword = {"sell item", "coin pouch"}
  CoinPouchGUID = ""
end

function Test()
  local desiredTable = false
  local xmlTable = {}
  xmlTable = self.UI.getXmlTable()
  for _,xml in pairs(xmlTable) do
	  for _,parent in pairs(xml) do
      if(type(parent) == "table") then
        for _,children in pairs(parent) do
          if(type(children) == "table") then
            for title,attribute in pairs(children) do
	            if(attribute["id"] and attribute["id"]:find("tableLayoutShop")) then
                desiredTable = true
              end
              if(desiredTable and title == "children") then
                table.insert(attribute, shopName)
                shopButton.children[1].children[1].attributes.id = lastIdStore
                lastIdStore = lastIdStore + 1
                table.insert(attribute, shopButton)
                self.UI.setXmlTable(xmlTable)
                desiredTable = false
              end
            end
          end
        end
      end
    end
  end
end

function TestDelete(index)
  local desiredTable = false
  local xmlTable = {}
  xmlTable = self.UI.getXmlTable()
  for _,xml in pairs(xmlTable) do
	  for _,parent in pairs(xml) do
      if(type(parent) == "table") then
        for _,children in pairs(parent) do
          if(type(children) == "table") then
            for title,attribute in pairs(children) do
	            if(attribute["id"] and attribute["id"]:find("tableLayoutShop")) then
                desiredTable = true
              end
              if(desiredTable and title == "children") then
                table.remove(attribute, index)
                table.remove(attribute, index)
                self.UI.setXmlTable(xmlTable)
                desiredTable = false
              end
            end
          end
        end
      end
    end
  end
end

function onCollisionEnter(info)
  if(allObjectsGUID) then
    if(info.collision_object.getGMNotes():lower():find(watchword[1])) then
      for _, v in ipairs(allObjectsGUID) do
        if(v == info.collision_object.getGUID()) then
          return
        end
      end
      table.insert(allObjectsGUID, info.collision_object.getGUID())
    elseif(info.collision_object.getGMNotes():lower():find(watchword[2])) then
      Wait.frames(|| SetNumberCoinsObjects(info), 5)
    end
  end
end

function SetNumberCoinsObjects(info)
  CoinPouchGUID = info.collision_object.getGUID()
  for _, guid in ipairs(allObjectsGUID) do
    local obj = getObjectFromGUID(guid)
    Wait.frames(|| SetCoinPouchGUIDIn(obj), 30)
  end
end

function onCollisionExit(info)
  if(allObjectsGUID) then
    if(info.collision_object.getGMNotes():lower():find(watchword[1])) then
      local removeId = -1
      for i, v in ipairs(allObjectsGUID) do
        if(v == info.collision_object.getGUID()) then
          removeId = i
        end
      end
      if(removeId > 0) then
        table.remove(allObjectsGUID, removeId)
      end
    elseif(info.collision_object.getGMNotes():lower():find(watchword[2])) then
      CoinPouchGUID = ""
    end
  end
end

function onObjectDestroy(info)
  for i, v in ipairs(allObjectsGUID) do
    if(v == info.getGUID()) then
      table.remove(allObjectsGUID, i)
    end
  end
  DeleteBag(info.getGUID())
end

function CreateBag()
  if(#allObjectsGUID > 0) then
    Wait.frames(|| CreateScriptInItem(), 30)
    Wait.frames(|| PutObjectsInBag(), 60)
  end
end

function PutObjectsInBag()
  print("Scripts items added")
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
  for _, v in ipairs(allObjectsGUID) do
    local locObj = getObjectFromGUID(v)

    spawnBag.putObject(locObj)

    table.insert(locBoardObjectsPos, locObj.getPosition() - self.getPosition())
    table.insert(locBoardObjectsRot, locObj.getRotation())
    Wait.frames(|| table.insert(locObjGUID, locObj.getGUID()), 3)
  end
  Wait.frames(|| table.insert(allStoresGUID, spawnBag.getGUID()), 4)
  Wait.frames(|| SetObjMeta(spawnBag, locObjGUID, locBoardObjectsPos, locBoardObjectsRot), 5)
  Wait.frames(|| Test(), 6)
  Wait.frames(|| UpdateSave(), 7)
end

function DeleteBag(guid)
  for index,v in ipairs(allStoresGUID) do
    if(v == guid) then
      ButtonDelete(index)
    end
  end
  Wait.frames(|| UpdateSave(), 7)
end

function ButtonDelete(index)
  TestDelete(index)
end

function SetObjMeta(bag, objGUID, locBoardObjectsPos, locBoardObjectsRot)
  local parametrs = {rotations = locBoardObjectsRot, positions = locBoardObjectsPos, objGUID = objGUID}
  bag.call("SetObjMetaBag", parametrs)
  showGUIDBag = ""
end

function ShowcaseMerchandise(player, _, idStoreGUID)
  idStoreGUID = tonumber(idStoreGUID)
  local storeGUID = allStoresGUID[idStoreGUID]
  if(getObjectFromGUID(storeGUID)) then
    GetObjectsBag(storeGUID)
  else
    table.remove(allStoresGUID, idStoreGUID)
  end
  UpdateSave()
end

function GetObjectsBag(storeGUID)
  local store = getObjectFromGUID(storeGUID)
  showGUIDBag = storeGUID
  local allObjMeta = store.call("GetObjectMetaBag")
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
        rotation = {x = objRot[1], y = objRot[2], z = objRot[3]}
      }
      local storItem = store.takeObject(takeParametrs)
      -- Пока хз, добавить это или нет
      --storItem.locked = true
      --print(storItem.locked)
    end
  end
end

function HidecaseMerchandise()
  local store = getObjectFromGUID(showGUIDBag)
  local allObjMeta = store.call("GetObjectMetaBag")
  for _, objGUID in ipairs(allObjectsGUID) do
    for _, objMeta in ipairs(allObjMeta) do
      if(store and objGUID == objMeta[1] and showGUIDBag == objMeta[4]) then
        store.putObject(getObjectFromGUID(objMeta[1]))
      end
    end
  end
end

function BuyItem()
  local CoinPouch = getObjectFromGUID(CoinPouchGUID)
  if(CoinPouch) then
    print(CoinPouch.call("GetAvailableMoney"))
  end
end

function SetCoinPouchGUIDIn(obj)
  obj.call("SetCoinPouchGUID", {guid = CoinPouchGUID})
end

function CreateScriptInBag(bag)
  print("Adding scripts from bag")
  local newScript = [[
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
    end
    function GetObjectMetaBag()
      return allObjMeta
    end
  ]]
  bag.setLuaScript(newScript)
end

function CreateScriptInItem()
  print("Adding scripts from item")
  for _, guid in ipairs(allObjectsGUID) do
    obj = getObjectFromGUID(guid)

    local newScript = [[
      function onLoad()
        Wait.frames(|| CreateButton(), 10)
        local prev_flag = false
        itemCost = -1
        thingsInBasket, countItem = {}, 0
        for word in string.gmatch(self.getGMNotes(), "%S+") do
          if(prev_flag) then
            itemCost = tonumber(word)
            break
          end
          if(word:lower():find("cost:")) then
            prev_flag = true
          end
        end
        if(itemCost < 0) then
          print("Предмету не задана стоимость. (либо стоимость предмета ниже нуля)")
        end
      end

      function CreateButton()
        self.createButton({
          click_function = "SelectItem", function_owner = self,
          position = {0, 0.1, 0}, height = 500, width = 500,
          color = {0.75, 0.25, 0.25, 0.6},
        })
      end

      function SetCoinPouchGUID(parametrs)
        local CoinPouchGUID = parametrs.guid
        CoinPouch = getObjectFromGUID(CoinPouchGUID)
      end

      function SelectItem(obj, playerColor, altClick)
        if(altClick and countItem > 0) then
          if(CoinPouch) then
            CoinPouch.call("UpdateCountMoney", {value = -itemCost})
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
            CoinPouch.call("UpdateCountMoney", {value = itemCost})
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
        local selfPosition = self.getPosition()
        local spawnParametrs = {
          json = self.getJSON(),
          position = {x = selfPosition.x + 15.5, y = selfPosition.y + countItem + 2, z = selfPosition.z - 5.5},
          rotation = {x = 0, y = 0, z = 0},
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
    obj.setLuaScript(newScript)
  end
  UpdateSave()
end