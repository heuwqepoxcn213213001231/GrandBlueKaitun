return function(GB)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TextService = game:GetService("TextService")
    local CoreGui = game:GetService("CoreGui")

    local Nia = {}
    Nia.Name = "Nia Hub"
    Nia.Version = "2.7.7"
    Nia.Flags = {}
    Nia._Windows = {}
    Nia._Snapshots = {}
    Nia._Toasts = {}

    Nia.Theme = {
        Background = Color3.fromRGB(13, 15, 19),
        Sidebar = Color3.fromRGB(17, 20, 25),
        Surface = Color3.fromRGB(24, 28, 35),
        SurfaceHover = Color3.fromRGB(31, 36, 44),
        Border = Color3.fromRGB(58, 65, 76),
        Text = Color3.fromRGB(239, 242, 248),
        TextDim = Color3.fromRGB(145, 153, 166),
        Accent = Color3.fromRGB(112, 142, 255),
        AccentDark = Color3.fromRGB(66, 88, 176),
        Success = Color3.fromRGB(93, 207, 139),
        Warning = Color3.fromRGB(239, 183, 79),
        Error = Color3.fromRGB(236, 100, 112),
        Font = Enum.Font.GothamSemibold,
        FontRegular = Enum.Font.Gotham,
        CornerRadius = 12,
        CornerRadiusSmall = 8,
        Animation = 0.16,
    }

    local function getEnvironment()
        local ok, value = pcall(function()
            if type(getgenv) == "function" then
                return getgenv()
            end
            return _G
        end)
        return ok and value or _G
    end

    local environment = getEnvironment()
    local singletonKey = "__GrandBlue_NiaInline"
    local previous = environment[singletonKey]
    if type(previous) == "table" and type(previous.Unload) == "function" then
        pcall(function()
            previous:Unload()
        end)
    elseif type(previous) == "function" then
        pcall(previous)
    end
    environment[singletonKey] = nil

    local function clean(item)
        local kind = typeof(item)
        if kind == "RBXScriptConnection" then
            pcall(function()
                item:Disconnect()
            end)
        elseif kind == "Instance" then
            pcall(function()
                item:Destroy()
            end)
        elseif kind == "function" then
            pcall(item)
        elseif kind == "table" then
            if type(item.Destroy) == "function" then
                pcall(function()
                    item:Destroy()
                end)
            elseif type(item.Disconnect) == "function" then
                pcall(function()
                    item:Disconnect()
                end)
            end
        end
    end

    local Janitor = {}
    Janitor.__index = Janitor

    function Janitor.new()
        return setmetatable({
            _items = {},
            _dead = false,
        }, Janitor)
    end

    function Janitor:Add(item)
        if item == nil then
            return nil
        end
        if self._dead then
            clean(item)
            return item
        end
        table.insert(self._items, item)
        return item
    end

    function Janitor:Destroy()
        if self._dead then
            return
        end
        self._dead = true
        for index = #self._items, 1, -1 do
            local item = self._items[index]
            self._items[index] = nil
            clean(item)
        end
    end

    local libraryJanitor = Janitor.new()

    local function safeSpawn(callback, ...)
        if type(callback) ~= "function" then
            return
        end
        local arguments = table.pack(...)
        task.spawn(function()
            local ok, err = pcall(callback, table.unpack(arguments, 1, arguments.n))
            if not ok then
                warn("[Nia] callback error: " .. tostring(err))
            end
        end)
    end

    local Signal = {}
    Signal.__index = Signal

    function Signal.new()
        return setmetatable({
            _listeners = {},
            _dead = false,
        }, Signal)
    end

    function Signal:Connect(callback)
        assert(type(callback) == "function", "OnChanged callback must be a function")
        local listener = {
            Callback = callback,
            Connected = true,
        }
        table.insert(self._listeners, listener)

        local connection = {}
        function connection:Disconnect()
            if not listener.Connected then
                return
            end
            listener.Connected = false
            local index = table.find(self._signal._listeners, listener)
            if index then
                table.remove(self._signal._listeners, index)
            end
        end
        connection.Destroy = connection.Disconnect
        connection._signal = self

        if self._dead then
            connection:Disconnect()
        end
        return connection
    end

    function Signal:Fire(...)
        if self._dead then
            return
        end
        local listeners = table.clone(self._listeners)
        for _, listener in ipairs(listeners) do
            if listener.Connected then
                safeSpawn(listener.Callback, ...)
            end
        end
    end

    function Signal:Destroy()
        if self._dead then
            return
        end
        self._dead = true
        for _, listener in ipairs(self._listeners) do
            listener.Connected = false
        end
        table.clear(self._listeners)
    end

    local function create(className, parent, properties)
        local instance = Instance.new(className)
        for key, value in pairs(properties or {}) do
            instance[key] = value
        end
        if parent then
            instance.Parent = parent
        end
        return instance
    end

    local function addCorner(parent, radius)
        return create("UICorner", parent, {
            CornerRadius = UDim.new(0, radius or Nia.Theme.CornerRadiusSmall),
        })
    end

    local function addStroke(parent, color, transparency, thickness)
        return create("UIStroke", parent, {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = color or Nia.Theme.Border,
            Transparency = transparency or 0,
            Thickness = thickness or 1,
        })
    end

    local function addPadding(parent, top, right, bottom, left)
        return create("UIPadding", parent, {
            PaddingTop = UDim.new(0, top or 0),
            PaddingRight = UDim.new(0, right or 0),
            PaddingBottom = UDim.new(0, bottom or 0),
            PaddingLeft = UDim.new(0, left or 0),
        })
    end

    local function tween(instance, properties, duration, style, direction)
        if not instance or not instance.Parent then
            return nil
        end
        local ok, result = pcall(function()
            local animation = TweenService:Create(instance, TweenInfo.new(
                duration or Nia.Theme.Animation,
                style or Enum.EasingStyle.Quint,
                direction or Enum.EasingDirection.Out
            ), properties)
            animation:Play()
            return animation
        end)
        return ok and result or nil
    end

    local function connect(janitor, signal, callback)
        return janitor:Add(signal:Connect(callback))
    end

    local function viewportSize()
        local camera = workspace.CurrentCamera
        if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
            return camera.ViewportSize
        end
        return Vector2.new(1280, 720)
    end

    local function iconSymbol(icon)
        if icon == nil or icon == "" then
            return ""
        end
        local raw = tostring(icon)
        local name = raw:match(":(.+)$") or raw
        name = string.lower(name)
        local symbols = {
            home = "H",
            house = "H",
            settings = "#",
            cog = "#",
            quest = "?",
            quests = "?",
            search = "/",
            ["circle-x"] = "x",
            check = "+",
            warning = "!",
            info = "i",
            user = "@",
            users = "@",
            teleport = ">",
            map = ">",
            sword = "/",
            target = "+",
            box = "[]",
            package = "[]",
            code = "{}",
            terminal = ">_",
            debug = "*",
            star = "*",
            zap = "*",
        }
        if symbols[name] then
            return symbols[name]
        end
        if #raw <= 3 then
            return raw
        end
        return string.upper(string.sub(name, 1, 1))
    end

    local ROOT_NAME = "GrandBlueNiaInline"

    local function parentCandidates()
        local candidates = {}
        if type(gethui) == "function" then
            local ok, hidden = pcall(gethui)
            if ok and typeof(hidden) == "Instance" then
                table.insert(candidates, hidden)
            end
        end
        table.insert(candidates, CoreGui)
        local player = Players.LocalPlayer
        local playerGui = player and (
            player:FindFirstChildOfClass("PlayerGui")
            or player:WaitForChild("PlayerGui", 5)
        )
        if playerGui then
            table.insert(candidates, playerGui)
        end
        return candidates
    end

    local root = create("ScreenGui", nil, {
        Name = ROOT_NAME,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local rootParent
    for _, candidate in ipairs(parentCandidates()) do
        pcall(function()
            local stale = candidate:FindFirstChild(ROOT_NAME)
            if stale then
                stale:Destroy()
            end
        end)
        local ok = pcall(function()
            root.Parent = candidate
        end)
        if ok and root.Parent == candidate then
            rootParent = candidate
            break
        end
    end
    if not rootParent then
        root:Destroy()
        error("Nia could not attach its ScreenGui")
    end

    Nia._Root = root
    libraryJanitor:Add(root)

    local activePopupClose = nil

    local function clearActivePopup(callback)
        if activePopupClose == callback then
            activePopupClose = nil
        end
    end

    local function closeActivePopup()
        if not activePopupClose then
            return
        end
        local close = activePopupClose
        activePopupClose = nil
        pcall(close)
    end

    local function setActivePopup(callback)
        if activePopupClose and activePopupClose ~= callback then
            closeActivePopup()
        end
        activePopupClose = callback
    end

    local function bindPointer(janitor, target, onBegin, onMove, onEnd)
        local moveConnection
        local endConnection
        local activeInput
        local inputType

        local function stop(input)
            if not activeInput then
                return
            end
            local wasActive = activeInput
            activeInput = nil
            if moveConnection then
                moveConnection:Disconnect()
                moveConnection = nil
            end
            if endConnection then
                endConnection:Disconnect()
                endConnection = nil
            end
            if onEnd then
                onEnd(input or wasActive)
            end
        end

        janitor:Add(function()
            stop(activeInput)
        end)

        connect(janitor, target.InputBegan, function(input)
            if activeInput then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            activeInput = input
            inputType = input.UserInputType
            if onBegin then
                onBegin(input)
            end

            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not activeInput then
                    return
                end
                local relevant = inputType == Enum.UserInputType.Touch
                    and changed == activeInput
                    or inputType == Enum.UserInputType.MouseButton1
                    and changed.UserInputType == Enum.UserInputType.MouseMovement
                if relevant and onMove then
                    onMove(changed)
                end
            end)

            endConnection = UserInputService.InputEnded:Connect(function(ended)
                local relevant = inputType == Enum.UserInputType.Touch
                    and ended == activeInput
                    or inputType == Enum.UserInputType.MouseButton1
                    and ended.UserInputType == Enum.UserInputType.MouseButton1
                if relevant then
                    stop(ended)
                end
            end)
        end)
    end

    local function makeControlJanitor(tab, instance)
        local janitor = Janitor.new()
        tab._janitor:Add(janitor)
        janitor:Add(instance)
        return janitor
    end

    local function baseCard(tab, height)
        local card = create("Frame", tab._page, {
            Name = "Control",
            BackgroundColor3 = Nia.Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, height),
            ZIndex = 20,
        })
        addCorner(card, Nia.Theme.CornerRadiusSmall)
        addStroke(card, Nia.Theme.Border, 0.42)
        return card
    end

    local function addTitleAndDescription(card, title, description, rightReserve)
        local hasDescription = description ~= nil and tostring(description) ~= ""
        local titleLabel = create("TextLabel", card, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(14, hasDescription and 8 or 0),
            Size = UDim2.new(1, -(28 + (rightReserve or 0)), 0, hasDescription and 19 or card.Size.Y.Offset),
            Text = tostring(title or ""),
            TextColor3 = Nia.Theme.Text,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 22,
        })
        local descriptionLabel
        if hasDescription then
            descriptionLabel = create("TextLabel", card, {
                BackgroundTransparency = 1,
                Font = Nia.Theme.FontRegular,
                Position = UDim2.fromOffset(14, 28),
                Size = UDim2.new(1, -(28 + (rightReserve or 0)), 0, 16),
                Text = tostring(description),
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 22,
            })
        end
        return titleLabel, descriptionLabel
    end

    local function addHover(janitor, target, surface)
        connect(janitor, target.MouseEnter, function()
            tween(surface, { BackgroundColor3 = Nia.Theme.SurfaceHover }, 0.12)
        end)
        connect(janitor, target.MouseLeave, function()
            tween(surface, { BackgroundColor3 = Nia.Theme.Surface }, 0.12)
        end)
    end

    local function cloneValue(value, seen)
        if type(value) ~= "table" then
            return value
        end
        seen = seen or {}
        if seen[value] then
            return seen[value]
        end
        local output = {}
        seen[value] = output
        for key, child in pairs(value) do
            output[cloneValue(key, seen)] = cloneValue(child, seen)
        end
        return output
    end

    local function valuesEqual(left, right)
        if type(left) ~= type(right) then
            return false
        end
        if type(left) ~= "table" then
            return left == right
        end
        for key, value in pairs(left) do
            if not valuesEqual(value, right[key]) then
                return false
            end
        end
        for key in pairs(right) do
            if left[key] == nil then
                return false
            end
        end
        return true
    end

    local function registerFlag(options, api, kind)
        local flag = options and options.Flag
        if flag == nil or flag == "" then
            return api
        end
        flag = tostring(flag)
        api.Flag = flag
        api.Kind = kind
        api.Label = options.Text or options.Title or options.Label or flag
        Nia.Flags[flag] = api

        local originalDestroy = api.Destroy
        local destroyed = false
        api.Destroy = function(self)
            if destroyed then
                return
            end
            destroyed = true
            if Nia.Flags[flag] == api then
                Nia.Flags[flag] = nil
            end
            if originalDestroy then
                originalDestroy(self)
            end
        end
        return api
    end

    local Window = {}
    Window.__index = Window

    local Tab = {}
    Tab.__index = Tab

    local function sizeFromOption(option, viewport, fallback)
        if typeof(option) == "UDim2" then
            return Vector2.new(
                option.X.Scale * viewport.X + option.X.Offset,
                option.Y.Scale * viewport.Y + option.Y.Offset
            )
        end
        if typeof(option) == "Vector2" then
            return option
        end
        return fallback
    end

    function Window:_Clamp()
        if self._destroyed or not self._gui or not self._gui.Parent then
            return
        end
        local viewport = viewportSize()
        local maxWidth = math.max(180, viewport.X - 16)
        local maxHeight = math.max(150, viewport.Y - 16)
        local minimum = self._minimumSize
        local width = math.clamp(self._gui.Size.X.Offset, math.min(minimum.X, maxWidth), maxWidth)
        local height = math.clamp(self._gui.Size.Y.Offset, math.min(minimum.Y, maxHeight), maxHeight)
        self._gui.Size = UDim2.fromOffset(width, height)

        local halfWidth = width * 0.5
        local halfHeight = height * 0.5
        local x = math.clamp(self._gui.Position.X.Offset, halfWidth + 4, viewport.X - halfWidth - 4)
        local y = math.clamp(self._gui.Position.Y.Offset, halfHeight + 4, viewport.Y - halfHeight - 4)
        self._gui.Position = UDim2.fromOffset(x, y)
        self._normalSize = self._gui.Size
    end

    function Window:_Layout()
        if self._destroyed then
            return
        end
        local compact = self._gui.AbsoluteSize.X > 0 and self._gui.AbsoluteSize.X < 520
        local sidebarWidth = compact and 104 or 150
        self._sidebar.Size = UDim2.new(0, sidebarWidth, 1, -54)
        self._divider.Position = UDim2.fromOffset(sidebarWidth, 54)
        self._content.Position = UDim2.fromOffset(sidebarWidth + 1, 54)
        self._content.Size = UDim2.new(1, -(sidebarWidth + 1), 1, -54)
        self._compact = compact

        for _, tab in ipairs(self._tabs) do
            tab._icon.Visible = not compact
            tab._label.Position = UDim2.fromOffset(compact and 12 or 38, 0)
            tab._label.Size = UDim2.new(1, compact and -20 or -46, 1, 0)
        end
    end

    function Nia:CreateWindow(options)
        assert(not self._unloaded, "Nia is unloaded")
        options = options or {}

        local viewport = viewportSize()
        local touchLayout = UserInputService.TouchEnabled and viewport.X < 700
        local fallback = touchLayout
            and Vector2.new(viewport.X * 0.94, viewport.Y * 0.82)
            or Vector2.new(680, 460)
        local requested = sizeFromOption(options.Size, viewport, fallback)
        local maxWidth = math.max(180, viewport.X - 16)
        local maxHeight = math.max(150, viewport.Y - 16)
        local minimum = sizeFromOption(options.MinSize, viewport, Vector2.new(360, 280))
        local width = math.clamp(requested.X, math.min(minimum.X, maxWidth), maxWidth)
        local height = math.clamp(requested.Y, math.min(minimum.Y, maxHeight), maxHeight)

        local janitor = Janitor.new()
        libraryJanitor:Add(janitor)

        local main = create("Frame", root, {
            Name = "Window",
            Active = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Nia.Theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Position = UDim2.fromOffset(viewport.X * 0.5, viewport.Y * 0.5),
            Size = UDim2.fromOffset(width, height),
            ZIndex = 10 + #Nia._Windows * 20,
        })
        janitor:Add(main)
        addCorner(main, Nia.Theme.CornerRadius)
        addStroke(main, Nia.Theme.Border, 0.14)
        create("UIGradient", main, {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 21, 27)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 13, 17)),
            }),
            Rotation = 105,
        })

        local scale = create("UIScale", main, {
            Scale = 0.97,
        })

        local topbar = create("Frame", main, {
            Name = "TopBar",
            Active = true,
            BackgroundColor3 = Color3.fromRGB(19, 22, 28),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 54),
            ZIndex = main.ZIndex + 2,
        })

        create("Frame", topbar, {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Nia.Theme.Border,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = topbar.ZIndex + 1,
        })

        local logo = create("TextLabel", topbar, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Nia.Theme.Accent,
            BorderSizePixel = 0,
            Font = Nia.Theme.Font,
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            Text = "N",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            ZIndex = topbar.ZIndex + 2,
        })
        addCorner(logo, 8)

        local titleLabel = create("TextLabel", topbar, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(52, options.Subtitle and 8 or 0),
            Size = UDim2.new(1, -160, 0, options.Subtitle and 22 or 54),
            Text = tostring(options.Title or Nia.Name),
            TextColor3 = Nia.Theme.Text,
            TextSize = 15,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = topbar.ZIndex + 2,
        })

        local subtitleLabel
        if options.Subtitle then
            subtitleLabel = create("TextLabel", topbar, {
                BackgroundTransparency = 1,
                Font = Nia.Theme.FontRegular,
                Position = UDim2.fromOffset(52, 28),
                Size = UDim2.new(1, -160, 0, 16),
                Text = tostring(options.Subtitle),
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = topbar.ZIndex + 2,
            })
        end

        local function topButton(text, offset)
            local button = create("TextButton", topbar, {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = Nia.Theme.Surface,
                BackgroundTransparency = 0.28,
                BorderSizePixel = 0,
                Font = Nia.Theme.Font,
                Position = UDim2.new(1, offset, 0.5, 0),
                Size = UDim2.fromOffset(27, 27),
                Text = text,
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 13,
                ZIndex = topbar.ZIndex + 3,
            })
            addCorner(button, 8)
            addStroke(button, Nia.Theme.Border, 0.42)
            connect(janitor, button.MouseEnter, function()
                tween(button, {
                    BackgroundColor3 = Nia.Theme.SurfaceHover,
                    TextColor3 = Nia.Theme.Text,
                }, 0.1)
            end)
            connect(janitor, button.MouseLeave, function()
                tween(button, {
                    BackgroundColor3 = Nia.Theme.Surface,
                    TextColor3 = Nia.Theme.TextDim,
                }, 0.1)
            end)
            return button
        end

        local hideButton = topButton("-", -48)
        local destroyButton = topButton("x", -14)

        local sidebar = create("ScrollingFrame", main, {
            Name = "Sidebar",
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Nia.Theme.Sidebar,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.fromOffset(0, 54),
            ScrollBarImageColor3 = Nia.Theme.TextDim,
            ScrollBarImageTransparency = 0.45,
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.new(0, 150, 1, -54),
            ZIndex = main.ZIndex + 1,
        })
        addPadding(sidebar, 12, 9, 12, 9)
        local sidebarLayout = create("UIListLayout", sidebar, {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local divider = create("Frame", main, {
            BackgroundColor3 = Nia.Theme.Border,
            BackgroundTransparency = 0.38,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(150, 54),
            Size = UDim2.new(0, 1, 1, -54),
            ZIndex = main.ZIndex + 2,
        })

        local content = create("Frame", main, {
            Name = "Content",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.fromOffset(151, 54),
            Size = UDim2.new(1, -151, 1, -54),
            ZIndex = main.ZIndex + 1,
        })

        local resizeHandle = create("TextButton", main, {
            AnchorPoint = Vector2.new(1, 1),
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Nia.Theme.Font,
            Position = UDim2.new(1, -3, 1, -2),
            Size = UDim2.fromOffset(24, 24),
            Text = "//",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 11,
            ZIndex = main.ZIndex + 8,
        })

        local window = setmetatable({
            _gui = main,
            _scale = scale,
            _topbar = topbar,
            _sidebar = sidebar,
            _sidebarLayout = sidebarLayout,
            _divider = divider,
            _content = content,
            _resizeHandle = resizeHandle,
            _titleLabel = titleLabel,
            _subtitleLabel = subtitleLabel,
            _tabs = {},
            _currentTab = nil,
            _janitor = janitor,
            _minimumSize = minimum,
            _normalSize = main.Size,
            _toggleKey = options.ToggleKeybind == false
                and nil
                or options.ToggleKeybind
                or Enum.KeyCode.RightShift,
            _open = true,
            _destroyed = false,
        }, Window)

        table.insert(Nia._Windows, window)

        connect(janitor, hideButton.MouseButton1Click, function()
            window:Close()
        end)
        connect(janitor, destroyButton.MouseButton1Click, function()
            window:Destroy()
        end)

        if options.Draggable ~= false then
            local dragOrigin
            local positionOrigin
            bindPointer(janitor, topbar, function(input)
                dragOrigin = input.Position
                positionOrigin = main.Position
                closeActivePopup()
            end, function(input)
                local delta = input.Position - dragOrigin
                main.Position = UDim2.fromOffset(
                    positionOrigin.X.Offset + delta.X,
                    positionOrigin.Y.Offset + delta.Y
                )
                window:_Clamp()
            end)
        end

        if options.Resizable ~= false then
            local resizeOrigin
            local sizeOrigin
            bindPointer(janitor, resizeHandle, function(input)
                resizeOrigin = input.Position
                sizeOrigin = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
                closeActivePopup()
            end, function(input)
                local delta = input.Position - resizeOrigin
                main.Size = UDim2.fromOffset(
                    sizeOrigin.X + delta.X,
                    sizeOrigin.Y + delta.Y
                )
                window:_Clamp()
                window:_Layout()
            end, function()
                window._normalSize = main.Size
            end)
        else
            resizeHandle.Visible = false
        end

        connect(janitor, main:GetPropertyChangedSignal("AbsoluteSize"), function()
            window:_Layout()
        end)

        connect(janitor, sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            sidebar.CanvasSize = UDim2.fromOffset(0, sidebarLayout.AbsoluteContentSize.Y + 24)
        end)

        window:_Clamp()
        window:_Layout()
        tween(scale, { Scale = 1 }, 0.24, Enum.EasingStyle.Back)
        return window
    end

    function Window:AddTab(options)
        assert(not self._destroyed, "Window is destroyed")
        options = type(options) == "table" and options or { Name = options }
        local name = tostring(options.Name or options.Title or "Tab")
        local tabJanitor = Janitor.new()
        self._janitor:Add(tabJanitor)

        local button = create("TextButton", self._sidebar, {
            AutoButtonColor = false,
            BackgroundColor3 = Nia.Theme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = #self._tabs + 1,
            Name = name,
            Size = UDim2.new(1, 0, 0, 38),
            Text = "",
            ZIndex = self._gui.ZIndex + 3,
        })
        tabJanitor:Add(button)
        addCorner(button, 8)

        local accent = create("Frame", button, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Nia.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 20),
            ZIndex = button.ZIndex + 2,
        })
        addCorner(accent, 2)

        local icon = create("TextLabel", button, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.fromOffset(20, 38),
            Text = iconSymbol(options.Icon),
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 12,
            ZIndex = button.ZIndex + 2,
        })

        local label = create("TextLabel", button, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(38, 0),
            Size = UDim2.new(1, -46, 1, 0),
            Text = name,
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = button.ZIndex + 2,
        })

        local page = create("ScrollingFrame", self._content, {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = Nia.Theme.TextDim,
            ScrollBarImageTransparency = 0.35,
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            ZIndex = self._gui.ZIndex + 2,
        })
        tabJanitor:Add(page)
        addPadding(page, 14, 13, 14, 13)
        local layout = create("UIListLayout", page, {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local tab = setmetatable({
            Name = name,
            Instance = page,
            _button = button,
            _accent = accent,
            _icon = icon,
            _label = label,
            _page = page,
            _layout = layout,
            _window = self,
            _janitor = tabJanitor,
            _destroyed = false,
        }, Tab)

        table.insert(self._tabs, tab)

        connect(tabJanitor, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 28)
        end)
        connect(tabJanitor, button.MouseEnter, function()
            if self._currentTab ~= tab then
                tween(button, { BackgroundTransparency = 0.55 }, 0.1)
            end
        end)
        connect(tabJanitor, button.MouseLeave, function()
            if self._currentTab ~= tab then
                tween(button, { BackgroundTransparency = 1 }, 0.1)
            end
        end)
        connect(tabJanitor, button.MouseButton1Click, function()
            self:SelectTab(tab)
        end)

        self:_Layout()
        if not self._currentTab then
            self:SelectTab(tab)
        end
        return tab
    end

    function Window:SelectTab(nameOrIndex)
        if self._destroyed then
            return nil
        end
        local target
        if getmetatable(nameOrIndex) == Tab then
            target = nameOrIndex
        elseif type(nameOrIndex) == "number" then
            target = self._tabs[nameOrIndex]
        else
            for _, tab in ipairs(self._tabs) do
                if tab.Name == tostring(nameOrIndex) then
                    target = tab
                    break
                end
            end
        end
        if not target or target._destroyed then
            return nil
        end

        closeActivePopup()
        self._currentTab = target
        for _, tab in ipairs(self._tabs) do
            local selected = tab == target
            tab._page.Visible = selected
            tween(tab._button, {
                BackgroundTransparency = selected and 0.16 or 1,
            }, 0.14)
            tween(tab._label, {
                TextColor3 = selected and Nia.Theme.Text or Nia.Theme.TextDim,
            }, 0.14)
            tween(tab._icon, {
                TextColor3 = selected and Nia.Theme.Accent or Nia.Theme.TextDim,
            }, 0.14)
            tween(tab._accent, {
                BackgroundTransparency = selected and 0 or 1,
            }, 0.14)
        end
        return target
    end

    function Window:SetTitle(title, subtitle)
        if self._destroyed then
            return
        end
        if title ~= nil then
            self._titleLabel.Text = tostring(title)
        end
        if subtitle ~= nil then
            if self._subtitleLabel then
                self._subtitleLabel.Text = tostring(subtitle)
            end
        end
    end

    function Window:IsOpen()
        return not self._destroyed and self._open
    end

    function Window:Open()
        if self._destroyed or self._open then
            return false
        end
        self._open = true
        self._transition = (self._transition or 0) + 1
        self._gui.Visible = true
        self._scale.Scale = 0.97
        tween(self._scale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
        return true
    end

    function Window:Close()
        if self._destroyed or not self._open then
            return false
        end
        closeActivePopup()
        self._open = false
        self._transition = (self._transition or 0) + 1
        local token = self._transition
        tween(self._scale, { Scale = 0.97 }, 0.12)
        task.delay(0.12, function()
            if not self._destroyed and not self._open and self._transition == token then
                self._gui.Visible = false
            end
        end)
        return true
    end

    Window.Hide = Window.Close
    Window.Show = Window.Open

    function Window:Toggle()
        if self._open then
            return self:Close()
        end
        return self:Open()
    end

    function Window:Destroy()
        if self._destroyed then
            return
        end
        self._destroyed = true
        self._open = false
        closeActivePopup()
        local index = table.find(Nia._Windows, self)
        if index then
            table.remove(Nia._Windows, index)
        end
        self._janitor:Destroy()
        table.clear(self._tabs)
        self._currentTab = nil
    end

    function Tab:Destroy()
        if self._destroyed then
            return
        end
        self._destroyed = true
        local window = self._window
        local index = table.find(window._tabs, self)
        if index then
            table.remove(window._tabs, index)
        end
        local wasSelected = window._currentTab == self
        self._janitor:Destroy()
        if wasSelected then
            window._currentTab = nil
            if window._tabs[1] then
                window:SelectTab(1)
            end
        end
        window:_Layout()
    end

    function Tab:AddSection(textOrOptions, icon)
        local options = type(textOrOptions) == "table"
            and textOrOptions
            or { Text = textOrOptions, Icon = icon }
        local holder = create("Frame", self._page, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25),
            ZIndex = 20,
        })
        local janitor = makeControlJanitor(self, holder)
        local symbol = iconSymbol(options.Icon)
        local label = create("TextLabel", holder, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(2, 5),
            Size = UDim2.new(1, -4, 0, 18),
            Text = (symbol ~= "" and symbol .. "  " or "") .. string.upper(tostring(options.Text or "Section")),
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 10,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 21,
        })
        local signal = Signal.new()
        janitor:Add(signal)
        local api = {
            Instance = holder,
            Set = function(_, value, silent)
                label.Text = string.upper(tostring(value or ""))
                if not silent then
                    signal:Fire(value)
                end
            end,
            Get = function()
                return label.Text
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Section")
    end

    function Tab:AddLabel(textOrOptions)
        local options = type(textOrOptions) == "table"
            and textOrOptions
            or { Text = textOrOptions }
        local label = create("TextLabel", self._page, {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Nia.Theme.FontRegular,
            Size = UDim2.new(1, 0, 0, 17),
            Text = tostring(options.Text or ""),
            TextColor3 = options.Color or Nia.Theme.TextDim,
            TextSize = options.TextSize or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 20,
        })
        local janitor = makeControlJanitor(self, label)
        local signal = Signal.new()
        janitor:Add(signal)
        local api = {
            Instance = label,
            Set = function(_, value, silent)
                label.Text = tostring(value or "")
                if not silent then
                    signal:Fire(label.Text)
                end
            end,
            Get = function()
                return label.Text
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Label")
    end

    function Tab:AddParagraph(options)
        options = type(options) == "table" and options or { Text = options }
        local card = create("Frame", self._page, {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Nia.Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 20,
        })
        addCorner(card, Nia.Theme.CornerRadiusSmall)
        addStroke(card, Nia.Theme.Border, 0.42)
        addPadding(card, 12, 14, 12, 14)
        create("UIListLayout", card, {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        local janitor = makeControlJanitor(self, card)

        local title = create("TextLabel", card, {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 17),
            Text = tostring(options.Title or ""),
            TextColor3 = Nia.Theme.Text,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Visible = options.Title ~= nil and tostring(options.Title) ~= "",
            ZIndex = 21,
        })
        local body = create("TextLabel", card, {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Nia.Theme.FontRegular,
            LayoutOrder = 2,
            RichText = options.RichText == true,
            Size = UDim2.new(1, 0, 0, 17),
            Text = tostring(options.Text or ""),
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 21,
        })
        local signal = Signal.new()
        janitor:Add(signal)

        local api = {
            Instance = card,
            Set = function(_, value, silent)
                body.Text = tostring(value or "")
                if not silent then
                    signal:Fire(body.Text)
                end
            end,
            Get = function()
                return body.Text
            end,
            SetTitle = function(_, value)
                title.Text = tostring(value or "")
                title.Visible = title.Text ~= ""
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Paragraph")
    end

    function Tab:AddButton(options)
        options = type(options) == "table" and options or { Text = options }
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
        local card = baseCard(self, hasDescription and 56 or 44)
        local janitor = makeControlJanitor(self, card)
        local title = addTitleAndDescription(
            card,
            options.Text or options.Name or "Button",
            options.Description,
            30
        )
        local arrow = create("TextLabel", card, {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(16, 20),
            Text = ">",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 15,
            ZIndex = 22,
        })
        local click = create("TextButton", card, {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            ZIndex = 24,
        })
        local signal = Signal.new()
        janitor:Add(signal)
        addHover(janitor, click, card)
        connect(janitor, click.MouseEnter, function()
            tween(arrow, {
                Position = UDim2.new(1, -10, 0.5, 0),
                TextColor3 = Nia.Theme.Text,
            }, 0.12)
        end)
        connect(janitor, click.MouseLeave, function()
            tween(arrow, {
                Position = UDim2.new(1, -14, 0.5, 0),
                TextColor3 = Nia.Theme.TextDim,
            }, 0.12)
        end)
        connect(janitor, click.MouseButton1Click, function()
            signal:Fire()
            safeSpawn(options.Callback)
        end)

        return {
            Instance = card,
            Set = function(_, value)
                title.Text = tostring(value or "")
            end,
            Get = function()
                return title.Text
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
    end

    function Tab:AddToggle(options)
        options = options or {}
        local state = options.Default == true
        local locked = options.Locked == true
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
        local card = baseCard(self, hasDescription and 56 or 44)
        local janitor = makeControlJanitor(self, card)
        addTitleAndDescription(card, options.Text or "Toggle", options.Description, 62)

        local switch = create("Frame", card, {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Nia.Theme.SurfaceHover,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(40, 22),
            ZIndex = 22,
        })
        addCorner(switch, 11)
        local switchStroke = addStroke(switch, Nia.Theme.Border, 0.2)
        local knob = create("Frame", switch, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Nia.Theme.TextDim,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            ZIndex = 23,
        })
        addCorner(knob, 8)
        local click = create("TextButton", card, {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            ZIndex = 24,
        })
        local signal = Signal.new()
        janitor:Add(signal)

        local function render()
            tween(switch, {
                BackgroundColor3 = state and Nia.Theme.Accent or Nia.Theme.SurfaceHover,
            }, 0.18)
            tween(switchStroke, {
                Color = state and Nia.Theme.Accent or Nia.Theme.Border,
            }, 0.18)
            tween(knob, {
                BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Nia.Theme.TextDim,
                Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            }, 0.18)
            card.BackgroundTransparency = locked and 0.28 or 0
            click.Active = not locked
        end

        local function fire()
            safeSpawn(options.Callback, state)
            signal:Fire(state)
        end

        addHover(janitor, click, card)
        connect(janitor, click.MouseButton1Click, function()
            if locked then
                return
            end
            state = not state
            render()
            fire()
        end)
        render()

        local api = {
            Instance = card,
            Set = function(_, value, silent)
                local nextState = value == true
                local changed = nextState ~= state
                state = nextState
                render()
                if changed and not silent then
                    fire()
                end
            end,
            Get = function()
                return state
            end,
            SetLocked = function(_, value)
                locked = value == true
                render()
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Toggle")
    end

    local function decimalPlaces(increment)
        local text = tostring(increment)
        local decimal = text:match("%.(%d+)")
        return decimal and math.min(#decimal, 6) or 0
    end

    local function snapNumber(value, minimum, maximum, increment)
        if maximum == minimum then
            return minimum
        end
        increment = math.abs(increment)
        if increment <= 0 then
            increment = 1
        end
        local snapped = minimum + math.floor((value - minimum) / increment + 0.5) * increment
        snapped = math.clamp(snapped, minimum, maximum)
        local factor = 10 ^ decimalPlaces(increment)
        return math.floor(snapped * factor + 0.5) / factor
    end

    local function formatNumber(value)
        if math.abs(value - math.floor(value + 0.5)) < 0.000001 then
            return tostring(math.floor(value + 0.5))
        end
        return string.format("%.4g", value)
    end

    function Tab:AddSlider(options)
        options = options or {}
        local minimum = tonumber(options.Min) or 0
        local maximum = tonumber(options.Max) or 100
        if maximum < minimum then
            minimum, maximum = maximum, minimum
        end
        local increment = math.abs(tonumber(options.Increment) or 1)
        if increment == 0 then
            increment = 1
        end
        local value = snapNumber(tonumber(options.Default) or minimum, minimum, maximum, increment)
        local suffix = tostring(options.Suffix or "")
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""

        local card = baseCard(self, hasDescription and 78 or 64)
        local janitor = makeControlJanitor(self, card)
        addTitleAndDescription(card, options.Text or "Slider", options.Description, 78)

        local valueLabel = create("TextLabel", card, {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Font = Nia.Theme.FontRegular,
            Position = UDim2.new(1, -14, 0, 8),
            Size = UDim2.fromOffset(70, 18),
            Text = "",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 22,
        })
        local track = create("Frame", card, {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Color3.fromRGB(45, 51, 61),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 14, 1, -16),
            Size = UDim2.new(1, -28, 0, 6),
            ZIndex = 22,
        })
        addCorner(track, 3)
        local fill = create("Frame", track, {
            BackgroundColor3 = Nia.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 23,
        })
        addCorner(fill, 3)
        local knob = create("Frame", track, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = 24,
        })
        addCorner(knob, 7)
        addStroke(knob, Nia.Theme.AccentDark, 0, 2)
        local hitbox = create("TextButton", track, {
            AnchorPoint = Vector2.new(0, 0.5),
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            ZIndex = 25,
        })
        local signal = Signal.new()
        janitor:Add(signal)

        local function alpha()
            if maximum == minimum then
                return 0
            end
            return math.clamp((value - minimum) / (maximum - minimum), 0, 1)
        end

        local function render(animated)
            local amount = alpha()
            valueLabel.Text = formatNumber(value) .. suffix
            if animated then
                tween(fill, { Size = UDim2.new(amount, 0, 1, 0) }, 0.12)
                tween(knob, { Position = UDim2.new(amount, 0, 0.5, 0) }, 0.12)
            else
                fill.Size = UDim2.new(amount, 0, 1, 0)
                knob.Position = UDim2.new(amount, 0, 0.5, 0)
            end
        end

        local function fire()
            safeSpawn(options.Callback, value)
            signal:Fire(value)
        end

        local function setValue(nextValue, silent, animated)
            nextValue = snapNumber(tonumber(nextValue) or minimum, minimum, maximum, increment)
            local changed = nextValue ~= value
            value = nextValue
            render(animated)
            if changed and not silent then
                fire()
            end
        end

        local function updateFromInput(input)
            if track.AbsoluteSize.X <= 0 then
                return
            end
            local amount = math.clamp(
                (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                0,
                1
            )
            setValue(minimum + amount * (maximum - minimum), false, false)
        end

        bindPointer(janitor, hitbox, function(input)
            updateFromInput(input)
            tween(knob, { Size = UDim2.fromOffset(17, 17) }, 0.1)
        end, updateFromInput, function()
            tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.12)
            render(true)
        end)
        render(false)

        local api = {
            Instance = card,
            Set = function(_, nextValue, silent)
                setValue(nextValue, silent, true)
            end,
            Get = function()
                return value
            end,
            SetRange = function(_, nextMinimum, nextMaximum, nextIncrement)
                nextMinimum = tonumber(nextMinimum) or minimum
                nextMaximum = tonumber(nextMaximum) or maximum
                if nextMaximum < nextMinimum then
                    nextMinimum, nextMaximum = nextMaximum, nextMinimum
                end
                minimum, maximum = nextMinimum, nextMaximum
                if nextIncrement ~= nil then
                    increment = math.abs(tonumber(nextIncrement) or increment)
                    if increment == 0 then
                        increment = 1
                    end
                end
                setValue(value, true, true)
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Slider")
    end

    local function normalizeOptions(values)
        local result = {}
        local seen = {}
        for _, value in ipairs(type(values) == "table" and values or {}) do
            if value ~= nil and not seen[value] then
                seen[value] = true
                table.insert(result, value)
            end
        end
        return result
    end

    function Tab:AddDropdown(options)
        options = options or {}
        local values = normalizeOptions(options.Options)
        local multi = options.MultiSelect == true
        local selected = multi and {} or nil
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
        local card = baseCard(self, hasDescription and 56 or 44)
        local janitor = makeControlJanitor(self, card)
        addTitleAndDescription(card, options.Text or "Dropdown", options.Description, 164)

        local valueLabel = create("TextLabel", card, {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(19, 22, 28),
            BorderSizePixel = 0,
            Font = Nia.Theme.FontRegular,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(142, 27),
            Text = "",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        })
        addCorner(valueLabel, 7)
        addStroke(valueLabel, Nia.Theme.Border, 0.38)
        local chevron = create("TextLabel", valueLabel, {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(14, 18),
            Text = "v",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 10,
            ZIndex = 23,
        })
        local valueText = create("TextLabel", valueLabel, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.FontRegular,
            Position = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -31, 1, 0),
            Text = "",
            TextColor3 = Nia.Theme.TextDim,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 23,
        })
        local click = create("TextButton", card, {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            ZIndex = 25,
        })
        local signal = Signal.new()
        janitor:Add(signal)
        local popupJanitor

        local function containsValue(value)
            return table.find(values, value) ~= nil
        end

        local function getValue()
            if not multi then
                return selected
            end
            local result = {}
            for _, option in ipairs(values) do
                if selected[option] then
                    table.insert(result, option)
                end
            end
            return result
        end

        local function displayValue()
            if not multi then
                return selected == nil and "None" or tostring(selected)
            end
            local result = getValue()
            if #result == 0 then
                return "None"
            elseif #result == 1 then
                return tostring(result[1])
            elseif #result == 2 then
                return tostring(result[1]) .. ", " .. tostring(result[2])
            end
            return tostring(#result) .. " selected"
        end

        local function renderValue()
            valueText.Text = displayValue()
        end

        local function fire()
            local current = getValue()
            safeSpawn(options.Callback, cloneValue(current))
            signal:Fire(cloneValue(current))
        end

        local closePopup

        closePopup = function()
            clearActivePopup(closePopup)
            chevron.Text = "v"
            if popupJanitor then
                local old = popupJanitor
                popupJanitor = nil
                old:Destroy()
            end
        end

        local function setSelection(nextValue, silent)
            local before = cloneValue(getValue())
            if multi then
                selected = {}
                if type(nextValue) == "table" then
                    for _, value in ipairs(nextValue) do
                        if containsValue(value) then
                            selected[value] = true
                        end
                    end
                end
            else
                if nextValue == nil or containsValue(nextValue) then
                    selected = nextValue
                else
                    selected = nil
                end
            end
            renderValue()
            if not silent and not valuesEqual(before, getValue()) then
                fire()
            end
        end

        local function setOptions(nextOptions, silent)
            local before = cloneValue(getValue())
            values = normalizeOptions(nextOptions)
            if multi then
                local pruned = {}
                for _, value in ipairs(values) do
                    if selected[value] then
                        pruned[value] = true
                    end
                end
                selected = pruned
            elseif selected ~= nil and not containsValue(selected) then
                selected = nil
            end
            closePopup()
            renderValue()
            if not silent and not valuesEqual(before, getValue()) then
                fire()
            end
        end

        local function popupPosition(width, height)
            local viewport = viewportSize()
            local cardPosition = card.AbsolutePosition
            local cardSize = card.AbsoluteSize
            local x = cardPosition.X + cardSize.X - width
            local y = cardPosition.Y + cardSize.Y + 7
            if y + height > viewport.Y - 8 then
                y = cardPosition.Y - height - 7
            end
            x = math.clamp(x, 8, math.max(8, viewport.X - width - 8))
            y = math.clamp(y, 8, math.max(8, viewport.Y - height - 8))
            return UDim2.fromOffset(math.floor(x), math.floor(y))
        end

        local function openPopup()
            if popupJanitor or self._destroyed or not card.Parent then
                return
            end
            popupJanitor = Janitor.new()
            local popup = popupJanitor
            janitor:Add(popup)
            setActivePopup(closePopup)
            chevron.Text = "^"

            local viewport = viewportSize()
            local width = math.min(300, math.max(210, viewport.X - 16))
            local listHeight = math.min(math.max(#values, 1) * 32 + 8, 224)
            local height = 48 + listHeight

            local backdrop = create("TextButton", root, {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                ZIndex = 290,
            })
            popup:Add(backdrop)
            connect(popup, backdrop.MouseButton1Click, closePopup)

            local frame = create("Frame", root, {
                Active = true,
                BackgroundColor3 = Nia.Theme.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Position = popupPosition(width, height),
                Size = UDim2.fromOffset(width, height),
                ZIndex = 300,
            })
            popup:Add(frame)
            addCorner(frame, 10)
            addStroke(frame, Nia.Theme.Border, 0.1)

            local searchHolder = create("Frame", frame, {
                BackgroundColor3 = Nia.Theme.Surface,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.new(1, -16, 0, 32),
                ZIndex = 302,
            })
            addCorner(searchHolder, 7)
            addStroke(searchHolder, Nia.Theme.Border, 0.4)
            create("TextLabel", searchHolder, {
                BackgroundTransparency = 1,
                Font = Nia.Theme.Font,
                Position = UDim2.fromOffset(9, 0),
                Size = UDim2.fromOffset(18, 32),
                Text = "/",
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 12,
                ZIndex = 303,
            })
            local search = create("TextBox", searchHolder, {
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Font = Nia.Theme.FontRegular,
                PlaceholderColor3 = Nia.Theme.TextDim,
                PlaceholderText = "Search options",
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Text = "",
                TextColor3 = Nia.Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 303,
            })

            local list = create("ScrollingFrame", frame, {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(),
                Position = UDim2.fromOffset(6, 46),
                ScrollBarImageColor3 = Nia.Theme.TextDim,
                ScrollBarImageTransparency = 0.3,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, -12, 1, -52),
                ZIndex = 302,
            })
            addPadding(list, 2, 4, 4, 2)
            local layout = create("UIListLayout", list, {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            local rows = {}
            local empty = create("TextLabel", list, {
                BackgroundTransparency = 1,
                Font = Nia.Theme.FontRegular,
                LayoutOrder = 1000000,
                Size = UDim2.new(1, 0, 0, 44),
                Text = "No matching options",
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 11,
                Visible = #values == 0,
                ZIndex = 303,
            })

            local function renderRows()
                for _, entry in ipairs(rows) do
                    local isSelected = multi and selected[entry.Value] == true
                        or not multi and selected == entry.Value
                    entry.Mark.Text = isSelected and "+" or ""
                    entry.Mark.BackgroundColor3 = isSelected
                        and Nia.Theme.Accent
                        or Color3.fromRGB(31, 36, 44)
                    entry.Label.TextColor3 = isSelected and Nia.Theme.Text or Nia.Theme.TextDim
                    entry.Button.BackgroundTransparency = isSelected and 0.22 or 1
                end
            end

            for index, option in ipairs(values) do
                local optionValue = option
                local row = create("TextButton", list, {
                    AutoButtonColor = false,
                    BackgroundColor3 = Nia.Theme.SurfaceHover,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = index,
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    ZIndex = 303,
                })
                addCorner(row, 7)
                local rowLabel = create("TextLabel", row, {
                    BackgroundTransparency = 1,
                    Font = Nia.Theme.FontRegular,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -43, 1, 0),
                    Text = tostring(optionValue),
                    TextColor3 = Nia.Theme.TextDim,
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 304,
                })
                local mark = create("TextLabel", row, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Nia.Theme.SurfaceHover,
                    BorderSizePixel = 0,
                    Font = Nia.Theme.Font,
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    Text = "",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 11,
                    ZIndex = 304,
                })
                addCorner(mark, 5)
                addStroke(mark, Nia.Theme.Border, 0.32)
                local entry = {
                    Button = row,
                    Label = rowLabel,
                    Mark = mark,
                    Value = optionValue,
                }
                table.insert(rows, entry)

                connect(popup, row.MouseEnter, function()
                    tween(row, { BackgroundTransparency = 0.12 }, 0.08)
                end)
                connect(popup, row.MouseLeave, function()
                    renderRows()
                end)
                connect(popup, row.MouseButton1Click, function()
                    if multi then
                        selected[optionValue] = not selected[optionValue] or nil
                        renderValue()
                        renderRows()
                        fire()
                    else
                        selected = optionValue
                        renderValue()
                        fire()
                        closePopup()
                    end
                end)
            end

            local function applySearch()
                local query = string.lower(search.Text)
                local visible = 0
                for _, entry in ipairs(rows) do
                    local match = query == ""
                        or string.find(string.lower(tostring(entry.Value)), query, 1, true) ~= nil
                    entry.Button.Visible = match
                    if match then
                        visible = visible + 1
                    end
                end
                empty.Visible = visible == 0
            end

            connect(popup, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
            end)
            connect(popup, search:GetPropertyChangedSignal("Text"), applySearch)
            renderRows()
            applySearch()
            task.defer(function()
                if search.Parent then
                    search:CaptureFocus()
                end
            end)
        end

        connect(janitor, click.MouseButton1Click, function()
            if popupJanitor then
                closePopup()
            else
                openPopup()
            end
        end)
        addHover(janitor, click, card)
        janitor:Add(closePopup)

        if multi then
            setSelection(options.Default or {}, true)
        else
            local initial = options.Default
            if initial == nil then
                initial = values[1]
            end
            setSelection(initial, true)
        end

        local api = {
            Instance = card,
            Set = function(_, value, silent)
                setSelection(value, silent)
                closePopup()
            end,
            Get = function()
                return cloneValue(getValue())
            end,
            SetOptions = function(_, nextOptions, silent)
                setOptions(nextOptions or {}, silent)
            end,
            Refresh = function(_, nextOptions, silent)
                setOptions(nextOptions or values, silent)
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                closePopup()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Dropdown")
    end

    function Tab:AddTextbox(options)
        options = options or {}
        local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
        local card = baseCard(self, hasDescription and 56 or 44)
        local janitor = makeControlJanitor(self, card)
        addTitleAndDescription(card, options.Text or "Textbox", options.Description, 174)

        local holder = create("Frame", card, {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(19, 22, 28),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(152, 28),
            ZIndex = 22,
        })
        addCorner(holder, 7)
        local holderStroke = addStroke(holder, Nia.Theme.Border, 0.36)
        local box = create("TextBox", holder, {
            BackgroundTransparency = 1,
            ClearTextOnFocus = options.ClearTextOnFocus == true,
            Font = Nia.Theme.FontRegular,
            PlaceholderColor3 = Nia.Theme.TextDim,
            PlaceholderText = tostring(options.Placeholder or ""),
            Position = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Text = tostring(options.Default or ""),
            TextColor3 = Nia.Theme.Text,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 23,
        })
        local signal = Signal.new()
        janitor:Add(signal)

        local function fire(enterPressed)
            safeSpawn(options.Callback, box.Text, enterPressed == true)
            signal:Fire(box.Text, enterPressed == true)
        end

        connect(janitor, box.Focused, function()
            tween(holderStroke, {
                Color = Nia.Theme.Accent,
                Transparency = 0,
            }, 0.12)
        end)
        connect(janitor, box.FocusLost, function(enterPressed)
            tween(holderStroke, {
                Color = Nia.Theme.Border,
                Transparency = 0.36,
            }, 0.12)
            fire(enterPressed)
        end)

        local api = {
            Instance = card,
            Set = function(_, value, silent)
                local text = tostring(value or "")
                local changed = text ~= box.Text
                box.Text = text
                if changed and not silent then
                    fire(false)
                end
            end,
            Get = function()
                return box.Text
            end,
            OnChanged = function(_, callback)
                return signal:Connect(callback)
            end,
            Destroy = function()
                janitor:Destroy()
            end,
        }
        return registerFlag(options, api, "Textbox")
    end

    function Tab:AddDivider()
        local holder = create("Frame", self._page, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 11),
            ZIndex = 20,
        })
        local janitor = makeControlJanitor(self, holder)
        create("Frame", holder, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Nia.Theme.Border,
            BackgroundTransparency = 0.32,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 21,
        })
        return {
            Instance = holder,
            Destroy = function()
                janitor:Destroy()
            end,
        }
    end

    Tab.AddLine = Tab.AddDivider

    function Nia:GetConfig()
        local config = {}
        for flag, api in pairs(self.Flags) do
            if type(api.Get) == "function" then
                local ok, value = pcall(api.Get, api)
                if ok then
                    config[flag] = cloneValue(value)
                end
            end
        end
        return config
    end

    function Nia:SetConfig(config, silent)
        if type(config) ~= "table" then
            return false, "config must be a table"
        end
        local firstError
        for flag, value in pairs(config) do
            local api = self.Flags[flag]
            if api and type(api.Set) == "function" then
                local ok, err = pcall(api.Set, api, cloneValue(value), silent ~= false)
                if not ok and not firstError then
                    firstError = tostring(err)
                end
            end
        end
        if firstError then
            return false, firstError
        end
        return true
    end

    function Nia:SetUIElementValue(flag, value, silent)
        local api = self.Flags[flag]
        if not api or type(api.Set) ~= "function" then
            return false, "Unknown UI element: " .. tostring(flag)
        end
        local ok, err = pcall(api.Set, api, cloneValue(value), silent ~= false)
        if not ok then
            return false, tostring(err)
        end
        return true
    end

    function Nia:CreateSnapshot(name)
        local snapshot = {
            Data = cloneValue(self:GetConfig()),
            CreatedAt = os.time(),
        }
        self._Snapshot = snapshot
        if name ~= nil then
            self._Snapshots[tostring(name)] = cloneValue(snapshot)
        end
        return cloneValue(snapshot)
    end

    function Nia:RestoreSnapshot(snapshotOrName, silent)
        local snapshot = snapshotOrName
        if type(snapshotOrName) == "string" then
            snapshot = self._Snapshots[snapshotOrName]
        elseif snapshotOrName == nil then
            snapshot = self._Snapshot
        end
        if type(snapshot) ~= "table" or type(snapshot.Data) ~= "table" then
            return false, "invalid snapshot"
        end
        return self:SetConfig(cloneValue(snapshot.Data), silent)
    end

    Nia.SaveSnapshot = Nia.CreateSnapshot
    Nia.LoadSnapshot = Nia.RestoreSnapshot

    local toastHolder = create("Frame", root, {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 320, 1, -28),
        ZIndex = 500,
    })
    create("UIListLayout", toastHolder, {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })

    local notifyColors = {
        info = Nia.Theme.Accent,
        success = Nia.Theme.Success,
        warning = Nia.Theme.Warning,
        error = Nia.Theme.Error,
    }

    local notifySymbols = {
        info = "i",
        success = "+",
        warning = "!",
        error = "x",
    }

    local function removeToast(record)
        local index = table.find(Nia._Toasts, record)
        if index then
            table.remove(Nia._Toasts, index)
        end
    end

    function Nia:Notify(options)
        if self._unloaded then
            return nil
        end
        options = options or {}
        local title = tostring(options.Title or "Notification")
        local text = tostring(options.Text or "")
        local kind = string.lower(tostring(options.Type or "info"))
        local duration = math.clamp(tonumber(options.Duration) or 4, 0.75, 30)
        local key = kind .. "\0" .. title .. "\0" .. text
        local now = os.clock()

        self._notifyTimes = self._notifyTimes or {}
        local previousTime = self._notifyTimes[key]
        if previousTime and now - previousTime < 0.35 then
            for index = #self._Toasts, 1, -1 do
                local record = self._Toasts[index]
                if record.Key == key and not record.Dead then
                    return record.API
                end
            end
        end
        self._notifyTimes[key] = now

        local maximum = 5
        while #self._Toasts >= maximum do
            self._Toasts[1].Dismiss()
        end

        local color = options.Color or notifyColors[kind] or Nia.Theme.Accent
        local cardWidth = math.min(320, math.max(220, viewportSize().X - 28))
        local textHeight = 0
        if text ~= "" then
            local ok, bounds = pcall(function()
                return TextService:GetTextSize(
                    text,
                    11,
                    Nia.Theme.FontRegular,
                    Vector2.new(cardWidth - 58, 1000)
                )
            end)
            textHeight = ok and bounds.Y or 15
        end
        local cardHeight = text == "" and 52 or math.max(66, 45 + textHeight)

        toastHolder.Size = UDim2.new(0, cardWidth, 1, -28)
        local card = create("Frame", toastHolder, {
            BackgroundColor3 = Nia.Theme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = math.floor(now * 1000),
            Size = UDim2.new(1, 0, 0, cardHeight),
            ZIndex = 501,
        })
        addCorner(card, 10)
        local cardStroke = addStroke(card, Nia.Theme.Border, 1)
        local cardScale = create("UIScale", card, {
            Scale = 0.94,
        })
        local symbol = create("TextLabel", card, {
            BackgroundColor3 = color,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.fromOffset(27, 27),
            Text = notifySymbols[kind] or "i",
            TextColor3 = color,
            TextSize = 14,
            ZIndex = 503,
        })
        addCorner(symbol, 8)
        create("TextLabel", card, {
            BackgroundTransparency = 1,
            Font = Nia.Theme.Font,
            Position = UDim2.fromOffset(50, text == "" and 0 or 10),
            Size = UDim2.new(1, -62, 0, text == "" and cardHeight or 18),
            Text = title,
            TextColor3 = Nia.Theme.Text,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 503,
        })
        if text ~= "" then
            create("TextLabel", card, {
                BackgroundTransparency = 1,
                Font = Nia.Theme.FontRegular,
                Position = UDim2.fromOffset(50, 31),
                Size = UDim2.new(1, -62, 0, textHeight + 3),
                Text = text,
                TextColor3 = Nia.Theme.TextDim,
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 503,
            })
        end
        local progress = create("Frame", card, {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 3),
            ZIndex = 504,
        })

        local record = {
            Card = card,
            Dead = false,
            Key = key,
        }

        local function dismiss()
            if record.Dead then
                return
            end
            record.Dead = true
            removeToast(record)
            tween(cardScale, { Scale = 0.94 }, 0.14)
            tween(card, { BackgroundTransparency = 1 }, 0.14)
            tween(cardStroke, { Transparency = 1 }, 0.14)
            task.delay(0.16, function()
                if card then
                    card:Destroy()
                end
            end)
        end

        record.Dismiss = dismiss
        record.API = {
            Instance = card,
            Dismiss = dismiss,
            Destroy = dismiss,
        }
        table.insert(self._Toasts, record)

        tween(card, { BackgroundTransparency = 0.06 }, 0.18)
        tween(cardStroke, { Transparency = 0.12 }, 0.18)
        tween(cardScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
        tween(progress, {
            Size = UDim2.new(0, 0, 0, 3),
        }, duration, Enum.EasingStyle.Linear)
        task.delay(duration, dismiss)
        return record.API
    end

    local cameraConnection

    local function refreshViewport()
        local viewport = viewportSize()
        toastHolder.Size = UDim2.new(0, math.min(320, math.max(220, viewport.X - 28)), 1, -28)
        for _, window in ipairs(Nia._Windows) do
            window:_Clamp()
            window:_Layout()
        end
        closeActivePopup()
    end

    local function watchCamera()
        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end
        local camera = workspace.CurrentCamera
        if camera then
            cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshViewport)
        end
    end

    libraryJanitor:Add(function()
        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end
    end)
    connect(libraryJanitor, workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        watchCamera()
        refreshViewport()
    end)
    watchCamera()

    connect(libraryJanitor, UserInputService.InputBegan, function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape and activePopupClose then
            closeActivePopup()
            return
        end
        if gameProcessed or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        local windows = table.clone(Nia._Windows)
        for _, window in ipairs(windows) do
            if window._toggleKey and input.KeyCode == window._toggleKey then
                window:Toggle()
            end
        end
    end)

    function Nia:Unload()
        if self._unloaded then
            return
        end
        self._unloaded = true
        closeActivePopup()

        local windows = table.clone(self._Windows)
        for _, window in ipairs(windows) do
            window:Destroy()
        end

        for _, toast in ipairs(table.clone(self._Toasts)) do
            toast.Dead = true
            if toast.Card then
                toast.Card:Destroy()
            end
        end
        table.clear(self._Toasts)
        table.clear(self.Flags)
        table.clear(self._Windows)
        table.clear(self._Snapshots)
        self._Snapshot = nil

        libraryJanitor:Destroy()
        self._Root = nil

        if environment[singletonKey] == self then
            environment[singletonKey] = nil
        end
    end

    environment[singletonKey] = Nia
    return Nia
end
