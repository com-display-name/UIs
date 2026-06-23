local VSCode, Config, Functions = {}, {}, {}
local cloneref = cloneref or function(...) return ... end
local getgenv = getgenv or function(...) return _G end

Config = {
	Pallet = {
		Main = Color3.fromRGB(31, 31, 31),
		AltMain =  Color3.fromRGB(26,26,26),
		AccentColor = Color3.fromRGB(0, 122, 204),
		Text = Color3.fromRGB(220,220,220),
		Divider = Color3.fromRGB(60,60,60),
		BackgroundText = Color3.fromRGB(160,160,160),
		Font = Font.fromEnum(Enum.Font.Arial),
		Tween = TweenInfo.new(0.16,Enum.EasingStyle.Linear),
		TweenSlow = TweenInfo.new(0.45,Enum.EasingStyle.Linear),
		TweenFast = TweenInfo.new(0.06,Enum.EasingStyle.Linear),
	},
	PlaceId = game.PlaceId,
	Tooltip = nil,
	OnTopOfCoreBlur = getthreadidentity and getthreadidentity() == 8 or setthreadidentity and setthreadidentity(8) and true or false,
	GuiHolder = (gethui and gethui()) or cloneref(game:GetService("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer.PlayerGui,
	CurrentLineCount = 0,
}

VSCode  = {
	TextBounds = Instance.new("GetTextBoundsParams")
}



local TweenService      = cloneref(game:GetService("TweenService"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local TextService       = cloneref(game:GetService("TextService"))
local GuiService        = cloneref(game:GetService("GuiService"))
local RunService        = cloneref(game:GetService("RunService"))
local HttpService       = cloneref(game:GetService("HttpService"))
local DateTime          = DateTime

Functions = {
	MakeLineStr = function(self, Length)
		local LineStr = ""
		for i = 1, Length do
			LineStr = LineStr .. i .. "\n"
		end
		return LineStr
	end,
	MakeBlur = function(self)
		local Blur = Instance.new("ImageLabel")
		Blur.Name = "Blur"
		Blur.Size = UDim2.new(1, 89, 1, 52)
		Blur.Position = UDim2.fromOffset(-48, -31)
		Blur.BackgroundTransparency = 1
		Blur.Image = "rbxassetid://14898786664"
		Blur.ScaleType = Enum.ScaleType.Slice
		Blur.SliceCenter = Rect.new(52, 31, 261, 502)
		return Blur
	end,
	GetFontSize = function(self, Text, Size, font, width)
		VSCode.TextBounds.Text = Text
		VSCode.TextBounds.Size = Size
		VSCode.TextBounds.Width = width or math.huge
		if typeof(Font) == 'Font' then
			VSCode.TextBounds.Font = font
		end
		return TextService:GetTextBoundsAsync(VSCode.TextBounds)
	end,
	MakeCorner = function(self, Offset)
		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, Offset or 8)

		return Corner
	end,
	MakeOutline = function(self, Color,Thickness, Position)
		local UIStroke = Instance.new("UIStroke")
		UIStroke.Color = Color or Color3.fromRGB(50,50,50)
		UIStroke.Thickness = Thickness or 1
		UIStroke.BorderStrokePosition = Position and  Enum.BorderStrokePosition[Position] or Enum.BorderStrokePosition.Outer
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return UIStroke
	end,
	RandomString = function(self, length)
		local Str = ""
		for i = 1, length or 8 do
			Str = Str .. string.char(math.random(32,126))
		end
		return Str
	end,
	Make = function(self, ClassName, PropertyTable, Children) : Instance
		local Inst = Instance.new(ClassName)

		for Property, Value in pairs(PropertyTable or {}) do
			Inst[Property] = Value
		end

		if (Inst:IsA("Frame") or Inst:IsA("TextLabel") or Inst:IsA("TextButton") or Inst:IsA("ImageLabel") or Inst:IsA("ImageButton") or Inst:IsA("ScrollingFrame")) and not table.find(PropertyTable, "BorderSizePixel") then
			Inst.BorderSizePixel = 0
		end

		for _, Child in ipairs(Children or {}) do
			if not Child then break end 
			Child.Parent = Inst
		end

		return Inst
	end,
	AddTooltip = function(self, TooltipText, BoundingFrame, HoverDurationNeeded)
		if not HoverDurationNeeded then HoverDurationNeeded = .8 end
		if not VSCode.Tooltip then return end
		local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
		local IsInFrame = false
		VSCode.Tooltip.Text = ""
		BoundingFrame.MouseEnter:Connect(function()
			IsInFrame = true
			task.delay(HoverDurationNeeded, function()
				if not IsInFrame then
					return
				end
				local tooltipSize = Functions:GetFontSize(TooltipText, VSCode.Tooltip.TextSize, Config.Pallet.Font)


				VSCode.Tooltip.Size = UDim2.new(0,0,0,0)
				VSCode.Tooltip.Text = ""
				VSCode.Tooltip.Visible = true	
				local Tween = TweenService:Create(VSCode.Tooltip, Config.Pallet.Tween, {Size =  UDim2.fromOffset(tooltipSize.X*1.15 + 20, tooltipSize.Y + 10)})
				Tween:Play()
				Tween.Completed:Once(function()
					if not IsInFrame then return end
					VSCode.Tooltip.Text = TooltipText
				end)

			end)
		end)
		BoundingFrame.MouseLeave:Connect(function()
			IsInFrame = false	
			VSCode.Tooltip.Text = ""
			local Tween = TweenService:Create(VSCode.Tooltip, Config.Pallet.Tween, {Size =  UDim2.fromOffset(0,0)})
			Tween:Play()
			Tween.Completed:Once(function() VSCode.Tooltip.Visible = false end)
		end)
		Mouse.Move:Connect(function()
			if IsInFrame then
				VSCode.Tooltip.Position = UDim2.fromOffset(Mouse.X + 20, Mouse.Y + 60)
			end
		end)
	end,
	GetTime = function(self)
		return tostring(DateTime.now():FormatLocalTime("LT", "en-us"))
	end,
	SafeSaveConfig = function(self, Data) : boolean
		if not (writefile and isfile and isfolder and makefolder and readfile and appendfile and deletefile and deletefolder) then 
			return false
		end
		local RanFine, Error = pcall(function()
			if not isfolder("VSCodeIDE") then
				makefolder("VSCodeIDE")
			end	
			writefile("VSCodeIDE\Settings.json", HttpService:JSONEncode(Data))
		end)
		if not RanFine then return false end
		return true

	end,
	SafeLoadConfig = function(self) : {[string] : any} | boolean
		local Return = {
			WindowSize =  UDim2.fromScale(.4, .5),
			WindowPos = UDim2.fromScale(.5, .5),
			WindowMaximized = false
		}
		if not (writefile and isfile and isfolder and makefolder and readfile and appendfile and deletefile and deletefolder) then 
			return Return
		end

		local RanFine, Data = pcall(function()
			if not isfolder("VSCodeIDE") then
				return Return
			end
			if not isfile("VSCodeIDE\Settings.json") then
				return Return
			end
			local File = HttpService:JSONDecode(readfile("VSCodeIDE\Settings.json"))
			Return = {
				WindowSize = File.WindowSize or UDim2.fromScale(.5, .5),
				WindowPos = File.WindowPos or UDim2.fromScale(.5, .5),
				WindowMaximized = File.WindowMaximized or false,
			}
			return Return
		end)
		if not RanFine then 
			return Return	
		end
	end,
	AddColors = function(self, Color, SecColor)
		return Color3.new(
			math.clamp(Color.R + SecColor.R, 0, 1),
			math.clamp(Color.G + SecColor.G, 0, 1),
			math.clamp(Color.B + SecColor.B, 0, 1)
		)
	end

}

function VSCode:InitTitleBar()
	VSCode.Titlebar = Functions:Make("Frame", {
		Name = "Titlebar",
		BackgroundTransparency = 1,
		Parent = VSCode.MainFrame,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1,0,0,38),
		ClipsDescendants = true
	}, {
		Functions:Make("Frame", {
			Name = "Left",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(0.5,-20, 1,0)
		}, {
			Functions:Make("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left
			}),
			Functions:Make("Frame", {
				Name = "IconContainer",
				Size = UDim2.new(0, 32,1,0),
				BackgroundTransparency = 1
			}, {
				Functions:Make("ImageLabel", {
					Name = "VSCodeIcon",
					Image = "rbxassetid://18605743806",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 18,0, 18),
					Position = UDim2.new(0,10,0,10)
				})
			}),
			Functions:Make("Frame", {
				Name = "FileContainer",
				Size = UDim2.new(0, 38,1,0),
				BackgroundTransparency = 1
			}, {
				Functions:Make("TextButton", {
					AutoButtonColor = false,
					Name = "Text",
					Text = "File",
					FontFace = Config.Pallet.Font,
					TextColor3 = Config.Pallet.BackgroundText,
					TextSize = 14,
					BackgroundColor3 = Config.Pallet.Main,
					Size = UDim2.new(1,0,1,-10),
					Position = UDim2.new(0,0,0,5)
				}, {Functions:MakeCorner()})
			}),
			Functions:Make("Frame", {
				Name = "EditContainer",
				Size = UDim2.new(0, 38,1,0),
				BackgroundTransparency = 1
			}, {
				Functions:Make("TextButton", {
					AutoButtonColor = false,
					Name = "Text",
					Text = "Edit",
					FontFace = Config.Pallet.Font,
					TextColor3 = Config.Pallet.BackgroundText,
					TextSize = 14,
					BackgroundColor3 = Config.Pallet.Main,
					Size = UDim2.new(1,0,1,-10),
					Position = UDim2.new(0,0,0,5)
				}, {Functions:MakeCorner()})
			}),
		}),
		Functions:Make("Frame", {
			Name = "Right",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.new(0.5,-20, 1,0)
		}, {
			Functions:Make("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right
			}),
		}),
		Functions:Make("TextButton", {
			AutoButtonColor = false,
			Text ="",
			Name = "Searchbar",
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5,0,0, 0),
			Size = UDim2.new(0.35,0, 1,0),
			AnchorPoint = Vector2.new(0.5,0)
		}, {
			Functions:Make("Frame", {
				Name = "Outline",
				BackgroundTransparency = 1,
				Position = UDim2.new(0,5,0,7),
				Size = UDim2.new(1,-10, 1,-14)
			}, {
				Functions:MakeCorner(),
				Functions:MakeOutline(Functions:AddColors(Config.Pallet.Main, Color3.fromRGB(20,20,20)), 1),
				Functions:Make("TextLabel", {
					Name = "Input",
					Text = "Workspace",
					FontFace = Config.Pallet.Font,
					TextColor3 = Config.Pallet.BackgroundText,
					TextSize = 14,
					Size = UDim2.new(1,-10, 1,-14),
					TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Position = UDim2.new(0,5,0,7),
				})
			})
		}),
		
		
		Functions:Make("Frame", {
			BackgroundColor3 = Config.Pallet.Divider,
			Name = "Divider",
			Size = UDim2.new(1,0,0,1),
			Position = UDim2.new(0,0,1,-1)
		})
	})
	UserInputService.WindowFocusReleased:Connect(function()
		for i,v in pairs(VSCode.Titlebar:GetDescendants()) do
			if v:IsA("ImageLabel") then
				TweenService:Create(v, Config.Pallet.TweenFast, {ImageTransparency = 0.25}):Play()
			end
			if v:IsA("TextButton") or v:IsA("TextLabel") then
				TweenService:Create(v, Config.Pallet.TweenFast, {TextTransparency = 0.25}):Play()
			end

		end
	end)
	UserInputService.WindowFocused:Connect(function()
		for i,v in pairs(VSCode.Titlebar:GetDescendants()) do
			if v:IsA("ImageLabel") then
				TweenService:Create(v, Config.Pallet.TweenFast, {ImageTransparency = 0}):Play()
			end
			if v:IsA("TextButton") or v:IsA("TextLabel") then
				TweenService:Create(v, Config.Pallet.TweenFast, {TextTransparency = 0}):Play()
			end
		end		
	end)
	for i,v in pairs(VSCode.Titlebar:GetDescendants()) do
		if v:IsA("TextButton") then
			v.MouseEnter:Connect(function()
				TweenService:Create(v, Config.Pallet.TweenFast, {BackgroundColor3 = Functions:AddColors(Config.Pallet.Main, Color3.new(0.05,0.05,0.05))}):Play()
			end)
			v.MouseLeave:Connect(function()
				TweenService:Create(v, Config.Pallet.TweenFast, {BackgroundColor3 = Config.Pallet.Main}):Play()
			end)
		end
		if v.Name == "Searchbar" then
			v.MouseEnter:Connect(function()
				TweenService:Create(v.Outline, Config.Pallet.TweenFast, {BackgroundTransparency = 0.95}):Play()
			end)
			v.MouseLeave:Connect(function()
				TweenService:Create(v.Outline, Config.Pallet.TweenFast, {BackgroundTransparency = 1}):Play()
			end)
			
		end
	end
	VSCode.MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if VSCode.MainFrame.AbsoluteSize.X < 340 then
			VSCode.Titlebar.Left.EditContainer.Visible = false
		else
			VSCode.Titlebar.Left.EditContainer.Visible = true
		end
		
		if VSCode.MainFrame.AbsoluteSize.X < 240 then
			VSCode.Titlebar.Left.FileContainer.Visible = false
		else
			VSCode.Titlebar.Left.FileContainer.Visible = true
		end
	end)
