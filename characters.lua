Characters = {
    {
        id = 1,
        name = "Turbo",
        color = {0.18, 0.53, 0.67},
        speed = 250,
        jumpForce = 400,
        grip = 1.0,
        description = "Balanced all-rounder"
    },
    {
        id = 2,
        name = "Speedy",
        color = {0.18, 0.80, 0.44},
        speed = 350,
        jumpForce = 350,
        grip = 0.8,
        description = "Fast but slippery"
    },
    {
        id = 3,
        name = "Jumpy",
        color = {0.95, 0.77, 0.06},
        speed = 180,
        jumpForce = 550,
        grip = 1.0,
        description = "Leaps for days"
    },
    {
        id = 4,
        name = "Ice King",
        color = {0, 0.83, 1},
        speed = 200,
        jumpForce = 380,
        grip = 0.4,
        description = "Slides on release"
    },
    {
        id = 5,
        name = "Tank",
        color = {0.91, 0.30, 0.24},
        speed = 150,
        jumpForce = 300,
        grip = 1.0,
        description = "Slow but steady"
    }
}

function Characters.getById(id)
    for _, char in ipairs(Characters) do
        if char.id == id then
            return char
        end
    end
    return Characters[1]
end

return Characters