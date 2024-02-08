# Better Victory Screen

[![shield](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white)](https://ko-fi.com/stringweasel) [![shield](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fbetter-victory-screen)](https://mods.factorio.com/mod/better-victory-screen) [![shield](https://img.shields.io/badge/Crowdin-Translate-brightgreen)](https://crowdin.com/project/factorio-mods-localization)

A better victory screen that places the focus on automation, and not combat.

If enabled in settings you can view the victory screen at any time by typing the command `/show-victory-screen`. This is disabled by default.

# Compatibility

**Compatible overhauls**:

- [248k](https://mods.factorio.com/mod/248k)
- [5Dims](https://mods.factorio.com/user/McGuten)
- [Bob's](https://mods.factorio.com/user/Bobingabout) and [Angel's](https://mods.factorio.com/user/Arch666Angel) 
- [Exotic Industries](https://mods.factorio.com/mod/exotic-industries)
- [Freight Forwarding](https://mods.factorio.com/mod/FreightForwarding)
- [Industrial Revolution 3](https://mods.factorio.com/mod/IndustrialRevolution3)
- [Mining Space Industries (MSI) II](https://mods.factorio.com/mod/Mining-Space-Industries-II)
- [Nullius](https://mods.factorio.com/mod/nullius)
- [Omni](https://mods.factorio.com/user/OmnissiahZelos)
- [Pyanodons](https://mods.factorio.com/user/pyanodon)
- [SeaBlock](https://mods.factorio.com/mod/SeaBlock)
- [Space Exploration](https://mods.factorio.com/mod/space-exploration) (works with [Krastorio 2](https://mods.factorio.com/mod/Krastorio2))
- [Space Extension Mod](https://mods.factorio.com/mod/SpaceMod), and this [fork](https://mods.factorio.com/mod/SpaceModFeorasFork).
- [Ultracube: Age of Cube](https://mods.factorio.com/mod/Ultracube)
- [Warptorio 2](https://mods.factorio.com/mod/warptorio2)
- [Warp Drive Machine](https://mods.factorio.com/mod/Warp-Drive-Machine/downloads)

**Soft-Compatible overhauls**:

These mods are safe to be installed to without any side-effects to track your statistics (like distance walked) until the mod is fully supported. However, the vanilla victory screen will still be shown on victory (except possibly when combining it with a fully compatible mod).

- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
- [Satisfactorio](https://mods.factorio.com/mod/Satisfactorio)

**Incompatible overhauls:**

Mods that are not listed already, that change the victory condition, are not compatible, and might cause unintended behaviour when installed. For example, still showing the victory screen erroneously on the first rocket launch, instead of during actual victory condition.

If you come across such a mod it's best to ask the author to add official compatibility. You can also request that Better Victory Screen adds a soft compatibility for it in the meantime in the [Discussion](https://mods.factorio.com/mod/better-victory-screen/discussion`).

**Note to mod developers:**

Any mods that change the game's victory condition will require explicit compatibility. If you want to add compatibility to your mod you can read how to [here](https://github.com/heinwessels/factorio-better-victory-screen/blob/main/mod-page/compatibility.md). 

Additionally, any mod can also add its statistics to the GUI, or remove existing entries.

# Caveats:
- Some statistics (like "distance walked") will only be accurate if mod is added at the start of a save file.
- Finish button is not functional due to modding API limitations.

# Credits
- [_CodeGreen](https://mods.factorio.com/user/_CodeGreen) for creating the foundation this mod is built upon.
- [Therenas](https://mods.factorio.com/mod/factoryplanner) for the code to create a semi-transparent backdrop.
- [Shadow_man](https://mods.factorio.com/user/Shadow_Man) for initial Russian translation. 
- _justarandomgeek_ for the [Factorio Modding Toolkit](https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug), without which this mod would not have been possible.