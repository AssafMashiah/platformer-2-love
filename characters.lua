local Characters = {}

Characters.list = {
    {
        name = "Runner",
        description = "Blazing speed but lower jumps",
        speed = 350,
        jumpForce = 500,
        color = {0.2, 0.9, 0.3},
        grip = 0.85,
        maxJumps = 2,
        width = 28,
        height = 32
    },
    {
        name = "Jumper",
        description = "Leaps high, moderate pace",
        speed = 230,
        jumpForce = 750,
        color = {0.95, 0.9, 0.2},
        grip = 0.75,
        maxJumps = 3,
        width = 30,
        height = 30
    },
    {
        name = "Tank",
        description = "Slow but stops on a dime",
        speed = 180,
        jumpForce = 550,
        color = {0.9, 0.25, 0.2},
        grip = 1.0,
        maxJumps = 2,
        width = 38,
        height = 36
    },
    {
        name = "Slider",
        description = "Smooth operator, icy feet",
        speed = 270,
        jumpForce = 580,
        color = {0.2, 0.85, 0.95},
        grip = 0.3,
        maxJumps = 2,
        width = 32,
        height = 32
    },
    {
        name = "Ninja",
        description = "Fast and agile, hard to control",
        speed = 320,
        jumpForce = 700,
        color = {0.7, 0.25, 0.9},
        grip = 0.5,
        maxJumps = 3,
        width = 28,
        height = 28
    },
    {
        name = "Steady",
        description = "Balanced all-rounder",
        speed = 250,
        jumpForce = 600,
        color = {0.95, 0.6, 0.2},
        grip = 0.9,
        maxJumps = 2,
        width = 32,
        height = 32
    }
}

function Characters:get(index)
    return self.list[index]
end

function Characters:count()
    return #self.list
end

function Characters:applyToPlayer(index, player)
    local char = self.list[index]
    if not char then return end

    player.speed = char.speed
    player.jumpForce = char.jumpForce
    player.maxJumps = char.maxJumps
    player.jumpsRemaining = char.maxJumps
    player.width = char.width
    player.height = char.height
    player.grip = char.grip
    player.characterIndex = index
    player.characterColor = {char.color[1], char.color[2], char.color[3]}
end

return Characters
