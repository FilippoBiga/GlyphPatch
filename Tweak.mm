#import <substrate.h>
#import <unicode/uchar.h>

// As defined in WebKit/Source/WebCore/platform/graphics/Font.h
enum CodePath {
    Auto,
    Simple,
    Complex,
    SimpleWithGlyphOverflow
};

static const UChar sequence[] = { 0x20, 0x337, 0x334, 0x310 };

// Font::CodePath Font::characterRangeCodePath(const UChar* characters, unsigned len)
// (WebKit/Source/WebCore/platform/graphics/Font.cpp)
static CodePath (*$ZN7WebCore4Font22characterRangeCodePathEPKtj)(const UChar*, unsigned len);

static CodePath (*orig_ZN7WebCore4Font22characterRangeCodePathEPKtj)(const UChar*, unsigned len);

static CodePath patched_ZN7WebCore4Font22characterRangeCodePathEPKtj(const UChar *characters, unsigned len)
{
    for (unsigned i = 0; i < len; i++)
    {
        const UChar c  = characters[i];
        if ((c >= 0x300 && c <= 0x36F) ||   // Combining diacritics
            (c >= 0x0600 && c <= 0x109F))   // Arabic (and other) characters
        {
            for (unsigned j = 0; (len - j) >= (sizeof(sequence)/sizeof(UChar)); j++)
            {
                if (memcmp(&characters[j], sequence, sizeof(sequence)) == 0)
                {
                    return Auto;
                }
            }
        }
    }
    
    return orig_ZN7WebCore4Font22characterRangeCodePathEPKtj(characters, len);
}

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