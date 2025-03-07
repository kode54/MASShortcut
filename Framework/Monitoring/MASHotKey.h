#if __has_include(<MASShortcut/MASShortcut.h>)
#    import <MASShortcut/MASShortcut.h>
#else
#    import "MASShortcut.h"
#endif

extern FourCharCode const MASHotKeySignature;

@interface MASHotKey : NSObject

@property(readonly) UInt32 carbonID;
@property(copy) dispatch_block_t action;

+ (instancetype) registeredHotKeyWithShortcut: (MASShortcut*) shortcut;

@end
