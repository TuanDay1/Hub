----- Services -----
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

------------------------------------------------
local _env = getgenv and getgenv() or {}
local _gethui = gethui
local _httpget = httpget or game.HttpGet

local function HttpGet(...)
    return _httpget(game, ...)
end
------------------------------------------------
local FileManager = loadstring(HttpGet("https://raw.githubusercontent.com/TuanDay1/Hub/refs/heads/main/Library/FileManager.lua"))()
------------------------------------------------

----- Variables -----
local Theme = {
    Name = "Ngu Thi Chet",
    Logo = "rbxassetid://18616130668",

    Main = Color3.fromRGB(0,0,0)
}

local Library = {
	Version = "2.0.0",
    Theme = Theme,

	GuiObjects = {},
    Connections = {},
    Keybinds = {},

    Tabs = {},

	MinimizeKey = Enum.KeyCode.RightShift,
}

local LocalPlayer = Players.LocalPlayer
local playerMouse = LocalPlayer:GetMouse()
local gameId = game.GameId

local CoreGui = _gethui() or game:GetService("CoreGui"):Clone()

local currentTab = nil
------------------------------------------------

local existScreen = CoreGui:FindFirstChild(Theme.Name)
if existScreen then
    existScreen:Destroy()
end

------------------------------------------------
local HubScreen = Instance.new("ScreenGui")
HubScreen.Name = Theme.Name
HubScreen.Parent = CoreGui
HubScreen.DisplayOrder = math.random(10000,99999)
HubScreen.IgnoreGuiInset = true
HubScreen.ResetOnSpawn = false

------------------------------------------------ Local Functions
function Library:IsRunning()
    return HubScreen.Parent == CoreGui
end

function Library:Destroy()
	HubScreen:Destroy()
end

function Library:RegisterKeybind(key, callback)
	self.Keybinds[key] = callback
end

function Library:RemoveKeybind(key)
	self.Keybinds[key] = nil
end

task.spawn(function()
	while (Library:IsRunning()) do
		task.wait()
	end
	for _, connection in next, Library.Connections do
		connection:Disconnect()
	end
end)

