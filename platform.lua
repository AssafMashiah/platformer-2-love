local Platform = {}
Platform.__index = Platform

Platform.TYPES = {
    GROUND = "ground",
    FLOATING = "floating",
    MOVING = "moving"
}

Platform.TILE_SIZE = 32

function Platform.new(x, y, width, height, platformType, config)
    local self = setmetatable({}, Platform)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.type = platformType or Platform.TYPES.FLOATING
    self.config = config or {}

    self.startX = x
    self.startY = y
    self.moveSpeed = self.config.moveSpeed or 100
    self.moveRange = self.config.moveRange or 200
    self.horizontal = self.config.horizontal ~= false

    self.image = nil
    self.quads = nil
    self.colors = self:generateColors()

    return self
end

function Platform:generateColors()
    local typeColors = {
        [Platform.TYPES.GROUND] = {
            top = {0.3, 0.5, 0.2},
            middle = {0.25, 0.4, 0.15},
            bottom = {0.2, 0.35, 0.1}
        },
        [Platform.TYPES.FLOATING] = {
            top = {0.4, 0.4, 0.5},
            middle = {0.35, 0.35, 0.45},
            bottom = {0.3, 0.3, 0.4}
        },
        [Platform.TYPES.MOVING] = {
            top = {0.5, 0.3, 0.3},
            middle = {0.45, 0.25, 0.25},
            bottom = {0.4, 0.2, 0.2}
        }
    }
    return typeColors[self.type] or typeColors[Platform.TYPES.FLOATING]
end

function Platform:generateTileGraphics()
    local tileW = Platform.TILE_SIZE
    local tileH = Platform.TILE_SIZE
    local canvasW = tileW * 3
    local canvasH = tileH * 3
    local canvas = love.graphics.newCanvas(canvasW, canvasH)
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    local colors = self.colors
    for row = 0, 2 do
        for col = 0, 2 do
            local px, py = col * tileW, row * tileH
            local colorKey = row == 0 and "top" or (row == 2 and "bottom" or "middle")
            local color = colors[colorKey]

            love.graphics.setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", px, py, tileW, tileH)

            local highlight = {math.min(1, color[1] + 0.15), math.min(1, color[2] + 0.15), math.min(1, color[3] + 0.15)}
            love.graphics.setColor(highlight[1], highlight[2], highlight[3], 1)
            love.graphics.rectangle("fill", px, py, tileW, 3)

            local shadow = {math.max(0, color[1] - 0.1), math.max(0, color[2] - 0.1), math.max(0, color[3] - 0.1)}
            love.graphics.setColor(shadow[1], shadow[2], shadow[3], 1)
            love.graphics.rectangle("fill", px, py + tileH - 3, tileW, 3)

            if row == 0 and self.type == Platform.TYPES.MOVING then
                love.graphics.setColor(1, 0.8, 0.4, 0.8)
                local arrowW, arrowH = 8, 6
                local ax, ay = px + tileW / 2, py + tileH / 2
                love.graphics.polygon("fill", ax - arrowW / 2, ay + arrowH / 2, ax + arrowW / 2, ay + arrowH / 2, ax, ay - arrowH / 2)
            elseif row == 2 and self.type == Platform.TYPES.GROUND then
                love.graphics.setColor(0.5, 0.3, 0.1, 1)
                for i = 0, 2 do
                    local dx = px + 5 + i * 10 + math.sin(i * 1.5) * 3
                    love.graphics.circle("fill", dx, py + 4, 2)
                end
            end
        end
    end

    love.graphics.setCanvas(oldCanvas)
    love.graphics.setColor(1, 1, 1, 1)
    self.image = love.graphics.newImage(canvas)

    self.quads = {}
    for row = 0, 2 do
        for col = 0, 2 do
            local quad = love.graphics.newQuad(
                col * tileW, row * tileH,
                tileW, tileH,
                canvasW, canvasH
            )
            self.quads[row * 3 + col + 1] = quad
        end
    end
end

function Platform:update(dt)
    if self.type == Platform.TYPES.MOVING then
        local progress = (math.sin(love.timer.getTime() * (self.moveSpeed / 50)) + 1) / 2
        if self.horizontal then
            self.x = self.startX + (progress - 0.5) * 2 * self.moveRange
        else
            self.y = self.startY + (progress - 0.5) * 2 * self.moveRange
        end
    end
end

function Platform:draw()
    if not self.image then
        self:generateTileGraphics()
    end

    love.graphics.setColor(1, 1, 1, 1)

    local tileW = Platform.TILE_SIZE
    local tileH = Platform.TILE_SIZE
    local tilesX = math.ceil(self.width / tileW)
    local tilesY = math.ceil(self.height / tileH)

    for row = 0, tilesY - 1 do
        for col = 0, tilesX - 1 do
            local destX = self.x + col * tileW
            local destY = self.y + row * tileH
            local srcCol = col % 3
            local srcRow = row % 3
            local quad = self.quads[srcRow * 3 + srcCol + 1]
            love.graphics.draw(self.image, quad, destX, destY)
        end
    end
end

function Platform:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        left = self.x,
        right = self.x + self.width,
        top = self.y,
        bottom = self.y + self.height
    }
end

function Platform:collidesWith(entity)
    local bounds = self:getBounds()
    return entity.x < bounds.right and
           entity.x + entity.width > bounds.left and
           entity.y < bounds.bottom and
           entity.y + entity.height > bounds.top
end

return Platform
