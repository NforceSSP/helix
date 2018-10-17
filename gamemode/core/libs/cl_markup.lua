
-- luacheck: ignore

local string = string
local table = table
local surface = surface
local tostring = tostring
local pairs = pairs
local Msg = Msg
local setmetatable = setmetatable
local math = math
local Material = Material
local tonumber = tonumber
local file = file

ix.markup = ix.markup or {}

-- Temporary information used when building text frames.
local colour_stack = { {r=255,g=255,b=255,a=255} }
local font_stack = { "DermaDefault" }
local curtag = nil
local blocks = {}

local colourmap = {
-- it's all black and white
	["black"] =		{	r=0,	g=0,	b=0,	a=255	},
	["white"] =		{	r=255,	g=255,	b=255,	a=255	},
-- it's greys
	["dkgrey"] =	{	r=64,	g=64,	b=64,	a=255	},
	["grey"] =		{	r=128,	g=128,	b=128,	a=255	},
	["ltgrey"] =	{	r=192,	g=192,	b=192,	a=255	},
-- account for speeling mistakes
	["dkgray"] =	{	r=64,	g=64,	b=64,	a=255	},
	["gray"] =		{	r=128,	g=128,	b=128,	a=255	},
	["ltgray"] =	{	r=192,	g=192,	b=192,	a=255	},
-- normal colours
	["red"] =		{	r=255,	g=0,	b=0,	a=255	},
	["green"] =		{	r=0,	g=255,	b=0,	a=255	},
	["blue"] =		{	r=0,	g=0,	b=255,	a=255	},
	["yellow"] =	{	r=255,	g=255,	b=0,	a=255	},
	["purple"] =	{	r=255,	g=0,	b=255,	a=255	},
	["cyan"] =		{	r=0,	g=255,	b=255,	a=255	},
	["turq"] =		{	r=0,	g=255,	b=255,	a=255	},
-- dark variations
	["dkred"] =		{	r=128,	g=0,	b=0,	a=255	},
	["dkgreen"] =	{	r=0,	g=128,	b=0,	a=255	},
	["dkblue"] =	{	r=0,	g=0,	b=128,	a=255	},
	["dkyellow"] =	{	r=128,	g=128,	b=0,	a=255	},
	["dkpurple"] =	{	r=128,	g=0,	b=128,	a=255	},
	["dkcyan"] =	{	r=0,	g=128,	b=128,	a=255	},
	["dkturq"] =	{	r=0,	g=128,	b=128,	a=255	},
-- light variations
	["ltred"] =		{	r=255,	g=128,	b=128,	a=255	},
	["ltgreen"] =	{	r=128,	g=255,	b=128,	a=255	},
	["ltblue"] =	{	r=128,	g=128,	b=255,	a=255	},
	["ltyellow"] =	{	r=255,	g=255,	b=128,	a=255	},
	["ltpurple"] =	{	r=255,	g=128,	b=255,	a=255	},
	["ltcyan"] =	{	r=128,	g=255,	b=255,	a=255	},
	["ltturq"] =	{	r=128,	g=255,	b=255,	a=255	},
}

--[[
    Name: colourMatch(c)
    Desc: Match a colour name to an rgb value.
   Usage: ** INTERNAL ** Do not use!
]]
local function colourMatch(c)
	c = string.lower(c)

	return colourmap[c]
end

