require 'copas'
local http = require 'socket.http'

local installer = {
  download = function (source, target)
    local contents = http.request(source)
    local file = io.open(target, "w")
    file:write(contents)
    file:close()
  end
}

local installScript = [[
  return {
    install = function ()
      local remotePath = "http://williamwilling.typepad.com/"
      download(remotePath .. "", idePath .. "packages/test.lua")
    end
  }
]]

return {
  name = "Plugin Manager",
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 1,

  onRegister = function (self)
    local plugin = assert(loadstring(installScript))()
    installer.idePath = ide.editorFilename:match(".*\\")
    setfenv(plugin.install, installer)
    plugin.install()
  end
}