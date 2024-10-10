require("prototypes.styles")


-- local is_spaceage = mods["space-age"] ~= nil

data:extend{
    {
        type = "sprite",
        name = "bvs-victory-sprite",
        filename = "__base__/scenarios/freeplay/victory.png", -- is_spaceage
        priority = "extra-high-no-scale",
        width = 400,
        height = 600,
    }
}