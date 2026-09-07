-- Grand Blue Kaitun — GitHub RAW loader (the only file you HttpGet)
-- Default: REMOTE. Fresh machine, no local folder.

local DEFAULT_OWNER = "heuwqepoxcn213213001231"
local DEFAULT_REPO = "GrandBlueKaitun"
local DEFAULT_BRANCH = "main"

if type(getgenv) ~= "function" then
	error("[Kaitun][Loader] getgenv missing")
end
if type(loadstring) ~= "function" then
	error("[Kaitun][Loader] loadstring missing")
end

if type(getgenv()._GBKaitunUnload) == "function" then
	pcall(getgenv()._GBKaitunUnload)
	task.wait(0.12)
end

local GEN = (tonumber(getgenv()._GBKaitunGen) or 0) + 1
getgenv()._GBKaitunGen = GEN

local function dead()
	return getgenv()._GBKaitunGen ~= GEN
end

local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function sourceMode()
	if getgenv().GB_DEV_LOCAL == true then
		return "LOCAL"
	end
	local m = getgenv().GB_SOURCE_MODE
	if type(m) == "string" then
		m = string.upper(trim(m))
		if m == "LOCAL" or m == "REMOTE" then
			return m
		end
		error("[Kaitun][Loader] GB_SOURCE_MODE must be REMOTE or LOCAL")
	end
	return "REMOTE"
end

local MODE = sourceMode()

local function parseRepo(s)
	s = trim(s)
	local owner, repo = s:match("^([%w._-]+)/([%w._-]+)$")
	if not owner then
		error("[Kaitun][Loader] GB_REPO must be owner/repo")
	end
	return owner, repo
end

local OWNER, REPO = DEFAULT_OWNER, DEFAULT_REPO
if type(getgenv().GB_REPO) == "string" and trim(getgenv().GB_REPO) ~= "" then
	OWNER, REPO = parseRepo(getgenv().GB_REPO)
end

local BRANCH = DEFAULT_BRANCH
if type(getgenv().GB_BRANCH) == "string" and trim(getgenv().GB_BRANCH) ~= "" then
	if not trim(getgenv().GB_BRANCH):match("^[%w._/-]+$") then
		error("[Kaitun][Loader] invalid GB_BRANCH")
	end
	BRANCH = trim(getgenv().GB_BRANCH)
end

local LOCKED_PREFIX = string.format(
	"https://raw.githubusercontent.com/%s/%s/%s/",
	OWNER,
	REPO,
	BRANCH
)

local BASE_URL = LOCKED_PREFIX
if type(getgenv().GB_BASE_URL) == "string" and trim(getgenv().GB_BASE_URL) ~= "" then
	BASE_URL = trim(getgenv().GB_BASE_URL)
	if BASE_URL:sub(-1) ~= "/" then
		BASE_URL = BASE_URL .. "/"
	end
	if not BASE_URL:match("^https://raw%.githubusercontent%.com/") then
		error("[Kaitun][Loader] GB_BASE_URL must be raw.githubusercontent.com")
	end
	LOCKED_PREFIX = BASE_URL
end

local function jsonDecode(s)
	local ok, Http = pcall(function()
		return game:GetService("HttpService")
	end)
	if not ok or not Http then
		error("[Kaitun][Loader] HttpService missing")
	end
	local ok2, t = pcall(Http.JSONDecode, Http, s)
	if not ok2 or type(t) ~= "table" then
		error("[Kaitun][Loader] manifest JSON invalid")
	end
	return t
end

local function httpGetOnce(url)
	if typeof(game.HttpGet) == "function" then
		return game:HttpGet(url)
	end
	if typeof(game.HttpGetAsync) == "function" then
		return game:HttpGetAsync(url)
	end
	if typeof(httpget) == "function" then
		return httpget(url)
	end
	error("HttpGet missing")
end

local function httpGetRetry(url, label)
	local last
	for _ = 1, 3 do
		local ok, body = pcall(httpGetOnce, url)
		if ok and type(body) == "string" and #body > 0 then
			return body
		end
		last = body
		task.wait(0.35)
	end
	error(string.format("[Kaitun][Loader] Failed to download %s", label))
end

