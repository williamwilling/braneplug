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
  local frame = wx.wxFrame(ide:GetMainFrame(), wx.wxID_ANY, 'Brane Plug', wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxRESIZE_BORDER + wx.wxFRAME_NO_TASKBAR + wx.wxFRAME_FLOAT_ON_PARENT)
  local panel = wx.wxPanel(frame, wx.wxID_ANY)
  
  local plugins = wx.wxListCtrl(
    panel,
    wx.wxID_ANY,
    wx.wxDefaultPosition,
    wx.wxDefaultSize,
    wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL)
  
  plugins:InsertColumn(0, "Name")
  plugins:InsertColumn(1, "Author")
  plugins:InsertColumn(2, "Version")
  plugins:InsertColumn(3, "Description")
  
  local buttons = wx.wxPanel(panel, wx.wxID_ANY)
  local install = wx.wxButton(buttons, wx.wxID_ANY, "Install")
  local remove = wx.wxButton(buttons, wx.wxID_ANY, "Remove")
  install:Disable()
  remove:Hide()
  
  local frameSizer = wx.wxBoxSizer(wx.wxVERTICAL)
  frameSizer:Add(plugins, 1, wx.wxEXPAND)
  frameSizer:Add(buttons, 0, wx.wxALIGN_CENTER_HORIZONTAL)
  
  local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
  buttonSizer:Add(install, 0, wx.wxALL + wx.wxALIGN_LEFT, 4)
  buttonSizer:Add(remove, 0, wx.wxALL + wx.wxALIGN_RIGHT, 4)
  
  buttons:SetSizer(buttonSizer)
  panel:SetSizerAndFit(frameSizer)
  
  plugins:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED, function(event)
    install:Enable(true)
  end)

  install:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    local selected = plugins:GetNextItem(-1, wx.wxLIST_NEXT_ALL, wx.wxLIST_STATE_SELECTED)
    local name = plugins:GetItemText(selected)
    local plugin = braneplug.plugins[name]
    plugin:Install()
  end)
  
  frame:Show()
  
  gui.plugins = plugins
end

function gui:LoadPlugins()
  braneplug:Fetch()
  
  for name, plugin in pairs(braneplug.plugins) do
    local item = gui.plugins:InsertItem(0, plugin.name)
    gui.plugins:SetItem(item, 1, plugin.author or "")
    gui.plugins:SetItem(item, 2, plugin.version or "")
    gui.plugins:SetItem(item, 3, plugin.description or "")
  end
end

function gui.onPluginSelected(args)
  local plugin = braneplug.plugins[args:GetString()]
  gui.name:SetLabel(plugin.name)
  gui.author:SetLabel(plugin.author or "")
  gui.description:SetLabel(plugin.description or "")
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