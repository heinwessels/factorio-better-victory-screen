## The rocket launch triggered the victory screen when it shouldn't for this overhaul?

If the overhaul you're playing has a custom victory condition then it needs explicit compatibility to work with Better Victory Screen. If there is no compatibility added then Better Victory Screen will assume it's an vanilla-ish run, and show the victory screen after the first rocket launch.

Your possible steps forward:
- You can continue playing as normal and keep Better Victory Screen installed. If you remove it you will lose some information like distance walked, time spent handcrafting, etc.
- In order to see the Better Victory Screen you'll have to request for the mod your playing to be made compatible with Better Victory Screen. This can best be done on both mods' preferred place of discussion, for example their mod pages.
- If compatibility is added to the other mod at some later point, then no further action is required, and you can continue playing as per normal. Better Victory Screen should detect automatically that new support was added. This can be verified in the [log file](https://wiki.factorio.com/Log_file). You can also force this reset by using the command 
- If there's no hope of compatibility being added then you can safely uninstall Better Victory Screen. It will not affect the rest of your play-through.

If you want to make sure you can still trigger the victory you can check with `/is-victory-pending`.

## Some statistics are zero when I expect it to have some value

Some statistics, like distance walked, is only tracked while Better Victory Screen is active. So if this mod is added just before victory then some values might be zero. Some values should always be correct, like the total amount of transport belts. If these values are zero, when they shouldn't be, then it might be a bug, and can be reported on the mod-page. The code is written to attempt to show zero instead of crashing. It will be useful if you provide a save-file with your bug report.