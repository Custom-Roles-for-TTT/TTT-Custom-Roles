# HUD Methods
Helper methods that can be used when displaying client-side UIs

### CRHUD:PaintBar(r, x, y, w, h, colors, value)
Paints a rounded bar that is some-percentaged filled. Can be used as a progress bar.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *r* - The amount the bar should be rounded
- *x* - The position from the left of the screen
- *y* - The position from the top of the screen
- *w* - The width of the bar
- *h* - The height of the bar
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the bar
  - *background* - The background color of the bar
  - *fill* - The color to use to show the percentage of the bar filled
- *value* - The percent of the bar to be filled

### CRHUD:PaintPowersHUD(client, powers, max_power, current_power, colors, title)
Paints a HUD for showing available powers and their associated costs. Used for roles such as the Phantom.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The client player
- *powers* - A sequential table of objects containing information about each ability
  - *name* - The name of this ability
  - *key* - The key that is used for the icon of this ability. If a single character is provided (e.g. "W"), then that character will be used as the icon for this ability. If more than one character is provided (e.g. "tab"), then a .vmt file with that name must exist in "vgui/ttt/keys" to be used as the icon
  - *cost* - The amount of power required to use this ability
  - *desc* - The description of this ability
- *max_power* - The maximum amount of a power a player can have
- *current_power* - The current amount of power a player has
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the powers
  - *background* - The background color of the progress bar used to show power level percentage
  - *fill* - The color to use for the current power level in the progress bar
- *title* - Title text to show within the power level progress bar

*NOTE:* Prior to version 2.2.1 the following parameters were used instead:
- *powers* - Table of key-value pairs where each key is the label for a power and the associated value is the cost of using it. The key can contain a `{num}` placeholder which will be replaced with the percentage of maximum power that the power costs
- *max_power* - The maximum amount of a power a player can have
- *current_power* - The current amount of power a player has
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the powers
  - *background* - The background color of the progress bar used to show power level percentage
  - *fill* - The color to use for the current power level in the progress bar
- *title* - Title text to show within the power level progress bar
- *subtitle* - The sub-title text, used for hints, that is shown in small text above the power level progress bar

### CRHUD:PaintProgressBar(x, y, w, color, heading, progress, segments, titles, m)
Paints a HUD for showing a progress bar, optionally divided into multiple segments\
*Realm:* Client\
*Added in:* 1.6.19\
*Parameters:*
- *x* - The position of the centre of the progress bar from the left of the screen
- *y* - The position from the top of the screen
- *w* - The width of the progress bar
- *color* - The [Color](https://wiki.facepunch.com/gmod/Color) of the progress bar
- *heading* - The heading to be displayed above the progress bar (Defaults to "")
- *progress* - The progress the bar should display as a value from 0 to 1 (Defaults to 1)
- *segments* - The number of segments the progress bar should have (Defaults to 1)
- *titles* - A table of strings containing the titles for each segment. Must have length equal to the number of segments. Ignored if segments is equal to 1 (Defaults to {})
- *m* - The margin between each segment (Defaults to 10)

### CRHUD:PaintSpectatorProgressBar(max_value, current_value, colors, title, subtitle)
Paints a HUD for showing a progress bar to spectators, similar to that shown when possessing a prop\
*Realm:* Client\
*Added in:* 2.2.1\
*Parameters:*
- *max_value* - The maximum value for the progress bar
- *current_value* - The current value of the progress bar
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used for the progress bar
  - *background* - The background color of the progress bar
  - *fill* - The color to use for the current level of the progress bar
- *title* - Title text to show within the progress bar
- *subtitle* - The sub-title text, used for hints, that is shown in small text above the progress bar

### CRHUD:PaintStatusEffect(shouldPaint, color, material, identifier)
Slightly tints the screen and paints floating particles on the bottom of the client's HUD.\
*Realm:* Client\
*Added in:* 1.8.3\
*Parameters:*
- *shouldPaint* - Whether the status effect should be painted or not. (*Note*: Whenever you are not painting a status effect you should still call this method with shouldPaint as `false` so that the effect properly fades in and out)
- *color* - The [Color](https://wiki.facepunch.com/gmod/Color) of the effect
- *material* - The [Material](https://wiki.facepunch.com/gmod/Global.Material) to use for the particle effects
- *identifier* - A string that is a unique identifier for this status effect 

### CRHUD:ShadowedText(text, font, x, y, color, xalign, yalign)
Renders text with an offset black background to emulate a shadow.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *text* - The text to render
- *font* - The name of the font to use
- *x* - The position from the left of the screen
- *y* - The position from the top of the screen
- *color* - The color to use for the rendered text
- *xalign* - The [TEXT_ALIGN](https://wiki.facepunch.com/gmod/Enums/TEXT_ALIGN) enum value to use for the horizontal alignment of the text
- *yalign* - The [TEXT_ALIGN](https://wiki.facepunch.com/gmod/Enums/TEXT_ALIGN) enum value to use for the vertical alignment of the text
