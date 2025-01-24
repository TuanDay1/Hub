----- Services -----
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local _env = getgenv and getgenv() or {}
local _httpget = httpget or game.HttpGet or (function()end)
local function HttpGet(...)
	return _httpget(game, ...)
end

----- Variables -----
local player = Players.LocalPlayer
local placeId = game.PlaceId

local CoreGui = (game:GetService("RunService"):IsStudio() and player.PlayerGui) or (gethui() or game:GetService("CoreGui"):Clone())

local UILib = {
    Mouse = player:GetMouse(),
	Keybinds = {},
	GuiObjects = {},
	Connections = {}
}

local FileManager = loadstring(HttpGet("https://raw.githubusercontent.com/TuanDay1/Hub/refs/heads/main/Library/FileManager.lua"))()

local HubLogo = "rbxassetid://18616130668"
local HubName = "Ngu Thi Chet"

----- ScreenGui -----
local existScreen = CoreGui:FindFirstChild(HubName.." Hub")
if existScreen then
    existScreen:Destroy()
end

local HubScreen = Instance.new("ScreenGui")
HubScreen.Name = HubName.." Hub"
HubScreen.Parent = CoreGui
HubScreen.DisplayOrder = math.random(10000,99999)
HubScreen.IgnoreGuiInset = true
HubScreen.ResetOnSpawn = false

----- Connections -----
local EscMenuOpen = GuiService.MenuIsOpen
GuiService.MenuOpened:Connect(function()
	EscMenuOpen = true
end)

GuiService.MenuClosed:Connect(function()
	EscMenuOpen = false
end)

table.insert(UILib.Connections,
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
        if not gameProcessedEvent or EscMenuOpen then
            local bind = UILib.Keybinds[input.KeyCode]
            if bind then
                bind()
            end
        end
    end)
)

table.insert(UILib.Connections,
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
)

----- Library -----
function UILib:IsRunning()
    return HubScreen.Parent == CoreGui
end

task.spawn(function()
	while (UILib:IsRunning()) do
		task.wait()
	end

	for _, connection in next, UILib.Connections do
		connection:Disconnect()
	end
end)

function UILib:RegisterKeybind(key, callback)
	self.Keybinds[key] = callback
end

function UILib:RemoveKeybind(key)
	self.Keybinds[key] = nil
end

local function AddConnection(Signal, Function)
	if not UILib:IsRunning() then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(UILib.Connections, SignalConnect)
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

function UILib.Create(className, Properties)
	local new = Instance.new(className)
	if Properties then
		for i,v in pairs(Properties) do
			if i ~= "Parent" then
				if typeof(v) == "Instance" then
					v.Parent = new
				else
					new[i] = v
				end
			end
		end
		
		new.Parent = Properties.Parent
	end
	return new
end

local uiBase = {}
uiBase.__index = uiBase

----- Main -----
function UILib:Destroy()
	HubScreen:Destroy()
end

local loaded = false

local NotificationGui
local TabContainer
local SectionContainer

