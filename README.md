A collection of mods made by me for Balatro.
# Bmwallet:Add a special area to the game to store various cards and achieve a large number of functions.
The wallet uses a drag and drop display structure similar to the official mobile app (that is, when a card is dragged, some areas will be displayed, and when you place the card on a highlighted area, the corresponding function will be executed on the card), and also uses a special mobile card mode. For example, you can drag a consumable card to the wallet, and then the card will be removed from the consumable slot and added to the wallet, and vice versa. All the following modules are built on these two methods. Unless otherwise specified, the first method is only used by default.
## The following are the basic functions of the wallet, which are also the foundation of other powerful modules.
The wallet is an independent area similar to the Joker slot and the Consumables slot, with the wallet and Joker slot overlapping in position. With a button, you can switch between displaying the wallet and Joker slot at any time. Joker cards, consumable cards, game cards and even booster packs can be put into the wallet and retrieved at any time (game cards have a special requirement: they can only be retrieved with cards in hand). The following modules are the basic modules for implementing hide and restore.
- Hide:If there is an empty space in the wallet, the card will be put into the wallet (For this module, Joker cards can only be used in the first way, while Consumable cards, Game cards and Booster packs can only be used in the second way) (For booster packs, this module is called Preorder. The booster packs in the wallet can be payment and open in any state).
- Restore:If there is an empty space in the original area of this card, the card will be returned to its original area (For this module, Joker cards can only be used in the first way, and both the first and second ways of consumable cards, game cards and booster packs can be used).
## The following modules are powerful modules that can only be used when the card is in the wallet.
The following modules can only be used in a store by dragging a card in the wallet. The modules that can be used vary according to the types of cards. Note that if the basic requirements for using a module are not met (for example, insufficient funds), the module will not be displayed.
- Recycle:Spend $2, return the card to the shop, and receive a card with the same rarity as the card returned to the shop. The starting cost is $2, and the cost will be increased by an additional $1 each time it is used. The cost will be reset in the next round (Joker only).
- Maintenance:Repair the perishable state of the card to its optimal level. If the card has been weakened, remove the weakened state caused by the perishable sticker. Each round of use incurs a repair cost of $3 (Joker only).
- Package:Spend $3, remove this card, and increase the packaging progress by one. If the packaging progress is full, create a corresponding jumbo or mega booster based on the type of card removed last. The starting cost is $3, and each successfully crafted booster pack increases the cost by $1. The cost will be reset in the next round (Joker or Consumable only).
- Print:Print a edition for the card, the order is Foil, Holo, polychrome, Negative. If the card already has a edition, print the next edition in the order mentioned above. The printing price of each edition is twice that of the previous one in the above order, and the printing price of Foil is $25. The Game cards cannot be printed with negative (Joker or Game card only).
- Forge:If the forge is successful, the forge level of the card will be increased, and a random quality forge gain will be added to the card: blue quality +25 chips, red quality +5 mult, gold quality +X0.5 mult, the higher the quality, the lower the probability. If forge fails, it will lower the forge level of the card, but it will not reduce the forge gain of the card that has already been added. The higher the forge level of the card, the lower the forge success rate and the higher the forge cost (Game card only).
- Practice:Spend $400, improve the cultivation level of the card (Joker only). (This module has a unique secondary module for batch use, which can be used in four levels: once, one fourth, half and all in, thereby improving the efficiency of the module and reducing a large number of repetitive mechanical operations.) (Need a pre installed Bmjokers mod. If it is not loaded, this module will not appear.)
- Stamp:Spend $15, stamp a random seal on the card (Game card only).
## The following are the basic functions of the new shop added to the wallet, which are also the basis of its ancillary modules.
In addition to the wallet being an independent area, a new shop has been added that is closely related to the old shop. It is more special and has more functions than the old shop. The old shop can deposit goods into the new shop and retrieve them when needed (such as single cards, booster packs or vouchers). The new shop will supply some goods that are limited to purchase in the old shop (such as booster packs and vouchers) and special goods that are unique to the new shop. One thing to note is that the new shop will not supply goods automatically (even if you beat the blinds and go to the next round), and you will need to pay a certain fee for each supply. The following modules are the basic modules for using the new shop. Our friend Jimbo will be waiting for you in the new shop!
- Deposit:If there is an empty space in the new shop, Spend $1 and the good will be temporarily deposit in the new shop (For this module, all types of goods can only be used in the first way).
- Retrieve:Regardless of whether there is an empty space or not in the original area of this good in the original shop, the good will be returned to its original area (For this module, all types of goods can only be used in the first way).
## The following modules are physical modules with buttons, which are used to assist in operated new shop.
The following modules are fixed modules, similar to the original shop's reroll button. Except for differences in function and usage conditions, the other properties are basically the same.
- Stock:Spend $6 to supply 4 goods to the new shop. The types of goods include: vouchers (1%), booster packs (4%), tags (90%), and Boss bottle caps (5%). If there are deposited goods in the new shop before supply, they will be retrieved to the old shop. The starting cost is $6, and the cost will be increased by an additional $2 each time it is used. The cost will be reset in the next round (If you buy vouchers or booster packs, you don’t need to pay the fee immediately, they will be added to the old shop and wait for payment. If you buy tags or Boss bottle caps, you will pay immediately) (Boss bottle caps will be added to your wallet after payment. If you sell them in the select blind state, the Boss blind will be replaced with the same as the Boss bottle cap).
- Kickback:Spend 1 kickback, make the specified good free. If no good was specified or the specified good is already free, produce a double tag. At the start of each game you will receive a kickback (There is a small chance of getting a kickback every time you spend in the new shop).
# Note that [Steamodded](https://github.com/Steamopollys/Steamodded) is required to load the mods.
The mods are written and tested on Steamodded 1.0.0. There was code for 0.9.8 compatibility but since most people are shifting to SMOD 1.0.0 and SMOD 1.0.0 supports 0.9.8 mods now, I won't check 0.9.8 compatibility very frequently and can't promise its compatibility.
