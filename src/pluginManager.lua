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

local function fetchRepository(url)
  local source = http.request(url)
  return assert(loadstring(source))()
end

local function installPlugin(url)
  local source = http.request(url)
  local plugin = assert(loadstring(source))()
  
  installer.idePath = ide.editorFilename:match(".*\\")
  setfenv(plugin.install, installer)
  plugin.install()
end

return {
  name = "Plugin Manager",
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 1,

  onRegister = function (self)
    local repository = fetchRepository("http://zerobranestore.blob.core.windows.net/repository/zbrepository.lua")
    
    for name, plugin in pairs(repository.plugins) do
      plugin.name = name
      plugin.install = function (self)
        installPlugin(self.url)
      end
      
      print(plugin.name)
    end
  end
}