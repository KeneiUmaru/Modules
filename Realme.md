Properties Module
The Properties module provides a flexible and extensible way to manage properties with validation and callback functions.

Usage
Creating a New Instance
lua
Copy code
local Properties = require("path/to/Properties")

-- Creating a new Properties instance
local myProperty = Properties.new(42)
Getting and Setting Values
lua
Copy code
-- Getting the current value
local currentValue = myProperty:getValue()

-- Setting a new value with validation and callbacks
myProperty:setValue(55)
Connecting Callbacks
lua
Copy code
-- Connecting a callback function to the Changed event
local connection = myProperty:connect(function(newValue)
    print("Property changed to:", newValue)
end)
Adding Validators
lua
Copy code
-- Adding a custom validator function
myProperty:addValidator(function(value)
    return value > 0
end)
Adding Additional Callbacks
lua
Copy code
-- Adding an additional callback function
myProperty:addCallback(function(newValue)
    print("Additional callback - Property changed to:", newValue)
end)
Removing Validators
lua
Copy code
-- Removing a previously added validator function
myProperty:removeValidator(function(value)
    return value > 0
end)
Removing Callbacks
lua
Copy code
-- Removing a previously added callback function
myProperty:removeCallback(function(newValue)
    print("Additional callback - Property changed to:", newValue)
end)
Disconnecting All Listeners
lua
Copy code
-- Disconnecting all listeners from the Changed event and resetting the event
myProperty:disconnectAll()
Getting Value with Callback
lua
Copy code
-- Getting the current value and triggering the callback without changing the value
local currentValue = myProperty:getValueWithCallback()
Examples
lua
Copy code
-- Example usage with validation and callbacks
local temperature = Properties.new(25)

-- Connect a callback for logging
temperature:connect(function(newValue)
    print("Temperature changed to:", newValue)
end)

-- Add a validator to ensure the temperature is within a valid range
temperature:addValidator(function(value)
    return value >= -50 and value <= 50
end)

-- Try setting a new temperature
temperature:setValue(30)  -- This should trigger the callback

-- Try setting an invalid temperature
temperature:setValue(80)  -- This should not trigger the callback due to validation
