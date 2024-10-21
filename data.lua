require("prototypes.styles")

local has_spaceage = mods["space-age"] ~= nil

data:extend{
    {
        type = "sprite",
        name = "bvs-victory-sprite",
        filename = "__base__/scenarios/freeplay/victory"..(has_spaceage and "-space-age" or "")..".png",
        priority = "extra-high-no-scale",
        width = 400,
        height = 600,
    }
}