--[[
    Name: ExtractParams(p1,p2,p3)
    Desc: This function is used to extract the tag information.
   Usage: ** INTERNAL ** Do not use!
]]
local function ExtractParams(p1,p2,p3)

	if (string.utf8sub(p1, 1, 1) == "/") then

		local tag = string.utf8sub(p1, 2)

		if (tag == "color" or tag == "colour") then
			table.remove(colour_stack)
		elseif (tag == "font" or tag == "face") then
			table.remove(font_stack)
		end

	else

		if (p1 == "color" or p1 == "colour") then

			local rgba = colourMatch(p2)

			if (rgba == nil) then
				rgba = {}
				local x = { "r", "g", "b", "a" }
				n = 1
				for k, v in string.gmatch(p2, "(%d+),?") do
					rgba[ x[n] ] = k
					n = n + 1
				end
			end

			table.insert(colour_stack, rgba)

		elseif (p1 == "font" or p1 == "face") then

			table.insert(font_stack, tostring(p2))
		elseif (p1 == "img" and p2) then
			local exploded = string.Explode(",", p2)
			local material = exploded[1] or p2
			local p3 = exploded[2]

			local found = file.Find("materials/"..material..".*", "GAME")

			if (found[1] and found[1]:find("%.png")) then
				material = material..".png"
			end

			local texture = Material(material)
			local sizeData = string.Explode("x", p3 or "16x16")
			w = tonumber(sizeData[1]) or 16
			h = tonumber(sizeData[2]) or 16

			if (texture) then
				table.insert(blocks, {
					texture = texture,
					w = w,
					h = h
				})
			end
		end

	end
end

--[[
    Name: CheckTextOrTag(p)
    Desc: This function places data in the "blocks" table
          depending of if p is a tag, or some text
   Usage: ** INTERNAL ** Do not use!
]]
local function CheckTextOrTag(p)
	if (p == "") then return end
	if (p == nil) then return end

	if (string.utf8sub(p, 1, 1) == "<") then
		string.gsub(p, "<([/%a]*)=?([^>]*)", ExtractParams)
	else

		local text_block = {}
		text_block.text = p
		text_block.colour = colour_stack[ table.getn(colour_stack) ]
		text_block.font = font_stack[ table.getn(font_stack) ]
		table.insert(blocks, text_block)

	end
end

--[[
    Name: ProcessMatches(p1,p2,p3)
    Desc: CheckTextOrTag for 3 parameters. Called by string.gsub
   Usage: ** INTERNAL ** Do not use!
]]
local function ProcessMatches(p1,p2,p3)
	if (p1) then CheckTextOrTag(p1) end
	if (p2) then CheckTextOrTag(p2) end
	if (p3) then CheckTextOrTag(p3) end
end

local MarkupObject = {}

--[[
    Name: MarkupObject:Create()
    Desc: Called by Parse. Creates a new table, and setups the
          metatable.
   Usage: ** INTERNAL ** Do not use!
]]
function MarkupObject:create()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	return o
end

--[[
    Name: MarkupObject:GetWidth()
    Desc: Returns the width of a markup block
   Usage: ml:GetWidth()
]]
function MarkupObject:GetWidth()
	return self.totalWidth
end

--[[
    Name: MarkupObject:GetHeight()
    Desc: Returns the height of a markup block
   Usage: ml:GetHeight()
]]
function MarkupObject:GetHeight()
	return self.totalHeight
end

function MarkupObject:size()
	return self.totalWidth, self.totalHeight
end

--[[
    Name: MarkupObject:Draw(xOffset, yOffset, halign, valign, alphaoverride)
    Desc: Draw the markup text to the screen as position
          xOffset, yOffset. Halign and Valign can be used
          to align the text. Alphaoverride can be used to override
          the alpha value of the text-colour.
   Usage: MarkupObject:Draw(100, 100)
]]
function MarkupObject:draw(xOffset, yOffset, halign, valign, alphaoverride)
	for i = 1, #self.blocks do
		local blk = self.blocks[i]

		if (blk.texture) then
			local y = yOffset + blk.offset.y
			local x = xOffset + blk.offset.x

			if (halign == TEXT_ALIGN_CENTER) then
				x = x - (self.totalWidth * 0.5)
			elseif (halign == TEXT_ALIGN_RIGHT) then
				x = x - (self.totalWidth)
			end

			surface.SetDrawColor(blk.colour.r, blk.colour.g, blk.colour.b, alphaoverride or blk.colour.a or 255)
			surface.SetMaterial(blk.texture)
			surface.DrawTexturedRect(x, y, blk.w, blk.h)
		else
			local y = yOffset + (blk.height - blk.thisY) + blk.offset.y
			local x = xOffset

			if (halign == TEXT_ALIGN_CENTER) then		x = x - (self.totalWidth / 2)
			elseif (halign == TEXT_ALIGN_RIGHT) then	x = x - (self.totalWidth)
			end

			x = x + blk.offset.x

			if (self.onDrawText) then
				self.onDrawText(blk.text, blk.font, x, y, blk.colour, halign, valign, alphaoverride, blk)
			else
				if (valign == TEXT_ALIGN_CENTER) then		y = y - (self.totalHeight / 2)
				elseif (valign == TEXT_ALIGN_BOTTOM) then	y = y - (self.totalHeight)
				end

				local alpha = blk.colour.a
				if (alphaoverride) then alpha = alphaoverride end

				surface.SetFont( blk.font )
				surface.SetTextColor( blk.colour.r, blk.colour.g, blk.colour.b, alpha )
				surface.SetTextPos( x, y )
				surface.DrawText( blk.text )
			end
		end
	end
