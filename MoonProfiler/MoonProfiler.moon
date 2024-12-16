love = love
PATH = ...\match "(.-)[^%.]+$"
dirPATH = PATH\gsub "%.","/"


lt = love.thread or require "love.thread"

threadConfig = require PATH .. "threadConfig"
info = lt.getChannel threadConfig.infoID

_err = error
error = (msg) ->
  _err "Error thrown by MoonProfiler: " .. tostring(msg)

local isActive, threadStartIndex

setActiveMode = (active) ->
  if isActive == nil
    info\performAtomic ->
      i = info\pop!
      if i
        isActive = i.active
        threadStartIndex = i.threadIndex
      else
        if active == nil
          active = true
        isActive = active
        threadStartIndex = 0
      info\push { active: isActive, threadIndex: threadStartIndex + 1 }



MoonProfilerEnableLevels = {
  ["none"]:     0
  ["profiles"]: 1
  ["mark"]:     2
  ["counter"]:  4
  ["all"]:      7
}

emptyFunc = ->
emptyProfile = { stop: emptyFunc, args: {} }
emptyCounter = {}
local moonProfilerRelease
local moonProfiler

moonProfilerRelease = {
  isActive: false
  enableLevels: MoonProfilerEnableLevels
  begin: emptyFunc
  end: emptyFunc
  enabled: false
  profile: -> return emptyProfile
  stopProfile: emptyFunc
  profileFunction: -> return emptyProfile
  mark: emptyFunc
  counter: -> return emptyCounter
  countMemory: -> return emptyCounter
  setName: emptyFunc
  setThreadName: emptyFunc
  setThreadSortIndex: emptyFunc
}

return (active) ->
  setActiveMode active

  if not isActive then return moonProfilerRelease

  moonProfiler = {
    isActive: true
    enableLevels: MoonProfilerEnableLevels
  }

  local threadId, commandTable

  threadId = threadStartIndex
  commandTable = { threadId }

  _getTime = love.timer.getTime

  getTime = -> _getTime() * 1e6

  local thread
  outStream = love.thread.getChannel threadConfig.outStreamID

  useBuffer, buffer = pcall require, "string.buffer"
  buf_enc, _options
  if useBuffer
    _options = { dict: threadConfig.dict }
    buf_enc = buffer.new _options
    buffer = nil

  bufferMode = false
  commandBuffer, commandBufferIndex = { buffer: true }, 1

  ------------------------------
  ---------METHODS--------------
  ------------------------------

  pushCommand = (command, arg, force) ->
    commandTable.command = command
    commandTable[2] = arg
    if not bufferMode or force
      if useBuffer
        outStream\push buf_enc\reset!encode(commandTable)\get!
      else
        outStream\push commandTable
    else
      commandBuffer[commandBufferIndex] = buf_enc\reset!\encode(commandTable)\get!
      commandBufferIndex += 1
    commandTable[2] = nil

