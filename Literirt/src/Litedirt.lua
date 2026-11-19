--[[
    LITEDIRT UI Library
    Roblox Luau ModuleScript
    Place this ModuleScript in ReplicatedStorage as "LITEDIRT".
    Use from a LocalScript: local Litedirt = require(game.ReplicatedStorage.LITEDIRT)

    This library is intended for UI in your own Roblox experiences.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Litedirt = {}
Litedirt.__index = Litedirt

Litedirt.Version = "1.0.0"

local DEFAULT_THEME = {
    Background = Color3.fromRGB(17, 19, 25),
    Surface = Color3.fromRGB(24, 27, 35),
    SurfaceHover = Color3.fromRGB(34, 39, 50),
    Stroke = Color3.fromRGB(52, 59, 74),
    Text = Color3.fromRGB(239, 242, 248),
    Muted = Color3.fromRGB(145, 153, 170),
    Accent = Color3.fromRGB(91, 141, 239),
    AccentDark = Color3.fromRGB(62, 105, 196),
    Success = Color3.fromRGB(80, 190, 130),
    Danger = Color3.fromRGB(225, 92, 105),
}

local function create(className, properties, children)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = object
    end
    return object
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, color, transparency)
    create("UIStroke", {
        Color = color or DEFAULT_THEME.Stroke,
        Transparency = transparency or 0,
        Thickness = 1,
        Parent = parent,
    })
end

local function padding(parent, left, right, top, bottom)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 10),
        PaddingRight = UDim.new(0, right or 10),
        PaddingTop = UDim.new(0, top or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        Parent = parent,
    })
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or DEFAULT_THEME.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None,
        Parent = parent,
    })
end

local function makeButton(parent, text, theme, height)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, height or 36),
        Text = text or "",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        Parent = parent,
    })
    corner(button, 8)
    stroke(button, theme.Stroke)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = theme.SurfaceHover
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = theme.Surface
        }):Play()
    end)
    return button
end

local function safeCallback(callback, ...)
    if typeof(callback) == "function" then
        local ok, err = pcall(callback, ...)
        if not ok then
            warn("[LITEDIRT] Callback error:", err)
        end
    end
end

