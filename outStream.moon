love = love
lfs = love.filesystem or require "love.filesystem"
insert, concat = table.insert, table.concat


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

  writeJsonArr