local function Select(tabTitle: string, first: boolean)
    local TabContainer = Library.GuiObjects.MainFrame.Main.TabFrame.Container
    local SectionContainer = Library.GuiObjects.MainFrame.Main.SectionContainer

    if first == true then
        local tabButton = TabContainer:FindFirstChild(tabTitle)
        if tabButton then
            tabButton.BackgroundColor3 = Color3.fromRGB(255, 205, 135)
            tabButton.TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
        local itemContainer = SectionContainer:FindFirstChild(tabTitle)
        if itemContainer then
            SectionContainer.UIPageLayout:JumpTo(itemContainer)
        end
        currentTab = tabTitle
    else
        if currentTab ~= nil and currentTab ~= tabTitle then
            local tabButton = TabContainer:FindFirstChild(currentTab)
            if tabButton then
                TweenService:Create(tabButton, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                }):Play()
                TweenService:Create(tabButton.TextLabel, TweenInfo.new(0.3), {
                    TextColor3 = Color3.fromRGB(88, 88, 88)
                }):Play()
            end
        end
        local tabButton = TabContainer:FindFirstChild(tabTitle)
        if tabButton then
            TweenService:Create(tabButton, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(255, 205, 135)
            }):Play()
            TweenService:Create(tabButton.TextLabel, TweenInfo.new(0.3), {
                TextColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
        end
        local itemContainer = SectionContainer:FindFirstChild(tabTitle)
        if itemContainer then
            SectionContainer.UIPageLayout:JumpTo(itemContainer)
        end
        currentTab = tabTitle
    end
end

local function AddConnection(Signal, Function)
	if not Library:IsRunning() then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(Library.Connections, SignalConnect)
	return SignalConnect
end

local function MakeDraggable(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos
		AddConnection(DragPoint.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		AddConnection(DragPoint.InputChanged, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				DragInput = Input
			end
		end)
		AddConnection(UserInputService.InputChanged, function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				Main.Position  = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			end
		end)
	end)
end

local function itemContainerResize(itemContainer)
    if itemContainer:FindFirstChild("UIListLayout") then
        local UIListLayout = itemContainer.UIListLayout
        itemContainer.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)
    end
end

local function autoContainerResize(itemContainer)
    AddConnection(itemContainer.ChildAdded, function(child: Instance)
        if child:IsA("Frame") then
            itemContainerResize(itemContainer)
        end
    end)
    AddConnection(itemContainer.ChildRemoved, function(child: Instance)
        if child:IsA("Frame") then
            itemContainerResize(itemContainer)
        end
    end)

    itemContainerResize(itemContainer)
end

local function setupConfig(saveFolder: string)
	local fileName = string.format("%s//%s_%s.json", saveFolder, LocalPlayer.Name, gameId)

	if _env.Config == nil then
		local readFile = FileManager:ReadFile(fileName, "table")
		if readFile then
			_env.Config = readFile
		else
			_env.Config = {}
		end
	end

	FileManager:GetFolder(saveFolder)
    FileManager:GetFile(fileName, _env.Config)
end

------------------------------------------------
local EscMenuOpen = GuiService.MenuIsOpen
AddConnection(GuiService.MenuOpened, function()
    EscMenuOpen = true
end)
AddConnection(GuiService.MenuClosed, function()
    EscMenuOpen = false
end)

AddConnection(UserInputService.InputBegan, function(input: InputObject, gameProcessedEvent: boolean)
    if gameProcessedEvent then return end
    if not EscMenuOpen then return end

    local bind = Library.Keybinds[input.KeyCode]
    if bind then
        bind()
    end
end)

AddConnection(LocalPlayer.Idled, function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)
------------------------------------------------

local function Create(className, Properties)
	local object = Instance.new(className)

	if Properties then
		for index, value in pairs(Properties) do
			if index ~= "Parent" then
				if typeof(value) == "Instance" then
					value.Parent = object
				else
					object[index] = value
				end
			end
		end

		object.Parent = Properties.Parent
	end

	return object
end

----- Main -----
function Library:CreateWindow(gameName: string, saveFolder: string)
	setupConfig(saveFolder)

	-------------------------------------------------------------------------
	Library.GuiObjects.NotificationFrame = Create("Frame", {
        Size = UDim2.new(0,250,1,-10),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1,-5,1,-5),
        BackgroundTransparency = 1,
        Parent = HubScreen,

        Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        })
    })
	-------------------------------------------------------------------------
	
	Library.GuiObjects.MainFrame = Create("Frame", {
        Size = UDim2.new(0,550,0,300),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        Visible = false,
        Parent = HubScreen,

		Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),

        Create("Frame", {
            Name = "Top",
            Size = UDim2.new(1,0,0,30),
            Position = UDim2.new(0,0,0,0),
            BackgroundTransparency = 1,
            
            Create("Frame", {
                Size = UDim2.new(1,-10,0,2),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5,0,1,-4),
                BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                
                Create("UIGradient", {
                    Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
                    Rotation = 0,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,1),
                        NumberSequenceKeypoint.new(0.5,0),
                        NumberSequenceKeypoint.new(1,1),
                    })
                }),
            }),

            Create("TextLabel", {
                Size = UDim2.new(0,80,0,20),
                Position = UDim2.new(0.5,0,0.45,0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                RichText = true,
                Text = string.format('%s <font color="#ffffff">[%s]</font>', Theme.Name, gameName),
                TextColor3 = Color3.fromRGB(255, 205, 135),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
            }),

            Create("ImageButton", {
                Size = UDim2.new(0,22,0,22),
                Position = UDim2.new(1,0,0.45,0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = Theme.Logo,
            })
        }),

        Create("Frame", {
            Name = "Main",
            Size = UDim2.new(1,0,1,-30),
            Position = UDim2.new(0,0,0,30),
            BackgroundTransparency = 1,

            -- LOGO
            Create("ImageLabel", {
                Size = UDim2.new(0,120,0,120),
                Position = UDim2.new(0.5,0,0.5,0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = Theme.Logo,
                ImageColor3 = Color3.fromRGB(0,0,0),
                ImageTransparency = 0.95,
            }),

            -- TAB
            Create("Frame", {
                Name = "TabFrame",
                Size = UDim2.new(1,-10,0,31),
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5,0,0,0),
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                ZIndex = 2,
    
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),

                Create("ScrollingFrame", {
                    Name = "Container",
                    Size = UDim2.new(1,-10,1,-10),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5,0,0.5,0),
                    BackgroundTransparency = 1,
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(0,0,0,0),

                    Create("UIListLayout", {
                        Padding = UDim.new(0, 5),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                })
            }),

            -- SECTION
            Create("Frame", {
                Name = "SectionContainer",
                Size = UDim2.new(1,-10,0.96,-30),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5,0,1,-5),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                ZIndex = 2,
    
                Create("UIPageLayout", {
                    EasingDirection = Enum.EasingDirection.InOut,
                    EasingStyle = Enum.EasingStyle.Quart,
                    Padding = UDim.new(0, 10),
                    TweenTime = 0.25,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    ScrollWheelInputEnabled = false,
                    TouchInputEnabled = false,
                    GamepadInputEnabled = false,
                })
            })
        })
	})

	Library.GuiObjects.MinimizeButton = Create("ImageButton", {
        Size = UDim2.new(0,50,0,50),
        Position = UDim2.new(0.041,0,0.77,0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        Image = "",
        Parent = HubScreen,

        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),

        Create("ImageLabel", {
            Size = UDim2.new(0,22,0,22),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            BackgroundTransparency = 1,
            Image = Theme.Logo,
        }),
    })
    -------------------------------------------------------------------------

    MakeDraggable(Library.GuiObjects.MainFrame.Top, Library.GuiObjects.MainFrame)
    MakeDraggable(Library.GuiObjects.MinimizeButton, Library.GuiObjects.MinimizeButton)

    Library:RegisterKeybind(Library.MinimizeKey, function()
        Library.GuiObjects.MainFrame.Visible = not Library.GuiObjects.MainFrame.Visible
    end)

    AddConnection(Library.GuiObjects.MainFrame.Top.ImageButton.MouseButton1Down, function()
        Library.GuiObjects.MainFrame.Visible = not Library.GuiObjects.MainFrame.Visible
    end)

    AddConnection(Library.GuiObjects.MinimizeButton.MouseButton1Click, function()
        Library.GuiObjects.MainFrame.Visible = not Library.GuiObjects.MainFrame.Visible
    end)

    task.spawn(function()
        Library:Notify(nil, "Giao diện sẽ tự động ẩn, bạn có thể bật nó bằng cách nhấn vào biểu tượng trên màn hình.", function()
            repeat
                task.wait()
            until Library.GuiObjects.MainFrame.Visible == true
        end)
    end)
