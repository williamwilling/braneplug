return {
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 1,
  
  install = function()
    local remotePath = "http://zerobranestore.blob.core.windows.net/braneplug/"
    download(remotePath .. "braneplug.lua", idePath .. "packages/braneplug.lua")
  end
}