local args = { ... }

local ok, CFG = pcall(dofile, "updater_config.lua")
if not ok then
  error("Could not load updater_config.lua: " .. tostring(CFG))
end

local DISK_MOUNT = CFG.disk_mount or "disk"
local PROGRAMS = CFG.programs or {}
local GITHUB = CFG.github or {}

local function sortedKeys(tbl)
  local keys = {}
  for k in pairs(tbl) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

local function usage()
  print("Usage:")
  print("  update <program>")
  print("  update all")
  print("")
  print("Available programs:")
  for _, name in ipairs(sortedKeys(PROGRAMS)) do
    local entry = PROGRAMS[name]
    print("  " .. name .. " -> " .. DISK_MOUNT .. "/" .. (entry.file or (name .. ".lua")))
  end
end

if #args == 0 then
  usage()
  return
end

local function ensureDiskMounted()
  if not fs.exists(DISK_MOUNT) or not fs.isDir(DISK_MOUNT) then
    error("Disk mount '" .. DISK_MOUNT .. "' not found. Insert the floppy first.")
  end
end

local function joinPath(a, b)
  if a:sub(-1) == "/" then
    return a .. b
  end
  return a .. "/" .. b
end

local function ensureParentDir(path)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then
    fs.makeDir(dir)
  end
end

local function buildGitHubRawUrl(entry)
  if type(entry.url) == "string" and entry.url ~= "" then
    return entry.url
  end

  local owner = entry.owner or GITHUB.owner
  local repo = entry.repo or GITHUB.repo
  local branch = entry.branch or GITHUB.branch or "main"
  local path = entry.path or entry.file

  if type(owner) ~= "string" or owner == "" then
    return nil, "Missing GitHub owner"
  end

  if type(repo) ~= "string" or repo == "" then
    return nil, "Missing GitHub repo"
  end

  if type(path) ~= "string" or path == "" then
    return nil, "Missing GitHub file path"
  end

  return ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(owner, repo, branch, path)
end

local function downloadUrl(url, label)
  if not http then
    error("HTTP API is not available.")
  end

  local response, err = http.get(url)

  if not response then
    error("Failed to download " .. label .. ": " .. tostring(err))
  end

  local text = response.readAll()
  response.close()

  if not text or text == "" then
    error("Downloaded empty content from " .. label .. ".")
  end

  return text
end

local function writeFile(path, text)
  ensureParentDir(path)

  local file = fs.open(path, "w")
  if not file then
    error("Could not open " .. path .. " for writing.")
  end

  file.write(text)
  file.close()
end

local function installOrUpdateOne(name)
  local entry = PROGRAMS[name]
  if not entry then
    error("Unknown program: " .. name)
  end

  local fileName = entry.file or (name .. ".lua")
  local targetPath = joinPath(DISK_MOUNT, fileName)
  local tempPath = targetPath .. ".new"

  local existed = fs.exists(targetPath)

  if existed then
    print("Updating " .. name .. " -> " .. targetPath)
  else
    print("Installing " .. name .. " -> " .. targetPath)
  end

  local downloadLabel
  local text

  local githubUrl, githubErr = buildGitHubRawUrl(entry)
  if githubUrl then
    downloadLabel = githubUrl
    text = downloadUrl(githubUrl, githubUrl)
  elseif type(entry.code) == "string" and entry.code ~= "" then
    local pasteUrl = "https://pastebin.com/raw/" .. entry.code
    downloadLabel = pasteUrl
    text = downloadUrl(pasteUrl, pasteUrl)
  else
    error("Program '" .. name .. "' is missing a GitHub source and Pastebin code" .. (githubErr and (": " .. githubErr) or "."))
  end

  if fs.exists(tempPath) then
    fs.delete(tempPath)
  end

  writeFile(tempPath, text)

  if existed then
    fs.delete(targetPath)
  end

  fs.move(tempPath, targetPath)

  if existed then
    print("Updated " .. name)
  else
    print("Installed " .. name)
  end
end

ensureDiskMounted()

local targets = {}

if #args == 1 and args[1] == "all" then
  targets = sortedKeys(PROGRAMS)
else
  for i = 1, #args do
    targets[#targets + 1] = args[i]
  end
end

for i = 1, #targets do
  installOrUpdateOne(targets[i])
end

print("")
print("Done.")
print("Restart any running programs to use the new version.")
