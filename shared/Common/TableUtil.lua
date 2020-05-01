local TableUtil = {}
local random = Random.new()

---Get a random value from a table
---@param t table The table to pick an input from
---@param filter function The filtering function to go with
---@return any The value from an array
function TableUtil.random(t, filter)
    if not type(filter) == "function" then
        error("expected function, got " .. type(filter))
    end
    if filter then
        local trackedEntries = {}
        while true do
            local val = random:NextInteger(1, #t)
            local entry = t[val]
            if filter(entry) then
                return entry, val
            end
            trackedEntries[entry] = true
            if TableUtil.getSize(trackedEntries) == #t then
                warn("table entries exceeded, no result")
                return nil
            end
        end
    end
    local val = random:NextInteger(1, #t)
    return t[val], val
end

---Shuffle an array with Fisher–Yates shuffling
---@param t table The array to shuffle
---@return table Same array, but shuffled
function TableUtil.shuffle(t)
    for i = 1, #t - 1 do
        local r = random:NextInteger(i, #t)
        local prevValue = t[r]
        t[r] = t[i]
        t[i] = prevValue
    end
    return t
end

---Convert an array table to a list table (dictionary)
---@param t table The array to convert
---@param callback function Define special behaviour. Passed arguments: (table) result, (userdata) value, (float) index
---@return table List styled as {value = index}
function TableUtil.toList(t, callback)
    local result = {}
    for i, v in pairs(t) do
        if callback then
            callback(result, v, i)
        else
            result[v] = i
        end
    end

    return result
end

function TableUtil.toEnumList(t)
    -- Convert {"EnumName", "Desc"} to
    -- [EnumName] = {Description = "Desc", Name = "EnumName", Number = index}
    TableUtil.toList(
        t,
        function(result, key, val)
            result[val[1]] = {
                Name = val[1],
                Description = val[2],
                Number = key
            }
        end
    )
end

---Get the size of a table by element count
---@param t table The table to iterate over
---@return table Size of the table (by element count)
function TableUtil.getSize(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

---Bubble sort an array based on values
---@param array table The array to sort
---@return table Array with sorted values
function TableUtil.valueBubblesort(array)
    local result = {}
    for _, val in ipairs(array) do
        table.insert(result, val)
    end

    -- Bubblesort swaps elements
    local function swap(list, index1, index2)
        local index2Val = list[index2]

        list[index2] = list[index1]
        list[index1] = index2Val
    end

    -- Repeat until there's nothing left to sort
    local count = #result
    repeat
        local newn = 1
        for i = 2, count do
            if result[i - 1] > result[i] then
                -- Swap the two values and set the index as the new count
                swap(result, i - 1, i)
                newn = i
            end
        end
        count = newn
    until count == 1

    return result
end

return TableUtil
