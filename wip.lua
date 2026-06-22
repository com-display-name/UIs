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
		AltMain =  Color3.fromRGB(26,26,26),
		Blue = Color3.fromRGB(0, 122, 204),
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
	TextBounds = Instance.new("GetTextBoundsParams"),
	OnTopOfCoreBlur = getthreadidentity and getthreadidentity() == 8 or setthreadidentity and setthreadidentity(8) and true or false,
	GuiHolder = (gethui and gethui()) or cloneref(game:GetService("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer.PlayerGui,
	IsDragging = false,
	IsMaximized = false,
	PreviousSize = UDim2.new(),
	CurrentLineCount = 0,
}

Library.TextBounds.Width = math.huge


local highlighter = {
	keywords = {
		lua = {
			["and"] = true, ["break"] = true, ["or"] = true, ["else"] = true, 
			["elseif"] = true, ["if"] = true, ["then"] = true, ["until"] = true, 
			["repeat"] = true, ["while"] = true, ["do"] = true, ["for"] = true, 
			["in"] = true, ["end"] = true, ["local"] = true, ["return"] = true, 
			["function"] = true, ["export"] = true,
		},
		rbx = {
			["game"] = true, ["workspace"] = true, ["script"] = true, ["math"] = true, 
			["string"] = true, ["table"] = true, ["task"] = true, ["wait"] = true, 
			["select"] = true, ["next"] = true, ["Enum"] = true, ["tick"] = true, 
			["assert"] = true, ["shared"] = true, ["loadstring"] = true, ["tonumber"] = true, 
			["tostring"] = true, ["type"] = true, ["typeof"] = true, ["unpack"] = true, 
			["Instance"] = true, ["CFrame"] = true, ["Vector3"] = true, ["Vector2"] = true, 
			["Color3"] = true, ["UDim"] = true, ["UDim2"] = true, ["Ray"] = true, 
			["BrickColor"] = true, ["OverlapParams"] = true, ["RaycastParams"] = true, 
			["Axes"] = true, ["Random"] = true, ["Region3"] = true, ["Rect"] = true, 
			["TweenInfo"] = true, ["collectgarbage"] = true, ["not"] = true, ["utf8"] = true, 
			["pcall"] = true, ["xpcall"] = true, ["_G"] = true, ["setmetatable"] = true, 
			["getmetatable"] = true, ["os"] = true, ["pairs"] = true, ["ipairs"] = true,
		},
		operators = {
			["#"] = true, ["+"] = true, ["-"] = true, ["*"] = true, 
			["%"] = true, ["/"] = true, ["^"] = true, ["="] = true, 
			["~"] = true, ["<"] = true, [">"] = true,
		}
	},
	colors = {
		numbers = Color3.fromHex("#FAB387"),
		boolean = Color3.fromHex("#FAB387"),
		operator = Color3.fromHex("#94E2D5"),
		lua = Color3.fromHex("#CBA6F7"),
		rbx = Color3.fromHex("#F38BA8"), -- def
		str = Color3.fromHex("#A6E3A1"),
		comment = Color3.fromHex("#9399B2"),
		null = Color3.fromHex("#F38BA8"), -- nil
		call = Color3.fromHex("#89B4FA"),    
		self_call = Color3.fromHex("#89B4FA"),
		local_property = Color3.fromHex("#CBA6F7"),
	}
}
function highlighter:getHighlight(tokens, index)
	local token = tokens[index]

	if highlighter.colors[token .. "_color"] then
		return highlighter.colors[token .. "_color"]
	end

	if tonumber(token) then
		return highlighter.colors.numbers
	elseif token == "nil" then
		return highlighter.colors.null
	elseif token:sub(1, 2) == "--" then
		return highlighter.colors.comment
	elseif highlighter.keywords.operators[token] then
		return highlighter.colors.operator
	elseif highlighter.keywords.lua[token] then
		return highlighter.colors.lua
	elseif highlighter.keywords.rbx[token] then
		return highlighter.colors.rbx
	elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
		return highlighter.colors.str
	elseif token == "true" or token == "false" then
		return highlighter.colors.boolean
	end

	if tokens[index + 1] == "(" then
		if tokens[index - 1] == ":" then
			return highlighter.colors.self_call
		end

		return highlighter.colors.call
	end

	if tokens[index - 1] == "." then
		if tokens[index - 2] == "Enum" then
			return highlighter.colors.rbx
		end

		return highlighter.colors.local_property
	end
end

function highlighter:run(source)
	local tokens = {}
	local currentToken = ""

	local inString = false
	local inComment = false
	local commentPersist = false

	for i = 1, #source do
		local character = source:sub(i, i)

		if inComment then
			if character == "\n" and not commentPersist then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""

				inComment = false
			elseif source:sub(i - 1, i) == "]]" and commentPersist then
				currentToken = currentToken .. "]"

				table.insert(tokens, currentToken)
				currentToken = ""

				inComment = false
				commentPersist = false
			else
				currentToken = currentToken .. character
			end
		elseif inString then
			if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
				currentToken = currentToken .. character
				inString = false
			else
				currentToken = currentToken .. character
			end
		else
			if source:sub(i, i + 1) == "--" then
				table.insert(tokens, currentToken)
				currentToken = "-"
				inComment = true
				commentPersist = source:sub(i + 2, i + 3) == "[["
			elseif character == "\"" or character == "\'" then
				table.insert(tokens, currentToken)
				currentToken = character
				inString = character
			elseif highlighter.keywords.operators[character] then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			elseif character:match("[%w_]") then
				currentToken = currentToken .. character
			else
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			end
		end
	end

	table.insert(tokens, currentToken)

	local highlighted = {}

	for i, token in ipairs(tokens) do
		local highlight = highlighter:getHighlight(tokens, i)

		if highlight then
			local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

			table.insert(highlighted, syntax)
		else
			table.insert(highlighted, token)
		end
	end

	return table.concat(highlighted)
end



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

local EncodingService = game:GetService("EncodingService")
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
			Library.IsMaximized = false
			startPos = FrameThatMoves.Position
			startMousePos = inputObj.Position
			Library.IsDragging = true
			inputObj.Changed:Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End then
					dragging = false
					Library.IsDragging = false
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
		amount = amount or 1
		for i = 1, amount do
			str = str .. tostring(i) .. "\n"
		end
		return str
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
		Name = "Tooltip",
		Visible = false,
	}, {
		MakeCorner(),
		MakeBlur(),
		MakeOutline()
	})
	
	local ClosedButton = Make("TextButton", {
		Name = "ClosedButton",
		Size = UDim2.new(0,150,0,30),
		Position = UDim2.new(0,20,1.2,0),
		BackgroundColor3 = Library.Pallet.Main,
		Text = "",
		AutoButtonColor = false,
		Parent = ScreenGui,
		Visible = true
	}, {
		MakeCorner(),
		MakeBlur(),
		MakeOutline(),
		Make("TextLabel", {
			Text = "Visual Studio Code",
			Size = UDim2.new(0, 120, 1, 0),
			Position = UDim2.new(0,30,0,0),
			BackgroundTransparency = 1,
			FontFace = Library.Pallet.Font,
			TextColor3 = Library.Pallet.Text,
			TextSize = 14
		}),
		Make("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://18605743806",
			Size = UDim2.new(0,20,0,20),
			Position = UDim2.new(0,5,0,5)
		})
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
			MaxSize = Vector2.new(1200, 760)
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
				Name = "Maximize",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(1,-64,0,0),
				Text = ""
			}, {
				Make("Frame", {
					Name = "Icon",
					Size = UDim2.new(0,20,0,20),
					Position = UDim2.new(0,6,0,6),
					BackgroundColor3 = Library.Pallet.Main,
					BorderSizePixel = 0
				}, {
					Make("UIStroke", {
						BorderOffset = UDim.new(0,-4),
						Color = Color3.fromRGB(160,160,160)
					})
				})
			}),
			Make("TextButton", {
				Name = "Minimize",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(1,-96,0,0),
				Text = ""
			}, {
				Make("Frame", {
					Name = "Icon",
					Size = UDim2.new(0,16,0,2),
					Position = UDim2.new(0,8,0,14),
					BackgroundColor3 = Color3.fromRGB(160,160,160),
					BorderSizePixel = 0
				}, {
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
					Name = "Icon",
					Size = UDim2.new(0,26,0,26),
					Position = UDim2.new(0,3,0,3),
					ImageColor3 = Color3.fromRGB(160,160,160),
					BackgroundTransparency = 1,
					Image = "rbxassetid://130629964514885"
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
					FillDirection = Enum.FillDirection.Horizontal
				}),
				Make("TextButton", {
					AutoButtonColor = false,
					Name = "Execute",
					Size = UDim2.new(0,80,1,0),
					BackgroundTransparency = 1,
					FontFace = Library.Pallet.Font,
					Text = "",
				}, {
					Make("ImageLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0,14,0,14),
						Position = UDim2.new(0,5,0,5),
						Rotation = 90,
						Image = "rbxassetid://126330486745540",
						ImageColor3 = Color3.fromRGB(160,160,160)
					}),
					Make("TextLabel", {
						Name = "Text",
						Text = "Execute",
						Size = UDim2.new(1,-20,1,0),
						Position = UDim2.new(0,20,0,0),
						BackgroundTransparency = 1,
						FontFace = Library.Pallet.Font,
						TextColor3 = Library.Pallet.BackgroundText,
						TextSize = 14
					})
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
					FillDirection = Enum.FillDirection.Horizontal
				}),
				Make("TextLabel", {
					Name = "LineColumn",
					Size = UDim2.new(0,80,1,0),
					BackgroundTransparency = 1,
					TextColor3 = Library.Pallet.BackgroundText,
					FontFace = Library.Pallet.Font,
					Text = "Ln 1, Col 1",
					TextSize = 14
				}),
				Make("TextLabel", {
					Name = "Time",
					Size = UDim2.new(0,80,1,0),
					BackgroundTransparency = 1,
					TextColor3 = Library.Pallet.BackgroundText,
					FontFace = Library.Pallet.Font,
					Text = GetTime(),
					TextSize = 14
				}),

			})
		}),
		Make("Frame", {
			Name = "Content",
			Size = UDim2.new(1,0,1,-56),
			Position = UDim2.new(0,0,0,32),
			BackgroundTransparency = 1
		}, {
			Make("Frame", {
				Name = "PathContainer",
				Size = UDim2.new(0.65,0,0,18),
				Position = UDim2.new(0.35,0,0,32),
				BackgroundColor3 = Library.Pallet.AltMain,
				BorderSizePixel = 0,
			}, {
				Make("TextLabel", {
					Name = "PathLabel",
					Size = UDim2.new(1,-12,1,-2),
					Position = UDim2.new(0,6,0,0),
					FontFace = Library.Pallet.Font,
					TextColor3 = Library.Pallet.BackgroundText,
					BackgroundTransparency = 1,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = "",
				})	
			}),
			Make("Frame", {
				Name = "ScriptContainer",
				Size = UDim2.new(0.65,0,1,-50),
				Position = UDim2.new(0.35,0,0,50),
				BackgroundColor3 = Library.Pallet.AltMain,
				BorderSizePixel = 0,
			}, {
				Make("ScrollingFrame", {
					Name = "Viewer",
					Size = UDim2.new(1,0,1,0),
					Position = UDim2.new(0,0,0,0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0
				}, {
					Make("TextLabel", {
						Name = "Lines",
						Size = UDim2.new(0,16,1,0),
						Position = UDim2.new(0,0,0,0),
						BackgroundTransparency = 1,
						TextColor3 = Library.Pallet.BackgroundText,
						FontFace = Library.Pallet.Font,
						RichText = true,
						Text = MakeLines(1),
						TextSize = 14,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextWrapped = true
					}),
					Make("TextBox", {
						Name = "ScriptContentInput",
						Size = UDim2.new(1,-20,1,0),
						Position = UDim2.new(0,20,0,0),
						BackgroundTransparency = 1,
						MultiLine = true,
						TextColor3 = Library.Pallet.BackgroundText,
						TextTransparency = 1,
						FontFace = Library.Pallet.Font,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						RichText = true,
						Text = "",
						ClearTextOnFocus = false,
						TextSize = 14,
						TextWrapped = true,
						ZIndex = 10000
					}),
					Make("TextBox", {
						Name = "ScriptContentOutput",
						Size = UDim2.new(1,-20,1,0),
						Position = UDim2.new(0,20,0,0),
						BackgroundTransparency = 1,
						MultiLine = true,
						TextColor3 = Library.Pallet.BackgroundText,
						FontFace = Library.Pallet.Font,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						RichText = true,
						Text = "",
						TextSize = 14,
						ClearTextOnFocus = false,
						TextWrapped = true,
						ZIndex = 999
					})
				})
			}),
			Make("Frame", {Name = "Divider", Size=UDim2.new(0,1,1,0), Position = UDim2.new(0.35,-1,0,0),BorderSizePixel = 0,BackgroundColor3 = Library.Pallet.Divider, ZIndex = 10}),
			Make("Frame", {Name = "Divider", Size=UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0),BorderSizePixel = 0,BackgroundColor3 = Library.Pallet.Divider, ZIndex = 10}),
			Make("Frame", {Name = "Divider", Size=UDim2.new(0.35,-1,0,1), Position = UDim2.new(0,0,0,0),BorderSizePixel = 0,BackgroundColor3 = Library.Pallet.Divider, ZIndex = 10}),
			Make("Frame", {Name = "Divider", Size=UDim2.new(0.65,-1,0,1), Position = UDim2.new(0.35,0,0,32),BorderSizePixel = 0,BackgroundColor3 = Library.Pallet.Divider, ZIndex = 10}),
			Make("Frame", {
				Name = "Explorer",
				Size = UDim2.new(0.35,-1,1,0),
				Position = UDim2.new(0,0,0,0),
				BackgroundColor3 = Library.Pallet.Main,
				BorderSizePixel = 0,
			})
		}),
	})

	local Topbar        = Main:FindFirstChild("Topbar", true)
	local SearchInput   = Main:FindFirstChild("Input", true)
	local UpdateButton  = Main:FindFirstChild("UpdateButton", true)
	local CloseButton   = Main:FindFirstChild("Close", true)
	local ScriptViewer  = Main:FindFirstChild("Viewer", true)
	local Explorer      = Main:FindFirstChild("Explorer", true)
	local Lines         = Main:FindFirstChild("Lines", true)
	local Path          = Main:FindFirstChild("PathLabel", true)
	local LineCol       = Main:FindFirstChild("LineColumn", true)
	local CloseButton   = Main:FindFirstChild("Close", true)
	local Minimize = Main:FindFirstChild("Minimize", true)
	local Maximize = Main:FindFirstChild("Maximize", true)
	local Execute = Main:FindFirstChild("Execute", true)
	local ScriptContent = ScriptViewer:FindFirstChild("ScriptContentInput", true)
	local ScriptContentOutput = ScriptViewer:FindFirstChild("ScriptContentOutput", true)

	MakeDraggable(Main:FindFirstChild("Topbar"), Main)

	-- returns the state of scrolling
	local function ToggleScrolling(): boolean
		ScriptViewer.ScrollingEnabled = not ScriptViewer.ScrollingEnabled
		return ScriptViewer.ScrollingEnabled
	end

	local function UpdateLines()
		local lines = string.split(ScriptContent.Text, "\n")

		local font = ScriptContent.Font
		local textSize = ScriptContent.TextSize
		local maxFrameWidth = ScriptContent.AbsoluteSize.X

		local singleLineHeight = TextService:GetTextSize("A", textSize, font, Vector2.new(math.huge, math.huge)).Y

		local result = {}

		for lineNumber, lineText in ipairs(lines) do
			table.insert(result, tostring(lineNumber))

			if lineText ~= "" then
				local constraintSize = Vector2.new(maxFrameWidth, math.huge)
				local stringSize = TextService:GetTextSize(lineText, textSize, font, constraintSize)
				local wrappedRows = math.round(stringSize.Y / singleLineHeight)

				if wrappedRows > 1 then
					for i = 1, wrappedRows - 1 do
						table.insert(result, "")
					end
				end
			end
		end

		Lines.Text = table.concat(result, "\n")
	end
	
	local function ToggleUpdateButton()
		UpdateButton.Visible = not UpdateButton.Visible
	end
	
	local function UpdateCanvasSize()
		ScriptViewer.CanvasSize = UDim2.new(0,0,0,Library.CurrentLineCount * 14)
	end

	local function UpdateCanvasPosition()
		ScriptViewer.CanvasPosition = Vector2.new(0,ScriptContent.TextBounds.Y)
	end

	local function UpdateLineAndCol()
		local cursorPosition = ScriptContent.CursorPosition
		if cursorPosition == -1 then return end

		local textUpToCursor = string.sub(ScriptContent.Text, 1, cursorPosition - 1)

		local lines = string.split(textUpToCursor, "\n")

		local currentLine = #lines

		local currentColumn = string.len(lines[currentLine]) + 1

		Library.CurrentLineCount = currentLine

		LineCol.Text = "Ln " .. tostring(currentLine) .. ", Col " .. tostring(currentColumn)
	end

	local function UpdateCode()
		ScriptContentOutput.Text = highlighter:run(ScriptContent.Text)
	end

	ScriptContent:GetPropertyChangedSignal("Text"):Connect(function() 
		UpdateLines()
		UpdateCanvasSize()
		UpdateCanvasPosition()
		UpdateCode()
		UpdateLineAndCol()
	end)

	local function UpdatePath(Inst : Instance )
		if typeof(Inst) == "Instance" then
			Path.Text = "game › " .. string.gsub(Inst:GetFullName(), "%.", " › ")
		end
	end

	local function SetScript(InstanceOrString: Instance | string)
		if typeof(InstanceOrString) == "string" then
			ScriptContent.Text = InstanceOrString
		end
	end

	local function LoadExplorer()
		local ServicesToLoad = {
			game:GetService("Workspace"),
			game:GetService("ReplicatedFirst"),
			game:GetService("ReflectionService"),
			game:GetService("StarterPlayer"),
			game:GetService("StarterPack"),
			game:GetService("StarterGui"),
			game:GetService("Lighting")
		}
	end
	
	CloseButton.MouseButton1Click:Connect(function()
		local Tween = TweenService:Create(Main, Library.Pallet.TweenSlow, {Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, 1.5, 0)})
		Tween:Play()
		Tween.Completed:Wait()
		ScreenGui:Destroy()
	end)
	
	
	Maximize.MouseButton1Click:Connect(function()
		if not Library.IsMaximized then
			Library.PreviousSize = Main.Size
			TweenService:Create(Main, Library.Pallet.TweenSlow, {Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,1100, 0, 700)}):Play()
		else
			TweenService:Create(Main, Library.Pallet.TweenSlow, {Position = UDim2.new(0.5,0,0.5,0), Size = Library.PreviousSize}):Play()
		end
		Library.IsMaximized = not Library.IsMaximized
	end)
	
	Minimize.MouseButton1Click:Connect(function()
		local Tween = TweenService:Create(Main, Library.Pallet.TweenSlow, {Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, 1.2, 0)})
		Tween:Play()
		Tween.Completed:Wait()
		TweenService:Create(ClosedButton, Library.Pallet.TweenSlow, {Position = UDim2.new(0,20,1,-50)}):Play()
		ClosedButton.MouseButton1Click:Once(function()
			TweenService:Create(ClosedButton, Library.Pallet.TweenSlow, {Position = UDim2.new(0,20,1.2,0)}):Play()
			TweenService:Create(Main, Library.Pallet.TweenSlow, {Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, 0.5, 0)}):Play()
		end)
	end)
	
	Execute.MouseButton1Click:Connect(function()
		loadstring(ScriptContent.Text)()
	end)
	
	task.spawn(function()
		while true do
			Main:FindFirstChild("Statusbar"):FindFirstChild("Right"):FindFirstChild("Time").Text = GetTime()
			task.wait(0.5)
		end
	end)

	
	do
		UpdatePath(game)
		ToggleUpdateButton()
	end



end
Library:CreateGui()
