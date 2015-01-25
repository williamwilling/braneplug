return {
  description = "A plugin manager for ZeroBrane Studio.",
  author = "William Willing",
  version = 2,

  install = function()
    local remotePath = "http://zerobranestore.blob.core.windows.net/braneplug/"
    download(remotePath .. "braneplug.lua", idePath .. "packages/braneplug.lua")
    download(remotePath .. "done.png", idePath .. "packages/done.png")
    download(remotePath .. "installing.png", idePath .. "packages/installing.png")
  end
}