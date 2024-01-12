local Properties = {}

function Properties.new(initialValue)
    local self = {
        _value = initialValue,
        Changed = Instance.new("BindableEvent"),
    }

    function self.getValue()
        return self._value
    end

    function self.setValue(newValue)
        if self._value ~= newValue then
            self._value = newValue
            self.Changed:Fire(newValue)
        end
    end

    return self
end
