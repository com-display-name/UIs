local cloneref = cloneref or function(...) return ... end
local getgenv = getgenv or function(...) return _G end


local TweenService      = cloneref(game:GetService("TweenService"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local TextService       = cloneref(game:GetService("TextService"))
local GuiService        = cloneref(game:GetService("GuiService"))
local RunService        = cloneref(game:GetService("RunService"))
local HttpService       = cloneref(game:GetService("HttpService"))
local DateTime          = DateTime


local Library = {
	Pallet = {
		Main = Color3.fromRGB(31, 31, 31),
		AltMain =  Color3.fromRGB(41, 41, 41),
		Blue = Color3.fromRGB(0, 122, 204),
		Text = Color3.fromRGB(220,220,220),
		BackgroundText = Color3.fromRGB(160,160,160),
		Font = Font.fromEnum(Enum.Font.Arial),
		Tween = TweenInfo.new(0.16,Enum.EasingStyle.Linear),
		TweenFast = TweenInfo.new(0.06,Enum.EasingStyle.Linear),
	},
	PlaceId = game.PlaceId,
	Tooltip = nil,
	TextBounds = Instance.new("GetTextBoundsParams"),
	OnTopOfCoreBlur = getthreadidentity and getthreadidentity() == 8 or setthreadidentity and setthreadidentity(8) and true or false,
	GuiHolder = (gethui and gethui()) or cloneref(game:GetService("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer.PlayerGui,
	IsDragging = false,
	IsInTextBox = UserInputService:GetFocusedTextBox() or false,
}

Library.TextBounds.Width = math.huge




local function MakeBlur()
	local Blur = Instance.new("ImageLabel")
	Blur.Name = "Blur"
	Blur.Size = UDim2.new(1, 89, 1, 52)
	Blur.Position = UDim2.fromOffset(-48, -31)
	Blur.BackgroundTransparency = 1
	Blur.Image = "rbxassetid://14898786664"
	Blur.ScaleType = Enum.ScaleType.Slice
	Blur.SliceCenter = Rect.new(52, 31, 261, 502)
	return Blur
end

local function MakeCorner(Offset)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Offset or 8)

	return Corner
end

local function MakeOutline(Color,Thickness, Position)
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color or Color3.fromRGB(50,50,50)
	UIStroke.Thickness = Thickness or 1
	UIStroke.BorderStrokePosition = Position and  Enum.BorderStrokePosition[Position] or Enum.BorderStrokePosition.Outer
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return UIStroke
end

local function RandomString(length)
	local Str = ""
	for i = 1, length do
		Str = Str .. string.char(math.random(32,126))
	end
	return Str
end

local function Make(ClassName, PropertyTable, Children) : Instance
	local Inst = Instance.new(ClassName)

	for Property, Value in pairs(PropertyTable or {}) do
		Inst[Property] = Value
	end

	for _, Child in ipairs(Children or {}) do
		if not Child then break end 
		Child.Parent = Inst
	end

	return Inst
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function MakeDraggable(Gui, FrameThatMoves)
	FrameThatMoves = FrameThatMoves or Gui

	local dragging = false
	local dragInput
	local startPos
	local startMousePos

	Gui.InputBegan:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = FrameThatMoves.Position
			startMousePos = inputObj.Position

			inputObj.Changed:Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Gui.InputChanged:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.MouseMovement or inputObj.UserInputType == Enum.UserInputType.Touch then
			dragInput = inputObj
		end
	end)

	UserInputService.InputChanged:Connect(function(inputObj)
		if dragging and inputObj == dragInput then
			local delta = inputObj.Position - startMousePos

			FrameThatMoves.Position = UDim2.new(
				startPos.X.Scale, 
				startPos.X.Offset + delta.X, 
				startPos.Y.Scale, 
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function GetFontSize(Text, Size, font, width)
	Library.TextBounds.Text = Text
	Library.TextBounds.Size = Size
	Library.TextBounds.Width = width or math.huge
	if typeof(Font) == 'Font' then
		Library.TextBounds.Font = font
	end
	return TextService:GetTextBoundsAsync(Library.TextBounds)
end

local function AddTooltip(TooltipText, BoundingFrame, HoverDurationNeeded)
	if not HoverDurationNeeded then HoverDurationNeeded = .8 end
	if not Library.Tooltip then return end
	local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local IsInFrame = false
	Library.Tooltip.Text = ""
	BoundingFrame.MouseEnter:Connect(function()
		IsInFrame = true
		task.delay(HoverDurationNeeded, function()
			if not IsInFrame then
				return
			end
			local tooltipSize = GetFontSize(TooltipText, Library.Tooltip.TextSize, Library.Pallet.Font)


			Library.Tooltip.Size = UDim2.new(0,0,0,0)
			Library.Tooltip.Text = ""
			Library.Tooltip.Visible = true	
			local Tween = TweenService:Create(Library.Tooltip, Library.Pallet.Tween, {Size =  UDim2.fromOffset(tooltipSize.X + 20, tooltipSize.Y + 10)})
			Tween:Play()
			Tween.Completed:Once(function()
				if not IsInFrame then return end
				Library.Tooltip.Text = TooltipText
			end)

		end)
	end)
	BoundingFrame.MouseLeave:Connect(function()
		IsInFrame = false	
		Library.Tooltip.Text = ""
		local Tween = TweenService:Create(Library.Tooltip, Library.Pallet.Tween, {Size =  UDim2.fromOffset(0,0)})
		Tween:Play()
		Tween.Completed:Once(function() Library.Tooltip.Visible = false end)
	end)
	Mouse.Move:Connect(function()
		if IsInFrame then
			Library.Tooltip.Position = UDim2.fromOffset(Mouse.X + 20, Mouse.Y + 60)
		end
	end)
end

function Library:CreateGui()

	if not game:IsLoaded() then game.Loaded:Wait() end

	local function GetTime(): string
		return tostring(DateTime.now():FormatLocalTime("LT", "en-us"))
	end
	
	local function MakeLines(amount) : string
		local str = ""
		for i = 1, amount do
			str = str .. tostring(i) .. "\n"
		end
	end

	local ScreenGui = Make("ScreenGui", {
		ResetOnSpawn = false,
		Name = "VSCode",
		IgnoreGuiInset = true,
		ClipToDeviceSafeArea = false,
		Parent = Library.GuiHolder
	})

	if Library.OnTopOfCoreBlur then ScreenGui.OnTopOfCoreBlur = true end

	Library.Tooltip = Make("TextLabel", {
		BackgroundColor3 = Library.Pallet.Main,
		Text = "",
		Size = UDim2.new(),
		TextSize = 12,
		FontFace = Library.Pallet.Font,
		Parent = ScreenGui,
		TextColor3 = Library.Pallet.Text,
		ZIndex = 999999,
		Visible = false,
	}, {
		MakeCorner(),
		MakeBlur(),
		MakeOutline()
	})

	local Main = Make("Frame", {
		Parent = ScreenGui,
		Name = "Main",
		Size = UDim2.new(0,600,0,350),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.new(0.5,0,0.5,0),
		BackgroundColor3 = Library.Pallet.Main
	}, {
		Make("UISizeConstraint", {
			MinSize = Vector2.new(420, 200),
			MaxSize = Vector2.new(700, 440)
		}),
		MakeOutline(Library.Pallet.Blue, 2),
		MakeCorner(),
		Make("Frame", {
			Name = "Topbar",
			Size = UDim2.new(1,0,0,32),
			Position = UDim2.new(0,0,0,0),
			BackgroundTransparency = 1
		}, {
			Make("Frame", {
				Name = "Searchbar",
				Size = UDim2.new(0,240,1,-10),
				Position = UDim2.new(0.5,-120,0,5),
				BackgroundColor3 = Color3.fromRGB(40,40,40)
			}, {
				MakeCorner(),
				MakeOutline(Color3.fromRGB(60,60,60)),
				Make("TextBox", {
					Size = UDim2.new(1,-28,1,0),
					Position = UDim2.new(0,4,0,0),
					Name = "Input",
					BackgroundTransparency = 1,
					PlaceholderText = "Workspace",
					FontFace = Library.Pallet.Font,
					TextColor3 = Library.Pallet.Text,
					PlaceholderColor3 = Library.Pallet.BackgroundText,
					TextSize = 14,
					Text = "",
					ClearTextOnFocus = true,
					TextTruncate = Enum.TextTruncate.AtEnd
				}),
				Make("TextButton", {
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Size = UDim2.new(0,22,0,22),
					Position = UDim2.new(1,-26,0,0),
					Text = ""
				}, {
					Make("ImageLabel", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://8447654914",
						Size = UDim2.new(0,14,0,14),
						Position = UDim2.new(0,4,0,4),
						ImageColor3 = Library.Pallet.BackgroundText
					})
				})
			}),
			Make("TextButton", {
				AutoButtonColor = false,
				Text = "",
				Name = "UpdateButton",
				Size = UDim2.new(0,60,1,-10),
				Position = UDim2.new(0.5,130,0,5),
				BackgroundColor3 = Library.Pallet.Blue
			}, {
				MakeCorner(),
				Make("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1,-16,1,0),
					Position = UDim2.new(0,8,0,0),
					FontFace = Library.Pallet.Font,
					TextColor3 = Library.Pallet.Text,
					TextSize = 12,
					Text = "Update"
				}, {
				})
			}),
			Make("Frame", {
				Name = "Right",
				Size = UDim2.new(0.5,0,1,0),
				Position = UDim2.new(0.5,0,0,0),
				BackgroundTransparency = 1,
			}, {
				Make("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				})
			}),
			Make("TextButton", {
				Name = "Icon",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(0,0,0,0),
				Text = ""
			}, {
				Make("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://18605743806",
					Size = UDim2.new(0,18,0,18),
					Position = UDim2.new(0,7,0,7)
				})
			}),
			Make("TextButton", {
				Name = "Redo",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(0.5,-158,0,0),
				Text = ""
			}, {
				Make("ImageLabel", {
					BackgroundTransparency = 1,
					Rotation = 270,
					ImageColor3 = Library.Pallet.BackgroundText,
					ImageTransparency = 0.2,
					Image = "rbxassetid://153287167",
					Size = UDim2.new(0,14,0,14),
					Position = UDim2.new(0,9,0,9)
				})
			}),
			Make("TextButton", {
				Name = "Undo",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(0.5,-180,0,0),
				Text = ""
			}, {
				Make("ImageLabel", {
					BackgroundTransparency = 1,
					Rotation = 90,
					ImageColor3 = Library.Pallet.BackgroundText,
					ImageTransparency = 0.2,
					Image = "rbxassetid://153287167",
					Size = UDim2.new(0,14,0,14),
					Position = UDim2.new(0,9,0,9)
				})
			}),
			Make("TextButton", {
				Name = "Close",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(1,-32,0,0),
				Text = ""
			}, {
				Make("ImageLabel", {
					BackgroundTransparency = 1,
					Rotation = 90,
					ImageColor3 = Library.Pallet.BackgroundText,
					ImageTransparency = 0.2,
					Image = "rbxassetid://113890280335265",
					Size = UDim2.new(0,14,0,14),
					Position = UDim2.new(0,9,0,9)
				})
			})
		}),
		Make("Frame", {
			Name = "Statusbar",
			Size = UDim2.new(1,0,0,24),
			Position = UDim2.new(0,0,1,-24),
			BackgroundTransparency = 1
		}, {
			Make("Frame", {
				Name = "Left",
				Size = UDim2.new(0.5,0,1,0),
				Position = UDim2.new(0,0,0,0),
				BackgroundTransparency = 1,
			}, {
				Make("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				})
			}),
			Make("Frame", {
				Name = "Right",
				Size = UDim2.new(0.5,0,1,0),
				Position = UDim2.new(0.5,0,0,0),
				BackgroundTransparency = 1,
			}, {
				Make("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				}),
				Make("TextLabel", {
					Name = "Time",
					Size = UDim2.new(0,80,1,0),
					BackgroundTransparency = 1,
					TextColor3 = Library.Pallet.BackgroundText,
					FontFace = Library.Pallet.Font,
					Text = GetTime(),
					TextSize = 14
				})
			})
		}),
		Make("Frame", {
			Name = "Content",
			Size = UDim2.new(1,0,1,-56),
			Position = UDim2.new(0,0,0,32),
			BackgroundTransparency = 1
		}, {
			Make("Frame", {
				Name = "ScriptContainer",
				Size = UDim2.new(0.65,0,1,-32),
				Position = UDim2.new(0.35,0,0,32),
				BackgroundColor3 = Library.Pallet.AltMain,
				BorderSizePixel = 0,
			}, {
				Make("ScrollingFrame", {
					Name = "Viewer",
					Size = UDim2.new(1,0,1,0),
					Position = UDim2.new(0,0,0,0),
					BackgroundTransparency = 1
				}, {
					Make("TextLabel", {
						Name = "Lines",
						Size = UDim2.new(0,16,1,0),
						Position = UDim2.new(0,0,0,0),
						BackgroundTransparency = 1,
						TextColor3 = Library.Pallet.BackgroundText,
						FontFace = Library.Pallet.Font,
						RichText = true,
						Text = MakeLines(2),
						TextWrapped = true
					})	
				})
			}),
			Make("Frame", {
				Name = "Explorer",
				Size = UDim2.new(0.35,0,1,-32),
				Position = UDim2.new(0,0,0,32),
				BackgroundColor3 = Library.Pallet.Main,
				BorderSizePixel = 0,
			})
		}),
	})
	
	MakeDraggable(Main:FindFirstChild("Topbar"), Main)

	task.spawn(function()
		while true do
			Main:FindFirstChild("Statusbar"):FindFirstChild("Right"):FindFirstChild("Time").Text = GetTime()
			task.wait(1)
		end
	end)

end
Library:CreateGui()
