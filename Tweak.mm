#import <substrate.h>
#import <unicode/uchar.h>

// From http://svn.saurik.com/repos/menes/trunk/tweaks/test/Tweak.mm
// thanks, Saurik.
template <typename Type_>
static void nlset(Type_ &function, struct nlist *nl, size_t index) {
    struct nlist &name(nl[index]);
    uintptr_t value(name.n_value);
    if ((name.n_desc & N_ARM_THUMB_DEF) != 0)
        value |= 0x00000001;
    function = reinterpret_cast<Type_>(value);
}

// As defined in WebKit/Source/WebCore/platform/graphics/Font.h
enum CodePath {
    Auto,
    Simple,
    Complex,
    SimpleWithGlyphOverflow
};

// Font::CodePath Font::characterRangeCodePath(const UChar* characters, unsigned len)
// (WebKit/Source/WebCore/platform/graphics/Font.cpp)
static CodePath (*$ZN7WebCore4Font22characterRangeCodePathEPKtj)(const UChar*, unsigned len);

static CodePath (*orig_ZN7WebCore4Font22characterRangeCodePathEPKtj)(const UChar*, unsigned len);

static CodePath patched_ZN7WebCore4Font22characterRangeCodePathEPKtj(const UChar *characters, unsigned len)
{
    for (unsigned i = 0; i < len; i++)
    {
        const UChar c = characters[i];
        
        /*
         
         As explained in the characterRangeCodePath(...) implementation in Font.cpp,
         range from U+0600 through U+109F includes Arabic characters, among the others.
         
         If one of our characters is in that range, we override the original function
         to return Auto instead of Complex.
         
         This makes Font::drawText(...) to call Font::drawSimpleText(...) instead of Font::drawComplexText(...):
         this function (implemented in WebKit/Source/WebCore/platform/graphics/FontFastPath.cpp),
         calls Font::getGlyphsAndAdvancesForSimpleText(...) to work and advance with the GlyphBuffer.
         
         On the other end, the original return value of the function would have required
         Font::drawText(...) to call Font::drawComplexText(...), which needs to call
         Font::getGlyphsAndAdvancesForComplexText(...).
         
         This last function makes use of a ComplexTextController object: the bug resides in the ComplexTextController::adjustGlyphsAndAdvances()
         function, which is called in the initialization of ComplexTextController.
         (ComplexTextController::ComplexTextController(const Font*, const TextRun&, bool, HashSet<const SimpleFontData*>*, bool))
         
         In this way we're actually able to isolate the case of Arabic characters,
         which seems to render fine even with the new rendering behavior.
         
         */
        
        if (c >= 0x0600 && c <= 0x109F) // U+0600 -> U+109F
        {
            return Auto;
        }
    }
    
    return orig_ZN7WebCore4Font22characterRangeCodePathEPKtj(characters, len);
}


__attribute__((constructor)) static void __GlyphPatch()
{
    struct nlist nl[2];
    
    memset(nl, 0, sizeof(nl));
    nl[0].n_un.n_name = (char *) "__ZN7WebCore4Font22characterRangeCodePathEPKtj";
    if (nlist("/System/Library/PrivateFrameworks/WebCore.framework/WebCore", nl) >= 0 &&
        nl[0].n_type != N_UNDF)
    {
        nlset($ZN7WebCore4Font22characterRangeCodePathEPKtj, nl, 0);
        MSHookFunction((void *)$ZN7WebCore4Font22characterRangeCodePathEPKtj,
                       (void *)patched_ZN7WebCore4Font22characterRangeCodePathEPKtj,
                       (void **)&orig_ZN7WebCore4Font22characterRangeCodePathEPKtj);
    }
}