end

function Library:CreateTab(title: string)
    local tab = {}

    local TabContainer = Library.GuiObjects.MainFrame.Main.TabFrame.Container
    local SectionContainer = Library.GuiObjects.MainFrame.Main.SectionContainer

    local tabButton = Create("TextButton", {
        Name = title,
        Size = UDim2.new(0.194,0,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        Text = "",
        ZIndex = 3,
        Parent = TabContainer,

        Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),

        Create("TextLabel", {
            Size = UDim2.new(1,0,0.6,0),
            Position = UDim2.new(0,0,0.5,0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = title,
            TextColor3 = Color3.fromRGB(88, 88, 88),
            TextScaled = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 4,
        })
    })
    table.insert(self.Tabs, tabButton)

    AddConnection(tabButton.MouseButton1Down, function()
        Select(title)
    end)

    if #self.Tabs == 1 then
        Select(title, true)
    end

    local itemContainer = Create("ScrollingFrame", {
        Name = title,
        Size = UDim2.new(1,0,1,-2),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(45, 45, 45),
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = SectionContainer,

        Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Vertical
        })
    })

    autoContainerResize(itemContainer)
    -------------------------------------------------------------------------

    function tab:CreateSection(sectionTitle: string)
        local section = {
            itemCount = 0,
        }
        local sectionFrame = Create("Frame", {
            Size = UDim2.new(1,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0,0,0,0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Parent = itemContainer,

            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),

            Create("UIListLayout", {
                Padding = UDim.new(0, 0),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            }),

            Create("Frame", {
                Name = "Container",
                Size = UDim2.new(1,-10,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),

                Create("Frame", {
                    Name = "Title",
                    Size = UDim2.new(1,0,0,35),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                    }),
        
                    Create("Frame", {
                        Name = "Container",
                        Size = UDim2.new(1,0,0,24),
                        AnchorPoint = Vector2.new(0,1),
                        Position = UDim2.new(0,0,1,-6),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextLabel", {
                            Size = UDim2.new(1,0,0.5,0),
                            Position = UDim2.new(0,0,0.5,0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundTransparency = 1,
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                            Text = sectionTitle,
                            TextColor3 = Color3.fromRGB(0, 0, 0),
                            TextScaled = true,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Center,
                        }),

                        Create("ImageLabel", {
                            Name = "Icon",
                            Size = UDim2.new(0,15,0,15),
                            Position = UDim2.new(1,-10,0.5,0),
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://18630017208",
                            ImageColor3 = Color3.fromRGB(0,0,0),
                            Rotation = 180,
                        }),

                        Create("TextButton", {
                            Name = "Button",
                            Size = UDim2.new(1,0,1,0),
                            Position = UDim2.new(0,0,0,0),
                            BackgroundTransparency = 1,
                            Text = "",
                        })
                    })
                })
            })
        })

        local header_icon = sectionFrame.Container.Title.Container.Icon
        local header_button = sectionFrame.Container.Title.Container.Button

        local header_tween = false
        AddConnection(header_button.MouseButton1Down, function()
            if header_tween == false then
                if header_icon.Rotation == 0 then
                    header_tween = true
                    local tween = TweenService:Create(header_icon, TweenInfo.new(0.3), {
                        Rotation = 180
                    })
                    tween:Play()
                    tween.Completed:Connect(function()
                        header_tween = false
                    end)
                    ----------------------------------------
                    for _, object in pairs(sectionFrame.Container:GetChildren()) do
                        if object:IsA("Frame") and object.Name ~= "Title" then
                            object.Visible = true
                        end
                    end
                else
                    header_tween = true
                    local tween = TweenService:Create(header_icon, TweenInfo.new(0.3), {
                        Rotation = 0
                    })
                    tween:Play()
                    tween.Completed:Connect(function()
                        header_tween = false
                    end)
                    ----------------------------------------
                    for _, object in pairs(sectionFrame.Container:GetChildren()) do
                        if object:IsA("Frame") and object.Name ~= "Title" then
                            object.Visible = false
                        end
                    end
                end 
            end
            itemContainerResize(itemContainer)
        end)

        ------------------------------------------------------------------------------

        function section:Dropdown(dropDownTitle: string, defaultText: string, dropDownItems: table, callback)
            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    Create("TextLabel", {
                        Size = UDim2.new(1,-70,0,0),
                        Position = UDim2.new(0,8,0,4),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = dropDownTitle,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    }),

                    Create("TextButton", {
                        Name = "Button",
                        Size = UDim2.new(1,-20,0,21),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,30),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                        Text = "",
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextLabel", {
                            Size = UDim2.new(1,-60,0.6,0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            Position = UDim2.new(0,10,0.5,0),
                            BackgroundTransparency = 1,
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                            Text = defaultText,
                            TextColor3 = Color3.fromRGB(0, 0, 0),
                            TextScaled = true,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                        }),

                        Create("ImageLabel", {
                            Size = UDim2.new(0,15,0,15),
                            Position = UDim2.new(1,-10,0.5,0),
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://18630017208",
                            ImageColor3 = Color3.fromRGB(0, 0, 0),
                            Rotation = -90,
                            ZIndex = 3,
                        })
                    }),

                    Create("Frame", {
                        Name = "ItemList",
                        Size = UDim2.new(1,-20,0,0),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,50),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        Visible = false,
                        ZIndex = 3,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("ScrollingFrame", {
                            Name = "Container",
                            Size = UDim2.new(1,-20,1,-20),
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5,0,0,10),
                            BackgroundTransparency = 1,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            ScrollBarThickness = 6,
                            ScrollBarImageColor3 = Color3.fromRGB(45, 45, 45),
                            BottomImage = "",
                            TopImage = "",
                            CanvasSize = UDim2.new(0,0,0,0),
                            ZIndex = 4,
        
                            Create("UIListLayout", {
                                Padding = UDim.new(0, 1),
                                FillDirection = Enum.FillDirection.Vertical
                            })
                        })
                    })
                })
            })

            local scrollFrame = item.Container.ItemList.Container
            autoContainerResize(scrollFrame)

            local imageTween = false
            AddConnection(item.Container.Button.MouseButton1Down, function()
                local imageLabel = item.Container.Button.ImageLabel
                if imageTween == false then
                    if imageLabel.Rotation == -90 then
                        imageTween = true
                        local tween = TweenService:Create(imageLabel, TweenInfo.new(0.3), {
                            Rotation = 0,
                        })
                        tween:Play()
                        tween.Completed:Connect(function()
                            imageTween = false
                        end)
                        ----------------------------------------
                        item.Container.ItemList.Visible = true
                        local tween2 = TweenService:Create(item.Container.ItemList, TweenInfo.new(0.3), {
                            Size = UDim2.new(1,-20,0,100)
                        })
                        tween2:Play()
                        tween2.Completed:Wait()
                    else
                        imageTween = true
                        local tween = TweenService:Create(imageLabel, TweenInfo.new(0.3), {
                            Rotation = -90,
                        })
                        tween:Play()
                        tween.Completed:Connect(function()
                            imageTween = false
                        end)
                        ----------------------------------------
                        local tween2 = TweenService:Create(item.Container.ItemList, TweenInfo.new(0.3), {
                            Size = UDim2.new(1,-20,0,0)
                        })
                        tween2:Play()
                        tween2.Completed:Wait()
                        item.Container.ItemList.Visible = false
                    end 
                end
                itemContainerResize(itemContainer)
            end)

            for _, buttonName in pairs(dropDownItems) do
                local button = Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1,0,0,20),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,
                    RichText = true,
                    FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    Text = buttonName,
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = scrollFrame
                })

                AddConnection(button.MouseButton1Down, function()
                    if callback ~= nil then
                        callback(item.Container.Button.TextLabel, buttonName)
                    end
                end)
            end

            itemContainerResize(itemContainer)
        end

        function section:Button(buttonText: string, callback)
            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    -- Create("TextLabel", {
                    --     Size = UDim2.new(1,-70,0,0),
                    --     Position = UDim2.new(0,8,0,4),
                    --     AutomaticSize = Enum.AutomaticSize.Y,
                    --     BackgroundTransparency = 1,
                    --     FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    --     RichText = true,
                    --     Text = buttonTitle,
                    --     TextColor3 = Color3.fromRGB(255, 255, 255),
                    --     TextSize = 14,
                    --     TextXAlignment = Enum.TextXAlignment.Left,
                    --     ZIndex = 2,
                    -- }),

                    Create("TextButton", {
                        Name = "Button",
                        Size = UDim2.new(1,-20,0,21),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,10),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        Text = "",
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextLabel", {
                            Size = UDim2.new(1,0,0.6,0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            Position = UDim2.new(0,0,0.5,0),
                            BackgroundTransparency = 1,
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            Text = buttonText,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextScaled = true,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 3,
                        })
                    })
                })
            })

            local button = item.Container.Button

            AddConnection(button.MouseButton1Down, function()
                if callback ~= nil then
                    callback()
                end
            end)

            itemContainerResize(itemContainer)
        end

        function section:Slider(sliderTitle: string, minValue: number, maxValue: number, default: number, callback)
            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    Create("TextLabel", {
                        Size = UDim2.new(1,-70,0,0),
                        Position = UDim2.new(0,8,0,4),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = sliderTitle,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    }),

                    Create("Frame", {
                        Name = "ValueFrame",
                        Size = UDim2.new(1,-400,0,25),
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1,-10,0,5),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextBox", {
                            Size = UDim2.new(1,-20,1,0),
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5,0,0,0),
                            BackgroundTransparency = 1,
                            TextColor3 = Color3.fromRGB(255, 205, 135),
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            Text = tostring(default),
                            ZIndex = 3,
                        })
                    }),

                    Create("Frame", {
                        Name = "Slider",
                        Size = UDim2.new(1,-20,0,9),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,35),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("Frame", {
                            Name = "Bar",
                            Size = UDim2.new(0,0,1,0),
                            Position = UDim2.new(0,0,0,0),
                            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                            ZIndex = 2,

                            Create("UICorner", {
                                CornerRadius = UDim.new(0, 4),
                            })
                        }),

                        Create("TextButton", {
                            Name = "Trigger",
                            Size = UDim2.new(1,0,1,0),
                            AnchorPoint = Vector2.new(0, 0),
                            Position = UDim2.new(0,0,0,0),
                            BackgroundTransparency = 1,
                            Text = "",
                            ZIndex = 3,
                        })
                    })
                })
            })

            local triggerButton = item.Container.Slider.Trigger

            local outputValue = 0
            local lastValue

            local function updateSlider(value)
                local output 
                if value ~= nil then
                    output = (value - minValue) / (maxValue - minValue)
                else
                    output = math.clamp(((Vector2.new(playerMouse.X, playerMouse.Y) - item.Container.Slider.AbsolutePosition) / item.Container.Slider.AbsoluteSize).X,0,1)
                end

                local outputClamped = minValue + (output*(maxValue-minValue))

                if outputValue ~= outputClamped then
                    TweenService:Create(item.Container.Slider.Bar, TweenInfo.new(0.35, Enum.EasingStyle.Exponential), {
                        Size = UDim2.fromScale(output, 1)
                    }):Play()
                end

                outputValue = outputClamped
                item.Container.ValueFrame.TextBox.Text = tostring(math.round(outputValue))

                if lastValue ~= math.round(outputValue) then
                    lastValue = math.round(outputValue)

                    if callback ~= nil then
                        callback(math.round(outputValue))
                    end
                end
            end

            updateSlider(default)

            local sliderActive = false

            local function activateSlider()
                sliderActive = true
                TweenService:Create(item.Container.Slider.Bar, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(255, 205, 135)
                }):Play()
                while sliderActive do
                    updateSlider()
                    task.wait()
                end
            end

            AddConnection(triggerButton.MouseButton1Down, activateSlider)

            AddConnection(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliderActive = false
                    TweenService:Create(item.Container.Slider.Bar, TweenInfo.new(0.3), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    }):Play()
                end
            end)

            AddConnection(item.Container.ValueFrame.TextBox:GetPropertyChangedSignal("Text"), function()
                local textBox = item.Container.ValueFrame.TextBox
                if not tonumber(textBox.Text) then
                    textBox.Text = ""
                end
            end)

            AddConnection(item.Container.ValueFrame.TextBox.FocusLost, function()
                local textBox = item.Container.ValueFrame.TextBox
                if tonumber(textBox.Text) > maxValue then
                    textBox.Text = tostring(maxValue)
                    updateSlider(maxValue)
                else
                    updateSlider(tonumber(textBox.Text))
                end
            end)

            itemContainerResize(itemContainer)
        end

        function section:TextBox(textBoxTitle: string, textBoxButtonText: string, textBoxPlaceholderText: string, callback)
            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    Create("Frame", {
                        Name = "TextBoxFrame",
                        Size = UDim2.new(1,-120,0,25),
                        Position = UDim2.new(0,8,0,25),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextBox", {
                            Size = UDim2.new(1,-20,1,0),
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5,0,0,0),
                            BackgroundTransparency = 1,
                            PlaceholderText = textBoxPlaceholderText,
                            PlaceholderColor3 = Color3.fromRGB(255, 205, 135),
                            TextColor3 = Color3.fromRGB(255, 205, 135),
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            TextSize = 13,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Text = "",
                            ZIndex = 3,
                        })
                    }),


                    Create("TextLabel", {
                        Size = UDim2.new(1,-70,0,0),
                        Position = UDim2.new(0,8,0,4),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = textBoxTitle,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    }),

                    Create("TextButton", {
                        Name = "TextBoxButton",
                        Size = UDim2.new(0.18,0,0,20),
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1,-8,0,27),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                        Text = "",
                        ZIndex = 2,

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        Create("TextLabel", {
                            Size = UDim2.new(1,0,0.5,0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            Position = UDim2.new(0,0,0.5,0),
                            BackgroundTransparency = 1,
                            FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            Text = textBoxButtonText,
                            TextColor3 = Color3.fromRGB(0, 0, 0),
                            TextScaled = true,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex = 3,
                        })
                    }),
                })
            })

            local textBoxButton = item.Container.TextBoxButton

            AddConnection(textBoxButton.MouseButton1Down, function()
                if callback ~= nil then
                    callback(item.Container.TextBoxFrame.TextBox.Text)
                end
            end)

            itemContainerResize(itemContainer)
        end

        function section:CheckBox(checkBoxTitle: string, checkBoxDesc: string, defaultValue: boolean, callback)
            self.itemCount += 1

            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,
                    
                    Create("Frame", {
                        Size = UDim2.new(1,0,1,12),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    Create("TextButton", {
                        Name = "CheckBoxButton",
                        Size = UDim2.new(1,0,1,6),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundTransparency = 1,
                        Text = "",
                        ZIndex = 2,
                    }),

                    Create("ImageLabel", {
                        Name = "CheckBoxFrame",
                        Size = UDim2.new(0,20,0,20),
                        Position = UDim2.new(1,-20,0.5,3),
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://18630060712",
                        ImageColor3 = Color3.fromRGB(255, 205, 135),
                        ZIndex = 2,

                        Create("ImageLabel", {
                            Name = "CheckBoxImage",
                            Size = UDim2.new(1,0,1,0),
                            Position = UDim2.new(0.5,0,0.5,0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://18630068210",
                            ImageColor3 = Color3.fromRGB(255, 205, 135),  
                            ImageTransparency = 1,
                        })
                    }),

                    Create("TextLabel", {
                        Size = UDim2.new(1,-70,0,0),
                        Position = UDim2.new(0,8,0,4),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = checkBoxTitle,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    }),

                    Create("TextLabel", {
                        Size = UDim2.new(1,-70,0,0),
                        Position = UDim2.new(0,8,0,20),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = checkBoxDesc,
                        TextColor3 = Color3.fromRGB(202, 202, 202),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    })
                })
            })

            local checkBoxButton = item.Container.CheckBoxButton

            local buttonValue = false
            local function onMouseButon1Down()
                if buttonValue == false then
                    buttonValue = true
                    TweenService:Create(item.Container.CheckBoxFrame.CheckBoxImage, TweenInfo.new(0.3), {
                        ImageTransparency = 0
                    }):Play()
                    if callback ~= nil then
                        callback(buttonValue)
                    end
                else
                    buttonValue = false
                    TweenService:Create(item.Container.CheckBoxFrame.CheckBoxImage, TweenInfo.new(0.3), {
                        ImageTransparency = 1
                    }):Play()
                    if callback ~= nil then
                        callback(buttonValue)
                    end
                end
            end

            AddConnection(checkBoxButton.MouseButton1Down, onMouseButon1Down)

            if defaultValue == true then
                task.spawn(function()
                    onMouseButon1Down()
                end)
            end

            itemContainerResize(itemContainer)
        end

        function section:Label(text: string, color)
            local color = color or Color3.fromRGB(220, 221, 225)

            local item = Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    Create("TextLabel", {
                        Size = UDim2.new(1,-20,0,0),
                        Position = UDim2.new(0,8,0,10),
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        RichText = true,
                        Text = text,
                        TextSize = 14,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                    })
                })
            })

            if type(color) == "boolean" and color then
                task.spawn(function()
                    while task.wait() do
                        local hue = tick() % 5 / 5
                        item.Container.TextLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
                    end
                end)
            else
                item.Container.TextLabel.TextColor3 = color
            end

            itemContainerResize(itemContainer)
        end

        return section
    end

    -------------------------------------------------------------------------
    return tab