function UILib.CreateWindow(gameName: string, saveFolder: string)
    local new = setmetatable({}, uiBase)

    ----- Config -----
    local fileName = string.format("%s//%s_%s.json", saveFolder, player.Name, placeId)
    if _env.Config == nil then
        local readFile = FileManager:ReadFile(fileName, "table")
        if readFile then
            _env.Config = readFile
        else
            _env.Config = {}
        end
    end

    -- local hubConfig = _env.Config
    -- local configFile = HttpGet("https://phanphu.site/NTC/config.json")

    -- local configSuccess, configValue = pcall(function()
    --     return HttpService:JSONDecode(configFile)
    -- end)
    
    -- if configSuccess and configValue then
    --     configValue = configValue[tostring(placeId)]
    --     if configValue then
    --         for i, v in pairs(configValue) do
    --             if hubConfig[i] then
    --                 continue
    --             else
    --                 hubConfig[i] = v
    --             end
    --         end
    --     end
    -- end
    
    -- FileManager:GetFolder(saveFolder)
    -- FileManager:GetFile(fileName, hubConfig)

    ----------------------------------------------------------
    _env.FileName = fileName

    ----- Notification -----
    new.NotificationGui = UILib.Create("Frame", {
        Size = UDim2.new(0,250,1,-10),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1,-5,1,-5),
        BackgroundTransparency = 1,
        Parent = HubScreen,

        UILib.Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        })
    })

    NotificationGui = new.NotificationGui

    task.spawn(function()
        uiBase:SendNotification("Đang tải giao diện chính, nếu bạn bị mắc kẹt ở đây hãy báo lỗi cho chúng tôi!", function()
            repeat
                task.wait()
            until loaded == true
        end)
    end)
    ----- end Notification -----

    ----- Main -----
    new.Gui = UILib.Create("Frame", {
        Size = UDim2.new(0,550,0,300),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        Visible = false,
        Parent = HubScreen,

        UILib.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),

        UILib.Create("Frame", {
            Name = "Top",
            Size = UDim2.new(1,0,0,30),
            Position = UDim2.new(0,0,0,0),
            BackgroundTransparency = 1,
            
            UILib.Create("Frame", {
                Size = UDim2.new(1,-10,0,2),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5,0,1,-4),
                BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                
                UILib.Create("UIGradient", {
                    Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
                    Rotation = 0,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,1),
                        NumberSequenceKeypoint.new(0.5,0),
                        NumberSequenceKeypoint.new(1,1),
                    })
                }),
            }),

            UILib.Create("TextLabel", {
                Size = UDim2.new(0,80,0,20),
                Position = UDim2.new(0.5,0,0.45,0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                RichText = true,
                Text = string.format('%s <font color="#ffffff">[%s]</font>', HubName, gameName),
                TextColor3 = Color3.fromRGB(255, 205, 135),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
            }),

            UILib.Create("ImageButton", {
                Size = UDim2.new(0,22,0,22),
                Position = UDim2.new(1,0,0.45,0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = HubLogo,
            })
        }),

        UILib.Create("Frame", {
            Name = "Main",
            Size = UDim2.new(1,0,1,-30),
            Position = UDim2.new(0,0,0,30),
            BackgroundTransparency = 1,

            -- LOGO
            UILib.Create("ImageLabel", {
                Size = UDim2.new(0,120,0,120),
                Position = UDim2.new(0.5,0,0.5,0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = HubLogo,
                ImageColor3 = Color3.fromRGB(0,0,0),
                ImageTransparency = 0.95,
            }),

            -- TAB
            UILib.Create("Frame", {
                Name = "TabFrame",
                Size = UDim2.new(1,-10,0,31),
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5,0,0,0),
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                ZIndex = 2,
    
                UILib.Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),

                UILib.Create("ScrollingFrame", {
                    Name = "Container",
                    Size = UDim2.new(1,-10,1,-10),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5,0,0.5,0),
                    BackgroundTransparency = 1,
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(0,0,0,0),

                    UILib.Create("UIListLayout", {
                        Padding = UDim.new(0, 5),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                })
            }),

            -- SECTION
            UILib.Create("Frame", {
                Name = "SectionContainer",
                Size = UDim2.new(1,-10,0.96,-30),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5,0,1,-5),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                ZIndex = 2,
    
                UILib.Create("UIPageLayout", {
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

    new.Button = UILib.Create("ImageButton", {
        Size = UDim2.new(0,50,0,50),
        Position = UDim2.new(0.041,0,0.77,0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        Image = "",
        Parent = HubScreen,

        UILib.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),

        UILib.Create("ImageLabel", {
            Size = UDim2.new(0,22,0,22),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            BackgroundTransparency = 1,
            Image = HubLogo,
        }),
    })

    TabContainer = new.Gui.Main.TabFrame.Container
    SectionContainer = new.Gui.Main.SectionContainer

    ----- end Main -----
    uiBase.Tabs = {}

    MakeDraggable(new.Gui.Top, new.Gui)

    UILib:RegisterKeybind(Enum.KeyCode.RightShift, function()
        new.Gui.Visible = not new.Gui.Visible
    end)

    AddConnection(new.Gui.Top.ImageButton.MouseButton1Down, function()
        new.Gui.Visible = not new.Gui.Visible
    end)

    MakeDraggable(new.Button, new.Button)

    AddConnection(new.Button.MouseButton1Click, function()
        new.Gui.Visible = not new.Gui.Visible
    end)

    table.insert(UILib.GuiObjects, new)

    loaded = true

    task.spawn(function()
        uiBase:SendNotification("Giao diện sẽ tự động ẩn, bạn có thể bật nó bằng cách nhấn vào biểu tượng trên màn hình.", function()
            repeat
                task.wait()
            until new.Gui.Visible == true
        end)
    end)
    return new
end

local lastTab = nil
function uiBase:Select(tabTitle: string, first: boolean)
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
        lastTab = tabTitle
    else
        if lastTab ~= nil and lastTab ~= tabTitle then
            local tabButton = TabContainer:FindFirstChild(lastTab)
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
        lastTab = tabTitle
    end
end

function uiBase:Tab(tabTitle: string)
    local new = {}

    local tabButton = UILib.Create("TextButton", {
        Name = tabTitle,
        Size = UDim2.new(0.194,0,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        Text = "",
        ZIndex = 3,
        Parent = TabContainer,

        UILib.Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),

        UILib.Create("TextLabel", {
            Size = UDim2.new(1,0,0.6,0),
            Position = UDim2.new(0,0,0.5,0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = tabTitle,
            TextColor3 = Color3.fromRGB(88, 88, 88),
            TextScaled = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 4,
        })
    })

    table.insert(self.Tabs, tabButton)

    AddConnection(tabButton.MouseButton1Down, function()
        self:Select(tabTitle)
    end)

    if #self.Tabs == 1 then
        self:Select(tabTitle, true)
    end

    local itemContainer = UILib.Create("ScrollingFrame", {
        Name = tabTitle,
        Size = UDim2.new(1,0,1,-2),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        Parent = SectionContainer,

        UILib.Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Vertical
        })
    })

    -- itemContainer Resize
    local function itemContainerResize()
        if itemContainer:FindFirstChild("UIListLayout") then
            local UIListLayout = itemContainer.UIListLayout
            
            itemContainer.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y) 
        end
    end

    AddConnection(itemContainer.ChildAdded, function(child: Instance)
        if child:IsA("Frame") then
            itemContainerResize()
        end
    end)

    AddConnection(itemContainer.ChildRemoved, function(child: Instance)
        if child:IsA("Frame") then
            itemContainerResize()
        end
    end)

    itemContainerResize()

    function new:Section(sectionTitle: string)
        local section = {
            itemCount = 0,
        }
        local sectionFrame = UILib.Create("Frame", {
            Size = UDim2.new(1,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0,0,0,0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Parent = itemContainer,

            UILib.Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),

            UILib.Create("UIListLayout", {
                Padding = UDim.new(0, 0),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            }),

            UILib.Create("Frame", {
                Name = "Container",
                Size = UDim2.new(1,-10,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),

                UILib.Create("Frame", {
                    Name = "Title",
                    Size = UDim2.new(1,0,0,35),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                    }),
        
                    UILib.Create("Frame", {
                        Name = "Container",
                        Size = UDim2.new(1,0,0,24),
                        AnchorPoint = Vector2.new(0,1),
                        Position = UDim2.new(0,0,1,-6),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextLabel", {
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

                        UILib.Create("ImageLabel", {
                            Name = "Icon",
                            Size = UDim2.new(0,15,0,15),
                            Position = UDim2.new(1,-10,0.5,0),
                            AnchorPoint = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://18630017208",
                            ImageColor3 = Color3.fromRGB(0,0,0),
                            Rotation = 180,
                        }),

                        UILib.Create("TextButton", {
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
            itemContainerResize()
        end)

        ------------------------------------------------------------------------------

        function section:Dropdown(dropDownTitle: string, defaultText: string, dropDownItems: table, callback)
            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    UILib.Create("TextLabel", {
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

                    UILib.Create("TextButton", {
                        Name = "Button",
                        Size = UDim2.new(1,-20,0,21),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,30),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                        Text = "",
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextLabel", {
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

                        UILib.Create("ImageLabel", {
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

                    UILib.Create("Frame", {
                        Name = "ItemList",
                        Size = UDim2.new(1,-20,0,0),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,50),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        Visible = false,
                        ZIndex = 3,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("ScrollingFrame", {
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
        
                            UILib.Create("UIListLayout", {
                                Padding = UDim.new(0, 1),
                                FillDirection = Enum.FillDirection.Vertical
                            })
                        })
                    })
                })
            })

            local scrollFrame = item.Container.ItemList.Container

            local function resize()
                if scrollFrame:FindFirstChild("UIListLayout") then
                    local UIListLayout = scrollFrame.UIListLayout
            
                    scrollFrame.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y) 
                end
            end

            AddConnection(scrollFrame.ChildAdded, function(child: Instance)
                if child:IsA("TextButton") then
                    resize()
                end
            end)
        
            AddConnection(scrollFrame.ChildRemoved, function(child: Instance)
                if child:IsA("TextButton") then
                    resize()
                end
            end)

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
                itemContainerResize()
            end)

            for _, buttonName in pairs(dropDownItems) do
                local button = UILib.Create("TextButton", {
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

            itemContainerResize()
        end

        function section:Button(buttonText: string, callback)
            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    -- UILib.Create("TextLabel", {
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

                    UILib.Create("TextButton", {
                        Name = "Button",
                        Size = UDim2.new(1,-20,0,21),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,10),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        Text = "",
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextLabel", {
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

            itemContainerResize()
        end

        function section:Slider(sliderTitle: string, minValue: number, maxValue: number, default: number, callback)
            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    UILib.Create("TextLabel", {
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

                    UILib.Create("Frame", {
                        Name = "ValueFrame",
                        Size = UDim2.new(1,-400,0,25),
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1,-10,0,5),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextBox", {
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

                    UILib.Create("Frame", {
                        Name = "Slider",
                        Size = UDim2.new(1,-20,0,9),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5,0,0,35),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("Frame", {
                            Name = "Bar",
                            Size = UDim2.new(0,0,1,0),
                            Position = UDim2.new(0,0,0,0),
                            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                            ZIndex = 2,

                            UILib.Create("UICorner", {
                                CornerRadius = UDim.new(0, 4),
                            })
                        }),

                        UILib.Create("TextButton", {
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
                    output = math.clamp(((Vector2.new(UILib.Mouse.X, UILib.Mouse.Y) - item.Container.Slider.AbsolutePosition) / item.Container.Slider.AbsoluteSize).X,0,1)
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

            itemContainerResize()
        end

        function section:TextBox(textBoxTitle: string, textBoxButtonText: string, textBoxPlaceholderText: string, callback)
            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    UILib.Create("Frame", {
                        Name = "TextBoxFrame",
                        Size = UDim2.new(1,-120,0,25),
                        Position = UDim2.new(0,8,0,25),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextBox", {
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


                    UILib.Create("TextLabel", {
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

                    UILib.Create("TextButton", {
                        Name = "TextBoxButton",
                        Size = UDim2.new(0.18,0,0,20),
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1,-8,0,27),
                        BackgroundColor3 = Color3.fromRGB(255, 205, 135),
                        Text = "",
                        ZIndex = 2,

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),

                        UILib.Create("TextLabel", {
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

            itemContainerResize()
        end

        function section:CheckBox(checkBoxTitle: string, checkBoxDesc: string, defaultValue: boolean, callback)
            self.itemCount += 1

            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,
                    
                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,12),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    UILib.Create("TextButton", {
                        Name = "CheckBoxButton",
                        Size = UDim2.new(1,0,1,6),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundTransparency = 1,
                        Text = "",
                        ZIndex = 2,
                    }),

                    UILib.Create("ImageLabel", {
                        Name = "CheckBoxFrame",
                        Size = UDim2.new(0,20,0,20),
                        Position = UDim2.new(1,-20,0.5,3),
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://18630060712",
                        ImageColor3 = Color3.fromRGB(255, 205, 135),
                        ZIndex = 2,

                        UILib.Create("ImageLabel", {
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

                    UILib.Create("TextLabel", {
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

                    UILib.Create("TextLabel", {
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

            itemContainerResize()
        end

        function section:Label(text: string, color)
            local color = color or Color3.fromRGB(220, 221, 225)

            local item = UILib.Create("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = self.itemCount,
                Parent = sectionFrame.Container,

                UILib.Create("UIListLayout", {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UILib.Create("Frame", {
                    Name = "Container",
                    Size = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,

                    UILib.Create("Frame", {
                        Size = UDim2.new(1,0,1,10),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,0,0,0),
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),

                        UILib.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                        }),
                    }),

                    UILib.Create("TextLabel", {
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

            itemContainerResize()
        end

        return section
    end

    return new
end

function uiBase:SendNotification(message: string, callback, timeOut: number)
    local item = UILib.Create("Frame", {
        Size = UDim2.new(1,0,0,0),
        Position = UDim2.new(0,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = NotificationGui,

        UILib.Create("Frame", {
            Name = "Container",
            Size = UDim2.new(1,0,1,6),
            Position = UDim2.new(0,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(26, 26, 26),

            UILib.Create("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }),
            UILib.Create("Frame", {
                Name = "Top",
                Size = UDim2.new(1,0,0,25),
                Position = UDim2.new(0,0,0,5),
                BackgroundTransparency = 1,

                UILib.Create("ImageLabel", {
                    Size = UDim2.new(0,22,0,22),
                    Position = UDim2.new(0,5,0.45,0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = HubLogo,
                }),

                UILib.Create("TextLabel", {
                    Size = UDim2.new(1,-40,1,0),
                    Position = UDim2.new(0,32,0.45,0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    RichText = true,
                    Text = "Thông báo",
                    TextColor3 = Color3.fromRGB(255, 205, 135),
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            }),

            UILib.Create("Frame", {
                Name = "Bottom",
                Size = UDim2.new(1,-20,0,0),
                Position = UDim2.new(0,10,0,30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,

                UILib.Create("TextLabel", {
                    Name = "Message",
                    Size = UDim2.new(1,-30,1,0),
                    Position = UDim2.new(0,0,0,0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    RichText = true,
                    FontFace = Font.fromName("Montserrat", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                    Text = message,
                    TextSize = 15,
                    TextWrapped = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),

                UILib.Create("Frame", {
                    Name = "Time",
                    Size = UDim2.new(0,20,0,20),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1,0,0.5,0),
                    BackgroundTransparency = 1,

                    UILib.Create("TextLabel", {
                        Size = UDim2.new(1,0,1,0),
                        Position = UDim2.new(0,0,0,0),
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        Text = "0",
                        TextSize = 14,
                        TextColor3 = Color3.fromRGB(255, 205, 135),
                        TextXAlignment = Enum.TextXAlignment.Center,

                        UILib.Create("Frame", {
                            Size = UDim2.new(1,4,1,4),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0.5,0,0.5,0),
                            BackgroundTransparency = 1,

                            -- Left
                            UILib.Create("Frame", {
                                Name = "L",
                                Size = UDim2.new(0.5,0,1,0),
                                Position = UDim2.new(0,0,0,0),
                                BackgroundTransparency = 1,
                                ClipsDescendants = true,

                                UILib.Create("ImageLabel", {
                                    Name = "Circle",
                                    Size = UDim2.new(2,0,1,0),
                                    Position = UDim2.new(0,0,0,0),
                                    BackgroundTransparency = 1,
                                    Image = "http://www.roblox.com/asset/?id=483229625",
                                    ImageColor3 = Color3.fromRGB(255, 205, 135),
    
                                    UILib.Create("UIGradient", {
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
                            UILib.Create("Frame", {
                                Name = "R",
                                Size = UDim2.new(0.5,0,1,0),
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(1,0,0,0),
                                BackgroundTransparency = 1,
                                ClipsDescendants = true,

                                UILib.Create("ImageLabel", {
                                    Name = "Circle",
                                    Size = UDim2.new(2,0,1,0),
                                    AnchorPoint = Vector2.new(1, 0),
                                    Position = UDim2.new(1,0,0,0),
                                    BackgroundTransparency = 1,
                                    Image = "http://www.roblox.com/asset/?id=483229625",
                                    ImageColor3 = Color3.fromRGB(255, 205, 135),
    
                                    UILib.Create("UIGradient", {
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

    local value = Instance.new("NumberValue", item)
	value.Name = math.random(666, 999)
	value.Value = 100

    local BottomFrame = item.Container.Bottom

    local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		local rotation = math.floor(math.clamp(value.Value * 3.6, 0, 360))

		BottomFrame.Time.TextLabel.Frame.R.Circle.UIGradient.Rotation =
			math.clamp(rotation, 0, 180)
        BottomFrame.Time.TextLabel.Frame.L.Circle.UIGradient.Rotation =
			math.clamp(rotation, 180, 360)
	end)

    if callback ~= nil then
		BottomFrame.Time.Visible = false
		callback()
	else
        local tween = TweenService:Create(
            value,
            TweenInfo.new(timeOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {
                Value = 0
            }
        )
        tween:Play()
        task.spawn(function()
            for i = timeOut, 0, -1 do
                if item == nil then break end
                BottomFrame.Time.TextLabel.Text = tostring(i)
                task.wait(1)
            end
        end)
        tween.Completed:Wait()
	end

    connection:Disconnect()
	item:Destroy()
    item = nil
end

return UILib