end

--[[
    Name: Parse(ml, maxwidth)
    Desc: Parses the pseudo-html markup language, and creates a
          MarkupObject, which can be used to the draw the
          text to the screen. Valid tags are: font and colour.
          \n and \t are also available to move to the next line,
          or insert a tab character.
          Maxwidth can be used to make the text wrap to a specific
          width.
   Usage: markup.Parse("<font=Default>changed font</font>\n<colour=255,0,255,255>changed colour</colour>")
]]
function ix.markup.Parse(ml, maxwidth)

	ml = utf8.force(ml)

	colour_stack = { {r=255,g=255,b=255,a=255} }
	font_stack = { "DermaDefault" }
	blocks = {}

	if (not string.find(ml, "<")) then
		ml = ml .. "<nop>"
	end

	string.gsub(ml, "([^<>]*)(<[^>]+.)([^<>]*)", ProcessMatches)

	local xOffset = 0
	local yOffset = 0
	local xSize = 0
	local xMax = 0
	local thisMaxY = 0
	local new_block_list = {}
	local ymaxes = {}
	local texOffset = 0

	local lineHeight = 0
	for i = 1, #blocks do
		local block = blocks[i]

		if (block.text) then
			surface.SetFont(block.font)

			local thisY = 0
			local curString = ""
			block.text = string.gsub(block.text, "&gt;", ">")
			block.text = string.gsub(block.text, "&lt;", "<")
			block.text = string.gsub(block.text, "&amp;", "&")

			for j=1,string.utf8len(block.text) do
				local ch = string.utf8sub(block.text,j,j)

				if (ch == "\n") then
					if (thisY == 0) then
						thisY = lineHeight + texOffset;
						thisMaxY = lineHeight + texOffset;
					else
						lineHeight = thisY + texOffset
					end

					if (string.utf8len(curString) > 0) then
						local x1,y1 = surface.GetTextSize(curString)

						local new_block = {}
						new_block.text = curString
						new_block.font = block.font
						new_block.colour = block.colour
						new_block.thisY = thisY
						new_block.thisX = x1
						new_block.offset = {}
						new_block.offset.x = xOffset
						new_block.offset.y = yOffset
						table.insert(new_block_list, new_block)
						if (xOffset + x1 > xMax) then
							xMax = xOffset + x1
						end
					end

					xOffset = 0
					xSize = 0
					yOffset = yOffset + thisMaxY;
					thisY = 0
					curString = ""
					thisMaxY = 0
				elseif (ch == "\t") then

					if (string.utf8len(curString) > 0) then
						local x1,y1 = surface.GetTextSize(curString)

						local new_block = {}
						new_block.text = curString
						new_block.font = block.font
						new_block.colour = block.colour
						new_block.thisY = thisY
						new_block.thisX = x1
						new_block.offset = {}
						new_block.offset.x = xOffset
						new_block.offset.y = yOffset
						table.insert(new_block_list, new_block)
						if (xOffset + x1 > xMax) then
							xMax = xOffset + x1
						end
					end

					local xOldSize = xSize
					xSize = 0
					curString = ""
					local xOldOffset = xOffset
					xOffset = math.ceil( (xOffset + xOldSize) / 50 ) * 50

					if (xOffset == xOldOffset) then
						xOffset = xOffset + 50
					end
				else
					local x,y = surface.GetTextSize(ch)

					if (x == nil) then return end

					if (maxwidth and maxwidth > x) then
						if (xOffset + xSize + x >= maxwidth) then

							-- need to: find the previous space in the curString
							--          if we can't find one, take off the last character
							--          and add a -. add the character to ch
							--          and insert as a new block, incrementing the y etc

							local lastSpacePos = string.utf8len(curString)
							for k=1,string.utf8len(curString) do
								local chspace = string.utf8sub(curString,k,k)
								if (chspace == " ") then
									lastSpacePos = k
								end
							end

							if (lastSpacePos == string.utf8len(curString)) then
								ch = string.utf8sub(curString,lastSpacePos,lastSpacePos) .. ch
								j = lastSpacePos
								curString = string.utf8sub(curString, 1, lastSpacePos-1)
							else
								ch = string.utf8sub(curString,lastSpacePos+1) .. ch
								j = lastSpacePos+1
								curString = string.utf8sub(curString, 1, lastSpacePos)
							end

							local m = 1
							while string.utf8sub(ch, m, m) == " " and m <= string.utf8len(ch) do
								m = m + 1
							end
							ch = string.utf8sub(ch, m)

							local x1,y1 = surface.GetTextSize(curString)

							if (y1 > thisMaxY) then thisMaxY = y1; ymaxes[yOffset] = thisMaxY; lineHeight = y1; end

							local new_block = {}
							new_block.text = curString
							new_block.font = block.font
							new_block.colour = block.colour
							new_block.thisY = thisY
							new_block.thisX = x1
							new_block.offset = {}
							new_block.offset.x = xOffset
							new_block.offset.y = yOffset
							table.insert(new_block_list, new_block)

							if (xOffset + x1 > xMax) then
								xMax = xOffset + x1
							end

							xOffset = 0
							xSize = 0
							x,y = surface.GetTextSize(ch)
							yOffset = yOffset + thisMaxY;
							thisY = 0
							curString = ""
							thisMaxY = 0
						end
					end

					curString = curString .. ch

					thisY = y
					xSize = xSize + x

					if (y > thisMaxY) then thisMaxY = y; ymaxes[yOffset] = thisMaxY; lineHeight = y; end
				end
			end

			if (string.utf8len(curString) > 0) then

				local x1,y1 = surface.GetTextSize(curString)

				local new_block = {}
				new_block.text = curString
				new_block.font = block.font
				new_block.colour = block.colour
				new_block.thisY = thisY
				new_block.thisX = x1
				new_block.offset = {}
				new_block.offset.x = xOffset
				new_block.offset.y = yOffset
				table.insert(new_block_list, new_block)

				lineHeight = thisY

				if (xOffset + x1 > xMax) then
					xMax = xOffset + x1
				end
				xOffset = xOffset + x1
			end
			xSize = 0
		elseif (block.texture) then
			local newBlock = table.Copy(block)
				newBlock.colour = block.colour or {r = 255, g = 255, b = 255, a = 255}
				newBlock.thisX = block.w
				newBlock.thisY = block.h
				newBlock.offset = {
					x = xOffset,
					y = lineHeight * 0.5 - block.h * 0.5
				}

			table.insert(new_block_list, newBlock)
			xOffset = xOffset + block.w + 1
			texOffset = block.h/2
		end
	end

	local totalHeight = 0
	for i = 1, #new_block_list do
		local block = new_block_list[i]
		block.height = ymaxes[block.offset.y]

		if (block.height and block.offset.y + block.height > totalHeight) then
			totalHeight = block.offset.y + block.height
		end
	end

	local newObject = MarkupObject:create()
	newObject.totalHeight = totalHeight
	newObject.totalWidth = xMax
	newObject.blocks = new_block_list
	return newObject
end
