 love = love
lfs = love.filesystem or require "love.filesystem"
insert, concat = table.insert, table.concat


-- see : https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/edit?tab=t.0#heading=h.yr4qxyxotyw


class OutStream

  @stream
  @flush
  @needPushBack = false

  new: (filepath) =>
    @filepath = filepath

  open: =>
    if @@stream
      @close!

    @filepath = @filepath or "profile.json"
    local errMsg
    major = love.getVersion!

    if major == 12 and lfs.openFile
      @@stream, errMsg = lfs.openFile @filepath, "w"
    else
      @@stream, errMsg = lfs.newFile @filepath, "w"

    unless @@stream
      error "Could not open file(" .. tostring(@filepath) .. ")for writing"

    @@flush = @@stream\setBuffer "none"
    @@stream\write "["

  close: (filepath) =>
    unless @@stream then return
    @@stream\write "]"
    @@stream\close!
    @@stream = nil
    @@needPushBack = false

  pushBack: =>
    if @@shouldPushBack
      @@stream\write ","
    @@needPushBack = true

  writeJsonArr: (table) =>
    str = { "{" }

    for k, v in pairs table
      insert str, ([["%s":]])\format(tostring(k))
      t = type v
      if t == "table"
        insert str, @writeJsonArr v
      elseif t == "number"
        insert str, tostring v
      elseif t == "userdata" and v\typeOf "Data"
        insert str, ([["%s":]])\format(v\getString!)
      elseif t != "userdata"
        insert str, ([["%s":]])\format(tostring v)
      insert str, ","

    if #str == 1 then return "{}"
    str[#str] = "}"

    concat str

  writeMark: (thredId, mark) =>
    unless @@stream then error "The file is not opned <:writeMark>"
    @pushBack!

    @@stream\write(([[{"name":"%s","ph":"i","pid":0,"tid":%d,"s":"%s","ts":%d]])\format(mark.name\gsub('"', '\"'), thredId, mark.scope, mark.start))

    if mark.args
      @@stream\write [[,"args":]]
      @@stream\write @writeJsonArr(mark.args)

    @@stream\write "}"

    if @@flush then @@stream\flush!

  writeProfile: (thredId, profile) =>
    unless @@stream then error "The file is not opned <:writeProfile>"
    @pushBack!

    @@stream\write(([[{"dur":%d,"name":"%s","ph":"X","pid":0,"tid":%d,"ts":%d]])\format(profile.finish-profile.start, profile.name\gsub('"','\"'), thredId, profile.start))

    if profile.args
      @@stream\write [[,"args":]]
      @@stream\write @writeJsonArr(profile.args)

    @@stream\write "}"

    if @@flush then @@stream\flush!

  writeCounter: (thredId, counter) =>
    unless @@stream then error "The file is not opned <:writeCounter>"
    @pushBack!

    @@stream\write(([[{"name":"%s","ph":"C","pid":0,"tid":%d,"ts":%d]])\format(counter.name, thredId, counter.start))

    if counter.args
      @@stream\write [[,"args":]]
      @@stream\write @writeJsonArr(counter.args)

    @@stream\write "}"

    if @@flush then @@stream\flush!

  jsonMetadata: (thredId, type, arg) =>
    if type == "process_name" or type == "thread_name"
      @@stream\write(([[{"name":"%s","ph":"M","pid":0,"tid":%d,"args":{"name":"%s"}}]])\format(type, thredId, arg))
    elseif type == "thread_sort_index"
      @@stream\write(([[{"name":"%s","ph":"M","pid":0,"tid":%d,"args":{"sort_index":%d}}]])\format(type, thredId, arg))

  writeMetadata: (thredId, metadata) =>
    unless @@stream then error "The file is not opned <:writeMetadata>"
    @pushBack!

    pb = false

    for key, name in pairs(metadata)
      if pb then @pushBack!
      @jsonMetadata thredId, key, name
      if @@flush then @@stream\flush!
      pb = true