end

function VSCode:InitContent()
	VSCode.Content = Functions:Make("Frame", {
		BackgroundTransparency = 1,
		Name = "ContentContainer",
		Size = UDim2.new(1,0,1,-(38 + 18)),
		Position = UDim2.new(0,0,0,38),
		Parent = VSCode.MainFrame
	})
end

function VSCode:InitExplorer()
	VSCode.Explorer = Functions:Make("Frame", {
		Parent = VSCode.Content,
		Name = "Explorer",
		Size = UDim2.new(0, 200, 1,0),
		Position = UDim2.new(0,0,0,0),
		BackgroundColor3 = Functions:AddColors(Config.Pallet.Main, Color3.fromRGB(5,5,5))
	}, {
		Functions:Make("Frame", {
			Name = "Top",
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,0,30),
		}, {
			Functions:Make("TextLabel", {
				Name = "ForgotName",
				Text = "EXPLORER",
				Position = UDim2.new(0,10,0,0),
				Size = UDim2.new(1,-20,1,0),
				BackgroundTransparency = 1,
				TextColor3 = Config.Pallet.BackgroundText,
				FontFace = Config.Pallet.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		}),
		Functions:Make("ScrollingFrame", {
			Name = "Container",
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,1,-30),
			Position = UDim2.new(0,0,0,30),
			ScrollBarThickness = 8,
			ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
		}, {
			Functions:Make("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder
			}),

		})
	})
	VSCode.Explorer:FindFirstChild("Container", true).TopImage = VSCode.Explorer:FindFirstChild("Container", true).MidImage
	VSCode.Explorer:FindFirstChild("Container", true).BottomImage = VSCode.Explorer:FindFirstChild("Container", true).MidImage
