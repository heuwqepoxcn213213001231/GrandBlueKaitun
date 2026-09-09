return function(GB)
	if type(GB) ~= "table" then
		error("[GrandBlue UI] runtime table missing")
	end

	local library = GB.NiaLibrary
	if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
		error("[NiaUI] failed to load")
	end

	local Adapter = {
		Library = library,
		Version = library.Version,
	}

	local function copyOpts(opts)
		local out = {}
		if type(opts) ~= "table" then
			return out
		end
		for key, value in pairs(opts) do
			out[key] = value
		end
		return out
	end

	local function asUDim2(size, fallback)
		if typeof(size) == "UDim2" then
			return size
		end
		if typeof(size) == "Vector2" then
			return UDim2.fromOffset(size.X, size.Y)
		end
		if type(size) == "table" then
			local x = tonumber(size.X) or tonumber(size[1])
			local y = tonumber(size.Y) or tonumber(size[2])
			if x and y then
				return UDim2.fromOffset(x, y)
			end
		end
		return fallback
	end

	local function call(target, name, ...)
		local method = target and target[name]
		if type(method) ~= "function" then
			return nil
		end
		return method(target, ...)
	end

	local function wrapTab(tab)
		if type(tab) ~= "table" then
			return tab
		end

		local wrapped = { _raw = tab }

		function wrapped:AddSection(textOrOpts, maybeIcon)
			return call(tab, "AddSection", textOrOpts, maybeIcon)
		end

		function wrapped:AddDivider()
			return call(tab, "AddDivider")
		end

		function wrapped:AddLabel(text)
			return call(tab, "AddLabel", text)
		end

		function wrapped:AddParagraph(opts)
			return call(tab, "AddParagraph", opts)
		end

		function wrapped:AddButton(opts)
			return call(tab, "AddButton", opts)
		end

		function wrapped:AddToggle(opts)
			return call(tab, "AddToggle", opts)
		end

		function wrapped:AddSlider(opts)
			return call(tab, "AddSlider", opts)
		end

		function wrapped:AddDropdown(opts)
			return call(tab, "AddDropdown", opts)
		end

		function wrapped:AddMultiSelect(opts)
			local nextOpts = copyOpts(opts)
			nextOpts.MultiSelect = true
			return call(tab, "AddDropdown", nextOpts)
		end

		function wrapped:AddTextbox(opts)
			return call(tab, "AddTextbox", opts)
		end

		function wrapped:AddInput(opts)
			return call(tab, "AddTextbox", opts)
		end

		function wrapped:AddKeybind(opts)
			return call(tab, "AddKeybind", opts)
		end

		function wrapped:AddColorPicker(opts)
			return call(tab, "AddColorPicker", opts)
		end

		function wrapped:AddSubTab(nameOrOpts)
			local child = call(tab, "AddSubTab", nameOrOpts)
			return wrapTab(child)
		end

		return setmetatable(wrapped, {
			__index = tab,
		})
	end

	local function wrapWindow(window)
		if type(window) ~= "table" then
			return window
		end

		local wrapped = { _raw = window }

		function wrapped:AddTab(nameOrOpts)
			return wrapTab(call(window, "AddTab", nameOrOpts))
		end

		function wrapped:SetTitle(title, subtitle)
			return call(window, "SetTitle", title, subtitle)
		end

		function wrapped:SelectTab(nameOrIndex)
			return call(window, "SelectTab", nameOrIndex)
		end

		function wrapped:Destroy(...)
			return call(window, "Destroy", ...)
		end

		function wrapped:Toggle()
			return call(window, "Toggle")
		end

		function wrapped:Close()
			return call(window, "Close")
		end

		function wrapped:Open()
			return call(window, "Open")
		end

		return setmetatable(wrapped, {
			__index = window,
		})
	end

	function Adapter:CreateWindow(opts)
		local nextOpts = copyOpts(opts)
		if nextOpts.Size ~= nil then
			nextOpts.Size = asUDim2(nextOpts.Size, UDim2.fromOffset(860, 610))
		else
			nextOpts.Size = UDim2.fromOffset(860, 610)
		end
		local window = call(library, "CreateWindow", nextOpts)
		if type(window) ~= "table" then
			error("[NiaUI] CreateWindow returned no window")
		end
		self.Window = wrapWindow(window)
		return self.Window
	end

	function Adapter:AddTab(window, nameOrOpts)
		local target = window or self.Window
		if type(target) ~= "table" or type(target.AddTab) ~= "function" then
			error("[NiaUI] AddTab has no window")
		end
		return target:AddTab(nameOrOpts)
	end

	function Adapter:AddSection(tab, textOrOpts, maybeIcon)
		return tab:AddSection(textOrOpts, maybeIcon)
	end

	function Adapter:AddToggle(tab, opts)
		return tab:AddToggle(opts)
	end

	function Adapter:AddDropdown(tab, opts)
		return tab:AddDropdown(opts)
	end

	function Adapter:AddMultiSelect(tab, opts)
		return tab:AddMultiSelect(opts)
	end

	function Adapter:AddButton(tab, opts)
		return tab:AddButton(opts)
	end

	function Adapter:AddSlider(tab, opts)
		return tab:AddSlider(opts)
	end

	function Adapter:AddInput(tab, opts)
		return tab:AddInput(opts)
	end

	function Adapter:AddTextbox(tab, opts)
		return tab:AddTextbox(opts)
	end

	function Adapter:AddParagraph(tab, opts)
		return tab:AddParagraph(opts)
	end

	function Adapter:AddLabel(tab, text)
		return tab:AddLabel(text)
	end

	function Adapter:AddKeybind(tab, opts)
		return tab:AddKeybind(opts)
	end

	function Adapter:Notify(opts)
		return call(library, "Notify", opts)
	end

	function Adapter:Unload()
		return call(library, "Unload")
	end

	function Adapter:Destroy()
		return self:Unload()
	end

	GB.UIAdapter = Adapter
	GB.Nia = Adapter
	return Adapter
end
