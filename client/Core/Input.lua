local UIS = game:GetService("UserInputService")

local Maid = require(shared.Common.Maid)
local Emitter = require(shared.Common.Emitter)
local log, logwarn = require(shared.Common.Log)(script:GetFullName())

---A class description
---@class Input
---@static
local Input = {
    _binds = {},
    _inputToBind = {},
    _ignoreProcessing = {},
    
    _emitter = Emitter.new()
}


Input.GamepadKeycodeMap = {
    -- analog
    [Enum.KeyCode.Thumbstick1] = true,
    [Enum.KeyCode.Thumbstick2] = true,
    [Enum.KeyCode.ButtonL2] = true,
    [Enum.KeyCode.ButtonR2] = true,
    
    -- rest are presumably digital (false)
}

function Input._fromVector(inputObject, state)
    return inputObject.Position, inputObject.Delta, inputObject
end

function Input._fromDigital(inputObject, state)
    return state, nil, inputObject
end

function Input._fromGamepad(inputObject, state)
    -- either fromVector or fromDigital...
    if Input.GamepadKeycodeMap[inputObject.KeyCode] then
        return Input._fromVector(inputObject, state)
    end

    return Input._fromDigital(inputObject, state)
end

local fromVector = Input._fromVector
local fromDigital = Input._fromDigital
local fromGamepad = Input._fromGamepad

Input.TranslationMap = {
    [Enum.UserInputType.MouseMovement] = fromVector,
    [Enum.UserInputType.MouseWheel] = fromVector,
    [Enum.UserInputType.Touch] = fromVector,
    [Enum.UserInputType.Keyboard] = fromDigital,
    ["MouseButton?"] = fromDigital,
    ["Gamepad?"] = fromGamepad,
}

function Input._matchNameToTransMap(inputObject)
    for entry, func in pairs(Input.TranslationMap) do
        if typeof(entry) == "string" and inputObject.UserInputType.Name:match(entry) then
            Input.TranslationMap[inputObject.UserInputType] = func
            return func
        end
    end
end

function Input._eventFunction(inputObject, state, processed)
        if not (Input._ignoreProcessing[inputObject.UserInputType] or Input._ignoreProcessing[inputObject.KeyCode]) and processed then
            log(3, "ignoring input for", inputObject.UserInputType, ":", inputObject.KeyCode)
            return
        end

        local translation = Input.TranslationMap[inputObject.UserInputType]

        if not translation then 
            translation = Input._matchNameToTransMap(inputObject)
            if not translation then
                log(3, "ignoring input", inputObject.UserInputType, "because it does not exist in translation map")
                return 
            end
        end

        local bind = Input._inputToBind[inputObject.UserInputType] or Input._inputToBind[inputObject.KeyCode]
        Input.trigger(
            bind, 
            translation(inputObject, state)
        )
end

function Input._init()
    if Input._initialized then error("do not initialize Input twice (static)", 2) end
    Input._initialized = true

    Input._UISBegan = UIS.InputBegan:Connect(function(inputObject, processed)
        Input._eventFunction(inputObject, true, processed)
    end)
    Input._UISChanged = UIS.InputChanged:Connect(function(inputObject, processed)
        Input._eventFunction(inputObject, nil, processed)
    end)
    Input._UISEnded = UIS.InputEnded:Connect(function(inputObject, processed)
        Input._eventFunction(inputObject, false, processed)
    end)
end

function Input.bind(bind, ...)
    local inputs = {...}
    Input._binds[bind] = Input._binds[bind] or {}
    
    for _, input in pairs(inputs) do
        if typeof(input) == "table" then
            Input.bind(bind, unpack(input))
        elseif input == true then
            -- bizarre code to check if last arg is a true boolean to 
            -- ignore the game processing boolean (trigger even if typing)
            for _, ignoreProcessingInput in pairs(inputs) do
                if typeof(input) ~= "boolean" then
                    Input._ignoreProcessing[input] = input
                end
            end
            break
        else
            log(3, "binding", input, "to", bind)
            table.insert(Input._binds[bind], input)
            Input._inputToBind[input] = bind
        end
    end
    
    return Input
end

function Input.listen(...)
    Input._emitter:listen(...)
    return Input
end

function Input.listenFor(bind, ...)
    Input._emitter:on(bind, ...)
    return Input
end
Input.on = Input.listenFor

function Input.trigger(bind, ...)
    log(3, "triggering", bind, "with", ...)
    Input._emitter:emit(bind, ...)
    return Input
end

function Input.clear()
    Input._binds = {}
    Input._inputToBind = {}
    return Input
end


Input._init()
return Input