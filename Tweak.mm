#import <substrate.h>

void (*$ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv)();
static void (*orig_ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv)();

static void nop_ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv()
{
    /*
     I still haven't found a way to determine whether we're safe to call
     the original function or not. :(
     
     For now, let's just NOP this in order to avoid the crash.
     I can confirm it does not affect 'normal web browsing'.
     
     Forgive me, I hope to fix this sooner or later.
     
     */
}


// From http://svn.saurik.com/repos/menes/trunk/tweaks/test/Tweak.mm
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
    
    nl[0].n_un.n_name = (char *) "__ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv";
    if (nlist("/System/Library/PrivateFrameworks/WebCore.framework/WebCore", nl) >= 0 &&
        nl[0].n_type != N_UNDF)
    {
        nlset($ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv, nl, 0);
        MSHookFunction((void *)$ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv,
                       (void *)nop_ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv,
                       (void **)&orig_ZN7WebCore21ComplexTextController23adjustGlyphsAndAdvancesEv);
    }
}