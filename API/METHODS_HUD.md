## HUD Methods
Helper methods that can be used when displaying client-side UIs

**HUD:PaintBar(r, x, y, w, h, colors, value)** - Paints a rounded bar that is some-percentaged filled. Can be used as a progress bar.\
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

**HUD:PaintPowersHUD(powers, max_power, current_power, colors, title, subtitle)** - Paints a HUD for showing available powers and their associated costs. Used for roles such as the Phantom.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *powers* - Table of key-value pairs where each key is the label for a power and the associated value is the cost of using it. The key can contain a `{num}` placeholder which will be replaced with the percentage of maximum power that the power costs
- *max_power* - The maximum amount of a power a player can have
- *current_power* - The current amount of power a player has
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the powers
  - *background* - The background color of the progress bar used to show power level percentage
  - *fill* - The color to use for the current power level in the progress bar
- *title* - Title text to show within the power level progress bar
- *subtitle* - The sub-title text, used for hints, that is shown in small text above the power level progress bar

**HUD:ShadowedText(text, font, x, y, color, xalign, yalign)** - Renders text with an offset black background to emulate a shadow.\
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