local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ImageButton = require(ReplicatedStorage.UI.components.buttons.ImageButton)
local SettingToggle = require(ReplicatedStorage.UI.components.settings.SettingToggle)

local e = React.createElement

return function(_props)
	return React.createElement("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromScale(0.0833333, 0.22037),
        Size = UDim2.fromScale(0.833333, 0.699074),
        ZIndex = 0,
    }, {
        uICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0.0264901, 0),
        }),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 99, 174)),
                ColorSequenceKeypoint.new(0.97, Color3.fromRGB(90, 99, 174)),
                ColorSequenceKeypoint.new(0.98, Color3.fromRGB(81, 88, 156)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(81, 88, 156)),
            }),
            Rotation = 90,
            Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.97, 0),
                            NumberSequenceKeypoint.new(0.98, 0),
                            NumberSequenceKeypoint.new(1, 0),
            }),
        }),

        uIStroke = React.createElement("UIStroke", {
            Color = Color3.new(1, 1, 1),
            Thickness = 5,
        }),

        header = React.createElement("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(0.015625, 0.0331126),
            Size = UDim2.fromScale(0.96875, 0.0993377),
        }, {
            uICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.133333, 0),
            }),

            uIGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
                    ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
                    ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
                }),
                Rotation = 90,
                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0),
                                                    NumberSequenceKeypoint.new(0.89, 0),
                                                    NumberSequenceKeypoint.new(0.91, 0),
                                                    NumberSequenceKeypoint.new(1, 0),
                }),
            }),

            uIStroke = React.createElement("UIStroke", {
                Color = Color3.new(1, 1, 1),
                Thickness = 2,
            }),

            background = React.createElement("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://122879724941312",
                Position = UDim2.fromScale(-0.00645161, -0.133333),
                Size = UDim2.fromScale(1.0129, 1.26667),
                ZIndex = 0,
            }),

            teextLabel = React.createElement("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = Font.new(
                    "rbxassetid://11702779517",
                    Enum.FontWeight.Heavy,
                    Enum.FontStyle.Italic
                ),
                RichText = true,
                Size = UDim2.fromScale(1, 1),
                Text = "Settings",
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
            }, {
                uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
                    AspectRatio = 20.6667,
                }),

                uIPadding = React.createElement("UIPadding", {
                    PaddingBottom = UDim.new(0.26, 0),
                    PaddingTop = UDim.new(0.26, 0),
                }),
            }),
        }),

        settings = React.createElement("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0.807292, 0.560185),
            Position = UDim2.fromScale(0.015625, 0.165563),
            ScrollBarThickness = 0,
            Size = UDim2.fromScale(0.96875, 0.801324),
            ZIndex = 2,
        }, {
            setting1 = e(SettingToggle, {
                Name = "Setting Name",
                Value = true,
                LayoutOrder = 1,
                OnChange = function(_newValue) end,
            }),

            setting2 = e(SettingToggle, {
                Name = "Setting Name",
                Value = false,
                LayoutOrder = 2,
                OnChange = function(_newValue) end,
            }),

            -- Language setting (unique - not using SettingToggle)
            language = React.createElement("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0.165289),
                LayoutOrder = 3,
                ZIndex = 0,
            }, {
                background = React.createElement("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://137904107688579",
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 0,
                }),

                settingName = React.createElement("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = Font.new(
                        "rbxassetid://11702779517",
                        Enum.FontWeight.Heavy,
                        Enum.FontStyle.Italic
                    ),
                    Position = UDim2.fromScale(0.0180645, 0.28),
                    RichText = true,
                    Size = UDim2.fromScale(0.173548, 0.44),
                    Text = "Language",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, {
                    uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 6.11364,
                    }),

                    uIPadding = React.createElement("UIPadding", {
                        PaddingBottom = UDim.new(0.0909091, 0),
                        PaddingTop = UDim.new(0.0909091, 0),
                    }),
                }),

                languageSelector = React.createElement("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Position = UDim2.fromScale(0.651613, 0.12),
                    Size = UDim2.fromScale(0.335484, 0.75),
                    ZIndex = 2,
                }, {
                    uICorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.133333, 0),
                    }),

                    uIGradient = React.createElement("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 52, 88)),
                            ColorSequenceKeypoint.new(0.89, Color3.fromRGB(47, 52, 88)),
                            ColorSequenceKeypoint.new(0.91, Color3.fromRGB(43, 46, 80)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 46, 80)),
                        }),
                        Rotation = 90,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.89, 0),
                            NumberSequenceKeypoint.new(0.91, 0),
                            NumberSequenceKeypoint.new(1, 0),
                        }),
                    }),

                    uIStroke = React.createElement("UIStroke", {
                        Color = Color3.new(1, 1, 1),
                        Thickness = 2,
                    }),

                    background = React.createElement("ImageLabel", {
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://109396313109098",
                        Position = UDim2.fromScale(-0.0181818, -0.133333),
                        Size = UDim2.fromScale(1.03636, 1.26667),
                        ZIndex = 0,
                    }),

                    textLabel = React.createElement("TextLabel", {
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxassetid://11702779517",
                            Enum.FontWeight.Heavy,
                            Enum.FontStyle.Italic
                        ),
                        Position = UDim2.fromScale(0.172727, 0.2),
                        RichText = true,
                        Size = UDim2.fromScale(0.654545, 0.6),
                        Text = "English",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                    }, {
                        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
                            AspectRatio = 5.41379,
                        }),

                        uIPadding = React.createElement("UIPadding", {
                            PaddingBottom = UDim.new(0.0862069, 0),
                            PaddingTop = UDim.new(0.0862069, 0),
                        }),
                    }),

                    arrowLeft = React.createElement("Frame", {
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Size = UDim2.fromScale(0.136364, 1),
                    }, {
                        uICorner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(1.33333, 0),
                        }),

                        uIGradient = React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(249, 0, 149)),
                                ColorSequenceKeypoint.new(0.918269, Color3.fromRGB(249, 0, 149)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 2, 109)),
                            }),
                            Rotation = 90,
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(0.918269, 0),
                                NumberSequenceKeypoint.new(1, 0),
                            }),
                        }),

                        arrowLeftButton = e(ImageButton, {
                            Image = "rbxassetid://128545361400662",
                            Size = UDim2.fromScale(1.33333, 1.33333),
                            OnClick = function() end,
                        }),
                    }),

                    arrowRight = React.createElement("Frame", {
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Position = UDim2.fromScale(0.863636, 0),
                        Size = UDim2.fromScale(0.136364, 1),
                    }, {
                        uICorner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(1.33333, 0),
                        }),

                        uIGradient = React.createElement("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(249, 0, 149)),
                                ColorSequenceKeypoint.new(0.918269, Color3.fromRGB(249, 0, 149)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 2, 109)),
                            }),
                            Rotation = 90,
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(0.918269, 0),
                                NumberSequenceKeypoint.new(1, 0),
                            }),
                        }),

                        arrowRightButton = e(ImageButton, {
                            Image = "rbxassetid://101380832517952",
                            Size = UDim2.fromScale(1.33333, 1.33333),
                            OnClick = function() end,
                        }),
                    }),
                }),
            }),

            uIListLayout = React.createElement("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0.0165289, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        }),

        background = React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://89383009044144",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
        }, {
            uICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.0264901, 0),
            }),
        }),

        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 2.11921,
        }),
    })
end
