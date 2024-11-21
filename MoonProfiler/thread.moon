love = love
_error = error

commands = {}

error = (message) ->
  error "Error thrown by MoonProfiler thread: " .. tostring message

PATH, OWNER = ...

outStream = require(PATH .. "outStream")!
threadConfig = require PATH .. "threadConfig"

useBuffer, buffer = pcall(require, "string.buffer")
local bufDec, _options

if useBuffer
  _options = {
    dict: threadConfig.dict
  }
  bufDec = buffer.new _options
  buffer = nil


out = love.thread.getChannel threadConfig.outStreamId
info = love.thread.getChannel threadConfig.infoId

updateOwner = (channel, owner) ->
  info = channel\pop!
  info.owner = owner
  channel\push info

commands["open"] = (threadId, filepath) ->
  if info\peek!.owner == nil
    if OWNER ~= threadId
      error "Thread " .. threadId .. "tried to begin session. Only thread ".. OWNER .. ", that created the outputStream, can begin sessions"

    outStream\open filepath

    info\performAtomic updateOwner, threadId

commands["close"] = (threadId) ->
  if OWNER ~= threadId
    error "Thread " .. threadId .. " tried to end session owned by thread "..OWNER

  outStream\close!
  info\performAtomic updateOwner, nil
  true


commands["writeProfile"]  = outStream.writeProfile
commands["writeMark"]     = outStream.writeMark
commands["writeCounter"]  = outStream.writeCounter
commands["writeMetadata"] = outStream.writeMetadata


while true
  local command
  if useBuffer
    command = bufDec\set(out\demand!\decode!)
  else
    command = out\command!

  if command.buffer
    for _, encoded in ipairs(command)
      decoded = bufDec\set(encoded)\decode!
      fn = commands[decoded.command]
      if fn and fn(decoded[1], decoded[2], decoded[3])
        return
  else
    fn = commands[command.command]
    if fn and fn(command[1], command[2], command[3])
      return






