### Background 

#### Part 1

As explained in the `characterRangeCodePath()` implementation in `Font.cpp`, the range from `U+0600` through `U+109F` includes Arabic characters, among others.

If one of our characters is in that range, we override the original function to return Auto instead of Complex, from the CodePath enum.

This makes `Font::drawText()` to call `Font::drawSimpleText()` instead of `Font::drawComplexText()`: this function (implemented in `WebKit/Source/WebCore/platform/graphics/FontFastPath.cpp`),
calls `Font::getGlyphsAndAdvancesForSimpleText()` to work and advance with the GlyphBuffer.

On the other end, the original return value of the function would have required `Font::drawText()` to call `Font::drawComplexText()`, which needs to call `Font::getGlyphsAndAdvancesForComplexText()`.

This last function makes use of a `ComplexTextController` object: the bug resides in the `ComplexTextController::adjustGlyphsAndAdvances()` function, which is called in the initialization of ComplexTextController. (`ComplexTextController::ComplexTextController(const Font*, const TextRun&, bool, HashSet<const SimpleFontData*>*, bool)`)



#### Part 2

Ok, so while the "new approach" described above was a better solution than the first one, it actually made Arabic characters look weird (larger).

That was caused by the fact that the new "rendering path" followed by WebCore was not actually meant for that range of characters and did not include all the details required to rendered that set properly.

The only way this could be avoided was to isolate the malicious character sequence and hijack the rendering path only in that case. This is exactly what I'm doing now.

The following code can be read as follows: "render everything as normal, except if the sequence of characters is the malicious one".