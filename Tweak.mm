#import <substrate.h>
#import <CoreText/CoreText.h>

CFIndex (*orig_CTRunGetGlyphCount)(CTRunRef run);
CFIndex replaced_CTRunGetGlyphCount(CTRunRef run)
{
    CFIndex ret = orig_CTRunGetGlyphCount(run);
    if ((int)ret < 0)
    {
        return (CFIndex)0;
    }
    
    return ret;
}

__attribute__((constructor)) static void __GlyphPatch()
{
    MSHookFunction((void*)CTRunGetGlyphCount,
                   (void*)replaced_CTRunGetGlyphCount,
                   (void**)&orig_CTRunGetGlyphCount);
}