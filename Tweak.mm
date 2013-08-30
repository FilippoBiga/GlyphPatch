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

// malicious character sequence
static const UChar sequence[] = {
    
    0x633, 0x645, 0x64e, 0x640, 0x64e, 0x651, 0x648, 0x64f,
    0x648, 0x64f, 0x62d, 0x62e, 0x20,  0x337, 0x334, 0x310,
    0x62e, 0x20,  0x337, 0x334, 0x310, 0x62e, 0x20, 0x337,
    0x334, 0x310, 0x62e, 0x20,  0x627, 0x645, 0x627, 0x631,
    0x62a, 0x64a, 0x62e, 0x20,  0x337, 0x334, 0x310, 0x62e
};

static CodePath patched_ZN7WebCore4Font22characterRangeCodePathEPKtj(const UChar *characters, unsigned len)
{
    for (unsigned i = 0; i < len; i++)
    {
        const UChar c  = characters[i];
        
        if (c >= 0x0600 && c <= 0x109F) // U+0600 -> U+109F
        {
            if (sizeof(sequence) / sizeof(UChar) <= len &&
                memcmp(characters, sequence, sizeof(sequence)) == 0)
            {
                return Auto;
            }
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