function Litedirt:CreateWindow(options)
    options = options or {}
    local theme = table.clone(DEFAULT_THEME)
    if typeof(options.Theme) == "table" then
        for key, value in pairs(options.Theme) do
            if theme[key] ~= nil then
                theme[key] = value
            end
        end
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = create("ScreenGui", {
        Name = options.GuiName or "LITEDIRT_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    })

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = options.Size or UDim2.fromOffset(570, 390),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    corner(main, 12)
    stroke(main, theme.Stroke)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
    })
    corner(topbar, 12)
    local topbarCover = create("Frame", {
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = topbar,
    })

    local title = label(topbar, options.Name or "LITEDIRT", 16, theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(18, 7)
    title.Size = UDim2.new(1, -100, 0, 22)

    local subtitle = label(topbar, options.Subtitle or "UI Library", 11, theme.Muted)
    subtitle.Position = UDim2.fromOffset(19, 29)
    subtitle.Size = UDim2.new(1, -100, 0, 15)

    local close = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = theme.Background,
        Text = "×",
        TextColor3 = theme.Muted,
        TextSize = 20,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
        Parent = topbar,
    })
    corner(close, 8)
    close.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Dragging is implemented with input events instead of the deprecated Draggable property.
    local dragging = false
    local dragStart, startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(12, 66),
        Size = UDim2.new(0, 142, 1, -78),
        BackgroundTransparency = 1,
        Parent = main,
    })
    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar,
    })

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(166, 66),
        Size = UDim2.new(1, -178, 1, -78),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
    })
    corner(content, 9)
    stroke(content, theme.Stroke)
    local pages = create("Folder", { Name = "Pages", Parent = content })

    local window = {
        ScreenGui = screenGui,
        Main = main,
        Theme = theme,
        _sidebar = sidebar,
        _pages = pages,
        _tabButtons = {},
        _activeTab = nil,
    }

    function window:CreateTab(tabName)
        local page = create("ScrollingFrame", {
            Name = tostring(tabName),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = pages,
        })
        padding(page, 12, 12, 12, 12)
        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })

        local tabButton = create("TextButton", {
            Name = tostring(tabName) .. "Tab",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Surface,
            Text = tostring(tabName),
            TextColor3 = theme.Muted,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            Parent = sidebar,
        })
        corner(tabButton, 8)

        local function selectTab()
            for _, child in ipairs(pages:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = (child == page)
                end
            end
            for _, button in ipairs(window._tabButtons) do
                button.BackgroundColor3 = theme.Surface
                button.TextColor3 = theme.Muted
            end
            tabButton.BackgroundColor3 = theme.AccentDark
            tabButton.TextColor3 = Color3.new(1, 1, 1)
            window._activeTab = page
        end
        table.insert(window._tabButtons, tabButton)
        tabButton.MouseButton1Click:Connect(selectTab)
        if #window._tabButtons == 1 then
            selectTab()
        end

        local tab = { Page = page }

        local function createRow(height)
            local row = create("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                Parent = page,
            })
            corner(row, 8)
            stroke(row, theme.Stroke)
            return row
        end

        function tab:CreateSection(text)
            local section = label(page, string.upper(text or "SECTION"), 10, theme.Accent, Enum.Font.GothamBold)
            section.Size = UDim2.new(1, 0, 0, 18)
            section.LayoutOrder = 0
            return section
        end

        function tab:CreateLabel(options)
            options = options or {}
            local row = createRow(34)
            local textLabel = label(row, options.Name or "Label", 12, theme.Muted)
            textLabel.Position = UDim2.fromOffset(11, 0)
            textLabel.Size = UDim2.new(1, -22, 1, 0)
            return textLabel
        end

        function tab:CreateButton(options)
            options = options or {}
            local button = makeButton(page, options.Name or "Button", theme, options.Height or 38)
            button.MouseButton1Click:Connect(function()
                safeCallback(options.Callback)
            end)
            return button
        end

        function tab:CreateToggle(options)
            options = options or {}
            local state = options.Default == true
            local row = createRow(40)
            local textLabel = label(row, options.Name or "Toggle", 12, theme.Text)
            textLabel.Position = UDim2.fromOffset(11, 0)
            textLabel.Size = UDim2.new(1, -75, 1, 0)

            local switch = create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(42, 22),
                BackgroundColor3 = state and theme.Accent or theme.Stroke,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })
            corner(switch, 11)
            local knob = create("Frame", {
                Position = state and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Parent = switch,
            })
            corner(knob, 7)

            local function set(value)
                state = value == true
                TweenService:Create(switch, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and theme.Accent or theme.Stroke
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.15), {
                    Position = state and UDim2.new(1, -19, 0.5, -7) or UDim2.new(0, 5, 0.5, -7)
                }):Play()
                safeCallback(options.Callback, state)
            end
            switch.MouseButton1Click:Connect(function() set(not state) end)
            return { Set = set, Get = function() return state end }
        end

        function tab:CreateSlider(options)
            options = options or {}
            local minimum = tonumber(options.Min) or 0
            local maximum = tonumber(options.Max) or 100
            if maximum <= minimum then maximum = minimum + 1 end
            local value = math.clamp(tonumber(options.Default) or minimum, minimum, maximum)
            local row = createRow(56)
            local titleLabel = label(row, options.Name or "Slider", 12, theme.Text)
            titleLabel.Position = UDim2.fromOffset(11, 5)
            titleLabel.Size = UDim2.new(1, -80, 0, 20)
            local valueLabel = label(row, tostring(value), 11, theme.Muted)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Position = UDim2.new(1, -65, 0, 5)
            valueLabel.Size = UDim2.fromOffset(52, 20)

            local track = create("Frame", {
                Position = UDim2.new(0, 11, 0, 34),
                Size = UDim2.new(1, -22, 0, 6),
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(track, 4)
            local fill = create("Frame", {
                Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = track,
            })
            corner(fill, 4)

            local function setValue(newValue)
                value = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
                local ratio = (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
                safeCallback(options.Callback, value)
            end
            local sliding = false
            local function update(input)
                local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(minimum + (maximum - minimum) * ratio)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    update(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            return { Set = setValue, Get = function() return value end }
        end

        function tab:CreateTextbox(options)
            options = options or {}
            local row = createRow(42)
            local textLabel = label(row, options.Name or "Textbox", 12, theme.Text)
            textLabel.Position = UDim2.fromOffset(11, 0)
            textLabel.Size = UDim2.new(0.42, -8, 1, 0)
            local input = create("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -9, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 27),
                BackgroundColor3 = theme.Surface,
                Text = options.Default or "",
                PlaceholderText = options.Placeholder or "Type here...",
                PlaceholderColor3 = theme.Muted,
                TextColor3 = theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                Parent = row,
            })
            corner(input, 6)
            stroke(input, theme.Stroke)
            input.FocusLost:Connect(function(enterPressed)
                safeCallback(options.Callback, input.Text, enterPressed)
            end)
            return input
        end

        function tab:CreateDropdown(options)
            options = options or {}
            local items = options.Options or {}
            local selected = options.Default
            local row = createRow(40)
            local textLabel = label(row, options.Name or "Dropdown", 12, theme.Text)
            textLabel.Position = UDim2.fromOffset(11, 0)
            textLabel.Size = UDim2.new(0.42, -8, 1, 0)

            local dropdown = create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -9, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 27),
                BackgroundColor3 = theme.Surface,
                Text = tostring(selected or "Select...") .. "  ▾",
                TextColor3 = theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                Parent = row,
            })
            corner(dropdown, 6)
            stroke(dropdown, theme.Stroke)

            local list = create("Frame", {
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 5,
                Parent = dropdown,
            })
            corner(list, 6)
            stroke(list, theme.Stroke)
            local listLayout = create("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = list,
            })
            local function choose(item)
                selected = item
                dropdown.Text = tostring(item) .. "  ▾"
                list.Visible = false
                list.Size = UDim2.new(1, 0, 0, 0)
                safeCallback(options.Callback, item)
            end
            for index, item in ipairs(items) do
                local optionButton = create("TextButton", {
                    LayoutOrder = index,
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    Text = tostring(item),
                    TextColor3 = theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    ZIndex = 6,
                    Parent = list,
                })
                optionButton.MouseButton1Click:Connect(function() choose(item) end)
            end
            dropdown.MouseButton1Click:Connect(function()
                list.Visible = not list.Visible
                list.Size = list.Visible and UDim2.new(1, 0, 0, math.min(#items * 28 + 4, 140))
                    or UDim2.new(1, 0, 0, 0)
            end)
            return {
                Set = choose,
                Get = function() return selected end,
                Refresh = function(newItems)
                    items = newItems or {}
                    for _, child in ipairs(list:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for index, item in ipairs(items) do
                        local optionButton = create("TextButton", {
                            LayoutOrder = index,
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundTransparency = 1,
                            Text = tostring(item),
                            TextColor3 = theme.Text,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                            ZIndex = 6,
                            Parent = list,
                        })
                        optionButton.MouseButton1Click:Connect(function() choose(item) end)
                    end
                end,
            }
        end

        return tab
    end

    function window:Notify(options)
        options = options or {}
        local toast = create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(260, 72),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            Parent = screenGui,
            ZIndex = 20,
        })
        corner(toast, 9)
        stroke(toast, theme.Accent)
        local heading = label(toast, options.Title or "LITEDIRT", 13, theme.Text, Enum.Font.GothamBold)
        heading.Position = UDim2.fromOffset(12, 8)
        heading.Size = UDim2.new(1, -24, 0, 20)
        local body = label(toast, options.Content or "Notification", 11, theme.Muted)
        body.Position = UDim2.fromOffset(12, 30)
        body.Size = UDim2.new(1, -24, 0, 30)
        body.TextWrapped = true
        toast.Position = UDim2.new(1, 280, 1, -18)
        TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -18, 1, -18)
        }):Play()
        task.delay(tonumber(options.Duration) or 3, function()
            if toast.Parent then
                local tween = TweenService:Create(toast, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, 280, 1, -18),
                    BackgroundTransparency = 1,
                })
                tween:Play()
                tween.Completed:Wait()
                toast:Destroy()
            end
        end)
    end

    function window:Destroy()
        screenGui:Destroy()
    end

    return window
end

return setmetatable(Litedirt, Litedirt)
