# Better Victory Screen

[![shield](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white)](https://ko-fi.com/stringweasel) [![shield](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fbetter-victory-screen)](https://mods.factorio.com/mod/better-victory-screen)

A better victory screen that places the focus on automation, and not combat.

You can view the victory screen at any time by typing the command `/show-victory-screen`.

# Compatibility

Any mods that change the game's victory condition will require explicit compatibility. 

**List of compatible overhauls (might be incomplete)**:

- [248k](https://mods.factorio.com/mod/248k)
- [Bob's](https://mods.factorio.com/user/Bobingabout), [Angel's](https://mods.factorio.com/user/Arch666Angel), and [SeaBlock](https://mods.factorio.com/mod/SeaBlock). **But(!):** [SpaceMod](https://mods.factorio.com/mod/SpaceMod) is not yet supported! This [fork](https://mods.factorio.com/mod/SpaceModFeorasFork) by Feoras is supported.
- [Exotic Industries](https://mods.factorio.com/mod/exotic-industries)
- [Freight Forwarding](https://mods.factorio.com/mod/FreightForwarding)
- [Industrial Revolution 3](https://mods.factorio.com/mod/IndustrialRevolution3)
- [Nullius](https://mods.factorio.com/mod/nullius)
- [Pyanodons](https://mods.factorio.com/user/pyanodon)
- [Ultracube: Age of Cube](https://mods.factorio.com/mod/Ultracube)

**List of popular INCOMPATIBLE overhauls (list is definitely incomplete)**:

- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
- [Space Exploration](https://mods.factorio.com/mod/space-exploration)
- [Space Extension Mod](https://mods.factorio.com/mod/SpaceMod)
- [Mining Space Industries (MSI) II](https://mods.factorio.com/mod/Mining-Space-Industries-II)

If the mod is marked compatible, but is combined with another overhaul that's incompatible, then the shown victory screen might still be unchanged, or the custom victory screen will be shown on the first rocket launch by accident. However, it should not prevent you from finishing the game normally as well.

**Note to mod developers:** If you want to add compatibility to your mod you can read how to [here](https://github.com/heinwessels/factorio-better-victory-screen/blob/main/mod-page/compatibility.md). It also allows you add your own statistics to the GUI, or remove existing entries.

# Caveats:
- Some statistics (like "distance walked") will only be accurate if mod is added at the start of a save file.
- Finish button is not functional due to modding API limitations.

# Credits
- [_CodeGreen](https://mods.factorio.com/user/_CodeGreen) for creating the foundation this mod is built upon.
- [Therenas](https://mods.factorio.com/mod/factoryplanner) for the code to create a semi-transparent backdrop.
- [Shadow_man](https://mods.factorio.com/user/Shadow_Man) for initial Russian translation. 
- _justarandomgeek_ for the [Factorio Modding Toolkit](https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug), without which this mod would not have been possible.