end

function VSCode:Init()
	if not game:IsLoaded() then game.Loaded:Wait() end

	Config.WindowConfig = Functions:SafeLoadConfig()
	print(Config.WindowConfig)



	VSCode.ScreenGui = Functions:Make("ScreenGui", {
		Name = "VSCode",
		Parent = Config.GuiHolder,
		IgnoreGuiInset = true,
		ResetOnSpawn = false
	})

	if Config.OnTopOfCoreBlur == true then
		VSCode.ScreenGui.OnTopOfCoreBlur = true
	end

	VSCode.ViewportSize = VSCode.ScreenGui.AbsoluteSize

	VSCode.Tooltip = Functions:Make("TextLabel", {
		BackgroundColor3 = Config.Pallet.Main,
		Text = "",
		Size = UDim2.new(),
		TextSize = 12,
		FontFace = Config.Pallet.Font,
		Parent = VSCode.ScreenGui,
		TextColor3 = Config.Pallet.Text,
		ZIndex = 999999,
		Name = "Tooltip",
		Visible = false,
	},{
		Functions:MakeBlur(),
		Functions:MakeOutline(Config.Pallet.AccentColor, 1)
	})

	VSCode.MainFrame = Functions:Make("Frame", {
		Name = "Main",
		Parent = VSCode.ScreenGui,
		Size = Config.WindowConfig.WindowSize,
		Position = Config.WindowConfig.WindowPos,
		BackgroundColor3 = Config.Pallet.Main,
		AnchorPoint = Vector2.new(.5, .5),
	}, {
		Functions:MakeCorner(),
		Functions:MakeBlur(),
		Functions:MakeOutline(Functions:AddColors(Config.Pallet.Main, Color3.fromRGB(90,90,90)), 1, "Outer"),
		Functions:Make("UISizeConstraint", {
			MaxSize = Vector2.new(1000,800),
			MinSize = Vector2.new(200,300)
		})
	})
end

function VSCode:InitAll()
	VSCode:Init()
	VSCode:InitTitleBar()
	VSCode:InitContent()
	VSCode:InitExplorer()
end

VSCode:InitAll()