local function canRead()
	return typeof(isfile) == "function" and typeof(readfile) == "function"
end

local function canWrite()
	return typeof(writefile) == "function"
end

local function localRoot()
	local root = getgenv().GB_ROOT
	if type(root) == "string" and trim(root) ~= "" then
		root = trim(root)
		if root:sub(-1) ~= "/" then
			root = root .. "/"
		end
		return root
	end
	return ""
end

local function diskCachePath(rel, ver)
	return "GBKaitun_cache/" .. tostring(ver) .. "/" .. rel:gsub("/", "__")
end

local function cacheRead(rel, ver)
	if not canRead() then
		return nil
	end
	local p = diskCachePath(rel, ver)
	if isfile(p) then
		local ok, s = pcall(readfile, p)
		if ok and type(s) == "string" and #s > 0 then
			return s
		end
	end
	return nil
end

local function cacheWrite(rel, ver, src)
	if not canWrite() then
		return
	end
	if typeof(makefolder) == "function" then
		pcall(makefolder, "GBKaitun_cache")
		pcall(makefolder, "GBKaitun_cache/" .. tostring(ver))
	end
	pcall(writefile, diskCachePath(rel, ver), src)
end

local ALLOWED = {
	["VERSION"] = true,
	["manifest.json"] = true,
}

local function validRel(rel)
	if type(rel) ~= "string" then
		return false
	end
	if rel:find("..", 1, true) or rel:find("://", 1, true) or rel:find("\\", 1, true) then
		return false
	end
	if rel:sub(1, 1) == "/" then
		return false
	end
	if not rel:match("^[%w._/%-]+$") then
		return false
	end
	return ALLOWED[rel] == true
end

