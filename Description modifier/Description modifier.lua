function onLoad()
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
        table.insert(itemCost, tonumber(word))
        table.insert(changeObj, info)
        break
      end
      if(word:lower() == watchword[1] or word:lower() == watchword[2]) then
        prev_flag = true
      end
    end
  end
end

function ApplyChanges()
  if(itemCost and changeObj) then
    for index, item in ipairs(changeObj) do
      local prevGMNotes = item.getGMNotes()
      if(not prevGMNotes:find("sell item")) then
        local newGMNotes = "sell item" .. " \n"
        newGMNotes = newGMNotes .. prevGMNotes
        Wait.frames(function() item.setGMNotes(newGMNotes) end, 5)
      else
        broadcastToAll(item.getName() .. " уже задан!")
      end
    end
    itemCost, changeObj = {}, {}
  end
end