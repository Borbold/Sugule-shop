﻿function onLoad()
  itemCost, changeObj = {}, {}
  watchword = {"цена:", "cost:"}
end

function onCollisionEnter(info)
  info = info.collision_object
  if(watchword) then
    local prev_flag
    for _,v in ipairs(changeObj) do
      if(v.getGUID() == info.getGUID()) then
        return
      end
    end

    for word in string.gmatch(info.getDescription(), "%S+") do
      if(prev_flag) then
        print(word)
        table.insert(itemCost, tonumber(word))
        table.insert(changeObj, info)
        break
      end
      if(word:lower():find(watchword[1]) or word:lower():find(watchword[2])) then
        prev_flag = true
      end
    end
  end
end

function ApplyChanges()
  if(itemCost and changeObj) then
    for index, item in ipairs(changeObj) do
      local prevGMNotes = item.getGMNotes()
      if(not prevGMNotes:find("cost:")) then
        local newGMNotes = "sell item" .. " \n"
        if(not itemCost[index]) then broadcastToAll(item.getName() .. " не задана стоимость! Перепроверте.") return end
        newGMNotes = newGMNotes .. "cost: " .. itemCost[index] .. " \n"
        newGMNotes = newGMNotes .. prevGMNotes
        Wait.frames(function() item.setGMNotes(newGMNotes) end, 5)
      else
        broadcastToAll(item.getName() .. " уже задана стоимость!")
      end
    end
    itemCost, changeObj = {}, {}
  end
end