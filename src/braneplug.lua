require 'copas'
local http = require 'socket.http'

local Installer = {
  download = function(source, target)
    local contents = http.request(source)
    local file = io.open(target, "w")
    file:write(contents)
    file:close()
  end
}

local Plugin = {}
Plugin.__index = Plugin

function Plugin:Install()
  local script = http.request(self.url)
  local installer = assert(loadstring(script))()

  setfenv(installer.install, Installer)
  installer:install()
end

local braneplug = {}

function braneplug:Fetch()
  local source = http.request("http://zerobranestore.blob.core.windows.net/repository/zbrepository.lua")
  local repository = assert(loadstring(source))()
  
  for name, plugin in pairs(repository.plugins) do
    plugin.name = name
    setmetatable(plugin, Plugin)
  end 
  
  self.plugins = repository.plugins
end

local gui = {}

function gui:Initialize()
  self.CreateMenuItem()
end

function gui:CreateMenuItem()
  local editMenu = ide:GetMenuBar():GetMenu(ide:GetMenuBar():FindMenu(TR("&Edit")))
  local menuItem = editMenu:Append(wx.wxID_ANY, "Plugins...")
  ide:GetMainFrame():Connect(menuItem:GetId(), wx.wxEVT_COMMAND_MENU_SELECTED, function()
      gui:CreateFrame()
      gui:LoadPlugins()
  end)
end

function gui:CreateFrame()
  self.frame = wx.wxFrame(
    wx.NULL,
    wx.wxID_ANY,
    'Brane Plug',
    wx.wxDefaultPosition,
    wx.wxDefaultSize,
    wx.wxDEFAULT_FRAME_STYLE)
  
  self.listBox = wx.wxListBox(
    self.frame,
    wx.wxID_ANY)
  self.frame:Show(true)
end

function gui:LoadPlugins()
  braneplug:Fetch()
  
  local plugins = {}
  for plugin in pairs(braneplug.plugins) do
    table.insert(plugins, plugin)
  end
  
  self.listBox:InsertItems(plugins, 0)
end

return {
  name = "Brane Plug",
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 1,

  onRegister = function(self)
    Installer.idePath = ide.editorFilename:match(".*\\")    -- Let the installers know where ZeroBrane Studio is located.
    ide:AddConsoleAlias("braneplug", braneplug)             -- Make the plugin manager accessible from the local console.
    gui:Initialize()
  end,
  
  onUnRegister = function(self)
    ide:RemoveConsoleAlias("braneplug")
  end
}