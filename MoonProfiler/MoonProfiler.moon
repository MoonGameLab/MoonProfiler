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
  isDebug: false
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
  return true


