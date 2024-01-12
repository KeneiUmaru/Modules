local Properties = {}

function Properties.new(initialValue, validator, callback)
    local self = {
        _value = initialValue,
        _validator = validator or function(value) return true end,
        _callback = callback or function(value) end,
        Changed = Instance.new("BindableEvent"),
    }

    function self:getValue()
        return self._value
    end

    function self:setValue(newValue)
        if self._validator(newValue) and self._value ~= newValue then
            self._value = newValue
            self.Changed:Fire(newValue)
            self._callback(newValue)
        end
    end

    function self:connect(callback)
        return self.Changed.Event:Connect(callback)
    end

    function self:addValidator(validator)
        local originalValidator = self._validator
        self._validator = function(value)
            return originalValidator(value) and validator(value)
        end
    end

    function self:addCallback(callback)
        local originalCallback = self._callback
        self._callback = function(value)
            originalCallback(value)
            callback(value)
        end
    end

    function self:disconnectAll()
        self.Changed:Destroy()
        self.Changed = Instance.new("BindableEvent")
    end

    function self:removeValidator(validator)
        local originalValidator = self._validator
        self._validator = function(value)
            return originalValidator(value) and not validator(value)
        end
    end

    function self:removeCallback(callback)
        local originalCallback = self._callback
        self._callback = function(value)
            originalCallback(value)
            if callback then
                callback(value)
            end
        end
    end

    function self:getValueWithCallback()
        self._callback(self._value)
        return self._value
    end

    return self
end
