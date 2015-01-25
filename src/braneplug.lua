require 'copas'
local http = require 'socket.http'
local lfs = require 'lfs'

local function ensureDir(path)
  local part, index = path:match("([/\\]?[^/\\]+[/\\])()")
  local subPath = ""
  
  while part do
    subPath = subPath .. part
    lfs.mkdir(subPath)
    part, index = path:match("([^/\\]+[/\\])()", index)
  end
end

local Installer = {
  download = function(source, target)
    local contents = http.request(source)
    
    ensureDir(target)
    local file = io.open(target, "wb")
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
  
  plugins:InsertColumn(0, "")
  plugins:InsertColumn(1, "Name")
  plugins:InsertColumn(2, "Version")
  plugins:InsertColumn(3, "Description")
  plugins:InsertColumn(4, "Author")
  
  local images = wx.wxImageList(16, 16, true, 2)
  images:Add(wx.wxBitmap("packages/installing.png"), wx.wxColour(255, 255, 255))
  images:Add(wx.wxBitmap("packages/done.png"), wx.wxColour(255, 255, 255))
  plugins:AssignImageList(images, wx.wxIMAGE_LIST_SMALL)
  
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
    local item = wx.wxListItem()
    item:SetId(selected)
    item:SetColumn(1)
    item:SetMask(wx.wxLIST_MASK_TEXT + wx.wxLIST_MASK_IMAGE)
    plugins:GetItem(item)
    
    local name = item:GetText()
    local plugin = braneplug.plugins[name]
    
    plugins:SetItemImage(selected, 0)
    
    local timer = wx.wxTimer(frame)
    frame:Connect(wx.wxEVT_TIMER, function()
      plugin:Install()
      plugins:SetItemImage(selected, 1)
    end)
    timer:Start(0, wx.wxTIMER_ONE_SHOT)
  end)
  
  frame:Show()
  
  gui.plugins = plugins
end

function gui:LoadPlugins()
  braneplug:Fetch()
  
  local function string(value)
    if value then
      return tostring(value)
    else
      return ""
    end
  end
  
  for name, plugin in pairs(braneplug.plugins) do
    local item = gui.plugins:InsertItem(0, "")
    gui.plugins:SetItem(item, 1, string(plugin.name))
    gui.plugins:SetItem(item, 2, string(plugin.version))
    gui.plugins:SetItem(item, 3, string(plugin.description))
    gui.plugins:SetItem(item, 4, string(plugin.author))
    gui.plugins:SetItemImage(item, -1)
  end
  
  gui.plugins:SetColumnWidth(0, 20)
  gui.plugins:SetColumnWidth(1, wx.wxLIST_AUTOSIZE)
  gui.plugins:SetColumnWidth(2, wx.wxLIST_AUTOSIZE_USEHEADER)
  gui.plugins:SetColumnWidth(3, wx.wxLIST_AUTOSIZE)
  gui.plugins:SetColumnWidth(4, wx.wxLIST_AUTOSIZE)
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