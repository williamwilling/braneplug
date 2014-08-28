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

return {
  name = "Plugin Manager",
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 1,

  onRegister = function (self)
    local source = http.request("http://zerobranestore.blob.core.windows.net/davinci/zbplugin.lua")
    local plugin = assert(loadstring(source))()
    
    installer.idePath = ide.editorFilename:match(".*\\")
    setfenv(plugin.install, installer)
    plugin.install()
  end
}