local function lockUrl(rel, ver)
	if not validRel(rel) then
		error("[Kaitun][Loader] blocked path " .. tostring(rel))
	end
	local url = BASE_URL .. rel
	if url:sub(1, #BASE_URL) ~= BASE_URL then
		error("[Kaitun][Loader] URL escaped lock")
	end
	if not url:match("^https://raw%.githubusercontent%.com/") then
		error("[Kaitun][Loader] URL host rejected")
	end
	if ver and rel ~= "VERSION" then
		url = url .. "?v=" .. tostring(ver)
	end
	return url
end

local function fetchLocal(rel)
	if not canRead() then
		error("[Kaitun][Loader] LOCAL mode requires readfile/isfile — missing " .. rel)
	end
	local path = localRoot() .. rel
	if not isfile(path) then
		error("[Kaitun][Loader] LOCAL missing " .. path .. " (set getgenv().GB_ROOT)")
	end
	local src = readfile(path)
	if type(src) ~= "string" or #src == 0 then
		error("[Kaitun][Loader] LOCAL empty " .. path)
	end
	return src
end

local MANIFEST_VER = "0"

local function fetchRemote(rel)
	local ver = MANIFEST_VER
	if rel == "VERSION" or ver == "0" then
		ver = nil
	end
	local url = lockUrl(rel, ver)
	local ok, src = pcall(httpGetRetry, url, rel)
	if ok then
		cacheWrite(rel, MANIFEST_VER, src)
		return src
	end
	local cached = cacheRead(rel, MANIFEST_VER)
	if cached then
		print("[Kaitun][Loader] cache fallback " .. rel)
		return cached
	end
	error(src)
end

local function fetch(rel)
	if MODE == "LOCAL" then
		return fetchLocal(rel)
	end
	return fetchRemote(rel)
end

print("[Kaitun][Loader] Source " .. MODE)
if MODE == "REMOTE" then
	print("[Kaitun][Loader] Base " .. BASE_URL)
end

local versionText = "1.0.1"
do
	local ok, raw = pcall(fetch, "VERSION")
	if ok then
		versionText = trim(raw)
	end
end
MANIFEST_VER = versionText

local manifest = jsonDecode(fetch("manifest.json"))
if type(manifest.version) ~= "string" or type(manifest.files) ~= "table" or type(manifest.order) ~= "table" then
	error("[Kaitun][Loader] manifest missing version/files/order")
end
if trim(manifest.version) ~= versionText then
	print("[Kaitun][Loader] VERSION " .. versionText .. " vs manifest " .. tostring(manifest.version))
end
MANIFEST_VER = trim(manifest.version)
print("[Kaitun][Loader] Manifest " .. MANIFEST_VER)

for rel, mapped in pairs(manifest.files) do
	if type(rel) ~= "string" or type(mapped) ~= "string" or rel ~= mapped then
		error("[Kaitun][Loader] files map must be path=path, no URLs")
	end
	if rel:find("://", 1, true) or mapped:find("://", 1, true) then
		error("[Kaitun][Loader] arbitrary URL in manifest")
	end
	ALLOWED[rel] = true
end
ALLOWED["kaitun.lua"] = true

for _, row in ipairs(manifest.order) do
	if type(row) ~= "table" or type(row.path) ~= "string" then
		error("[Kaitun][Loader] bad order row")
	end
	if not manifest.files[row.path] then
		error("[Kaitun][Loader] order path not in files: " .. tostring(row.path))
	end
end

local chunkCache = {}

local function LoadModule(rel)
	if type(rel) ~= "string" then
		error("[Kaitun][Loader] LoadModule needs a path")
	end
	rel = rel:gsub("^/+", "")
	if not rel:match("%.lua$") and rel ~= "VERSION" and rel ~= "manifest.json" then
		rel = rel .. ".lua"
	end
	if chunkCache[rel] ~= nil then
		return chunkCache[rel]
	end
	if not ALLOWED[rel] then
		error("[Kaitun][Loader] path not in manifest: " .. rel)
	end
	local src = fetch(rel)
	local fn, err = loadstring(src, rel)
	if not fn then
		error("[Kaitun][Loader] compile " .. rel .. " " .. tostring(err))
	end
	local result = fn()
	chunkCache[rel] = result
	return result
end

local function Require(dotted)
	local path = tostring(dotted):gsub("%.", "/")
	return LoadModule(path)
end

getgenv()._GBKaitunLoader = {
	LoadModule = LoadModule,
	Require = Require,
	BASE_URL = BASE_URL,
	VERSION = MANIFEST_VER,
	SOURCE_MODE = MODE,
	OWNER = OWNER,
	REPO = REPO,
	BRANCH = BRANCH,
}

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
if not lp then
	repeat
		task.wait()
	until Players.LocalPlayer
	lp = Players.LocalPlayer
end

local GB = {
	gen = GEN,
	dead = dead,
	lp = lp,
	conns = {},
	LoadModule = LoadModule,
	Require = Require,
}

local function optionalStub()
	local M = {}
	setmetatable(M, {
		__index = function()
			return function() end
		end,
	})
	return M
end

local loaded = 0
for _, row in ipairs(manifest.order) do
	local key, rel, kind = row.key, row.path, row.kind or "core"
	local factoryOk = row.factory ~= false
	local ok, result = pcall(LoadModule, rel)
	if not ok then
		if kind == "core" then
			error(tostring(result))
		end
		print("[Kaitun][Loader] optional fail " .. rel .. " — disabled")
		if key then
			GB[key] = optionalStub()
		end
	else
		print("[Kaitun][Loader] " .. rel)
		loaded = loaded + 1
		if factoryOk then
			if type(result) ~= "function" then
				if kind == "core" then
					error("[Kaitun][Loader] " .. rel .. " must return function(GB)")
				end
				print("[Kaitun][Loader] optional fail " .. rel .. " — not factory")
				GB[key] = optionalStub()
			else
				local ok2, inst = pcall(result, GB)
				if not ok2 then
					if kind == "core" then
						error("[Kaitun][Loader] init " .. rel .. " " .. tostring(inst))
					end
					print("[Kaitun][Loader] optional fail " .. rel .. " — init")
					GB[key] = optionalStub()
				else
					GB[key] = inst
				end
			end
		end
	end
end

print("[Kaitun][Loader] Loaded " .. loaded .. " modules")

local boot = LoadModule(manifest.entry or "kaitun.lua")
if type(boot) ~= "function" then
	error("[Kaitun][Loader] entry must return function(GB)")
end
boot(GB)

getgenv().GBKaitun = GB
getgenv().GBConfig = GB.Config
getgenv().GB_VERSION = MANIFEST_VER

return GB
