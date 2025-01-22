# Better Victory Screen

[![shield](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white)](https://ko-fi.com/stringweasel) [![shield](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fbetter-victory-screen)](https://mods.factorio.com/mod/better-victory-screen) [![shield](https://img.shields.io/badge/Crowdin-Translate-brightgreen)](https://crowdin.com/project/factorio-mods-localization)

Upon victory it shows various interesting game statistics, like the total amount of time you spent hand crafting and your peak power production. Can safely be added to an existing save.

# Compatibility

All mods should be automatically compatible. Please let me know if you find a mod that isn't.

Additionally, any mod can also add custom statistics to the GUI, or remove existing entries. [More information...](https://github.com/heinwessels/factorio-better-victory-screen/blob/main/mod-page/compatibility.md)

# Caveats:
- One or two statistics (like "distance walked") will only be accurate if mod is added at the start of a save file.
- Some shown statistics are only estimates.
- The player specific information is only shown if there's only one player connected at the time of victory due to API limitations.
- In PvP games there's a small chance the wrong force's statistics is shown due to API limitations.

# Credits
- [_CodeGreen](https://mods.factorio.com/user/_CodeGreen) for creating the GUI styling and initial concepts.
- [Therenas](https://mods.factorio.com/mod/factoryplanner) for the code to create a semi-transparent backdrop.
- [Shadow_man](https://mods.factorio.com/user/Shadow_Man) for initial Russian translation. 
- _justarandomgeek_ for the [Factorio Modding Toolkit](https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug), without which this mod would not have been possible.