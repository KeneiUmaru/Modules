local Thread = {}

function Thread:new(func, ...)
    local thread = setmetatable({
        coroutine = coroutine.create(func),
        arguments = { ... },
        running = false,
        result = nil,
        onComplete = nil
    }, self)
    return thread
end

function Thread:Disconnect()
    self.running = false
end

function Thread:Run()
    self.running = true
    local status, result = coroutine.resume(self.coroutine, unpack(self.arguments))
    if not status then
        warn("Thread error:", result)
    else
        self.result = result
    end
    self.running = false
    if self.onComplete then
        self.onComplete(self.result)
    end
end

function Thread:Pause()
    self.running = false
end

function Thread:Resume()
    if not self.running then
        self.running = true
        coroutine.resume(self.coroutine)
    end
end

function Thread:IsRunning()
    return self.running
end

function Thread:IsCompleted()
    return coroutine.status(self.coroutine) == "dead" and not self.running
end

function Thread:SetOnComplete(callback)
    self.onComplete = callback
end

function Thread:GetResult()
    return self.result
end

function Thread:Reset()
    self.coroutine = coroutine.create(self.coroutine_function)
    self.running = false
end

return Thread