end

function Library:Notify(title: string, content: string, callback, timeOut: number)
	local newNotification = Create("Frame", {
        Size = UDim2.new(1,0,0,0),
        Position = UDim2.new(0,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Library.GuiObjects.NotificationFrame,

        Create("Frame", {
            Name = "Container",
            Size = UDim2.new(1,0,1,6),
            Position = UDim2.new(0,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(26, 26, 26),

            Create("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }),
            Create("Frame", {
                Name = "Top",
                Size = UDim2.new(1,0,0,25),
                Position = UDim2.new(0,0,0,5),
                BackgroundTransparency = 1,

                Create("ImageLabel", {
                    Size = UDim2.new(0,22,0,22),
                    Position = UDim2.new(0,5,0.45,0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = Theme.Logo,
                }),

                Create("TextLabel", {
                    Size = UDim2.new(1,-40,1,0),
                    Position = UDim2.new(0,32,0.45,0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    RichText = true,
                    Text = title and string.format("%s - %s", Theme.Name, title) or Theme.Name,
                    TextColor3 = Color3.fromRGB(255, 205, 135),
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            }),

            Create("Frame", {
                Name = "Bottom",
                Size = UDim2.new(1,-20,0,0),
                Position = UDim2.new(0,10,0,30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,

                Create("TextLabel", {
                    Name = "Message",
                    Size = UDim2.new(1,-30,1,0),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    RichText = true,
                    FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                    Text = content,
                    TextSize = 15,
                    TextWrapped = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),

                Create("Frame", {
                    Name = "Time",
                    Size = UDim2.new(0,20,0,20),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1,0,0.5,0),
                    BackgroundTransparency = 1,

                    Create("TextLabel", {
                        Size = UDim2.new(1,0,1,0),
                        Position = UDim2.new(0,0,0,0),
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        Text = "0",
                        TextSize = 14,
                        TextColor3 = Color3.fromRGB(255, 205, 135),
                        TextXAlignment = Enum.TextXAlignment.Center,

                        Create("Frame", {
                            Size = UDim2.new(1,4,1,4),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0.5,0,0.5,0),
                            BackgroundTransparency = 1,

                            -- Left
                            Create("Frame", {
                                Name = "L",
                                Size = UDim2.new(0.5,0,1,0),
                                Position = UDim2.new(0,0,0,0),
                                BackgroundTransparency = 1,
                                ClipsDescendants = true,

                                Create("ImageLabel", {
                                    Name = "Circle",
                                    Size = UDim2.new(2,0,1,0),
                                    Position = UDim2.new(0,0,0,0),
                                    BackgroundTransparency = 1,
                                    Image = "http://www.roblox.com/asset/?id=483229625",
                                    ImageColor3 = Color3.fromRGB(255, 205, 135),
    
                                    Create("UIGradient", {
                                        Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
                                        Rotation = 180,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0,0),
                                            NumberSequenceKeypoint.new(0.499,0),
                                            NumberSequenceKeypoint.new(0.5,1),
                                            NumberSequenceKeypoint.new(1,1),
                                        })
                                    })
                                }),
                            }),

                            -- Right
                            Create("Frame", {
                                Name = "R",
                                Size = UDim2.new(0.5,0,1,0),
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(1,0,0,0),
                                BackgroundTransparency = 1,
                                ClipsDescendants = true,

                                Create("ImageLabel", {
                                    Name = "Circle",
                                    Size = UDim2.new(2,0,1,0),
                                    AnchorPoint = Vector2.new(1, 0),
                                    Position = UDim2.new(1,0,0,0),
                                    BackgroundTransparency = 1,
                                    Image = "http://www.roblox.com/asset/?id=483229625",
                                    ImageColor3 = Color3.fromRGB(255, 205, 135),
    
                                    Create("UIGradient", {
                                        Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
                                        Rotation = 0,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0,0),
                                            NumberSequenceKeypoint.new(0.499,0),
                                            NumberSequenceKeypoint.new(0.5,1),
                                            NumberSequenceKeypoint.new(1,1),
                                        })
                                    })
                                })
                            })
                        })
                    })
                })
            })
        })
    })

	local BottomFrame = newNotification.Container.Bottom

	local NumberValue = Instance.new("NumberValue", newNotification)
	NumberValue.Name = math.random(666, 999)
	NumberValue.Value = 100

	local notifyConnection = AddConnection(NumberValue:GetPropertyChangedSignal("Value"), function()
		local rotation = math.floor(math.clamp(NumberValue.Value * 3.6, 0, 360))

		BottomFrame.Time.TextLabel.Frame.R.Circle.UIGradient.Rotation =
			math.clamp(rotation, 0, 180)
        BottomFrame.Time.TextLabel.Frame.L.Circle.UIGradient.Rotation =
			math.clamp(rotation, 180, 360)
	end)

	if callback ~= nil then
		BottomFrame.Time.Visible = false
		callback()
	else
        local timeOutTween = TweenService:Create(
            NumberValue,
            TweenInfo.new(timeOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {
                Value = 0
            }
        )
        timeOutTween:Play()
        task.spawn(function()
            for i = timeOut, 0, -1 do
                if newNotification == nil then break end
                BottomFrame.Time.TextLabel.Text = tostring(i)
                task.wait(1)
            end
        end)
        timeOutTween.Completed:Wait()
	end

    notifyConnection:Disconnect()
	newNotification:Destroy()
end

------------------------------------------------
return Library
