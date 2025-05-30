#if __has_include(<MASShortcut/MASShortcut.h>)
#    import <MASShortcut/MASShortcut.h>
#else
#    import "MASShortcut.h"
#endif

/**
 Executes action when a shortcut is pressed.

 There can only be one instance of this class, otherwise things
 will probably not work. (There’s a Carbon event handler inside
 and there can only be one Carbon event handler of a given type.)
*/
@interface MASShortcutMonitor : NSObject

- (instancetype) init __unavailable;
+ (instancetype) sharedMonitor;

/**
 Register a shortcut along with an action.

 Attempting to insert an already registered shortcut probably won’t work.
 It may burn your house or cut your fingers. You have been warned.
*/
- (BOOL) registerShortcut: (MASShortcut*) shortcut withAction: (dispatch_block_t) action;
- (BOOL) isShortcutRegistered: (MASShortcut*) shortcut;

- (void) unregisterShortcut: (MASShortcut*) shortcut;
- (void) unregisterAllShortcuts;

@end
