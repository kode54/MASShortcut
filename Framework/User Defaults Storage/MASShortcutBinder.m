#if __has_include(<MASShortcut/MASShortcut.h>)
#    import <MASShortcut/MASShortcut.h>
#else
#    import "MASShortcut.h"
#endif
#if __has_include(<MASShortcut/MASShortcutBinder.h>)
#    import <MASShortcut/MASShortcutBinder.h>
#else
#    import "MASShortcutBinder.h"
#endif
#if __has_include(<MASShortcut/MASDictionaryTransformer.h>)
#    import <MASShortcut/MASDictionaryTransformer.h>
#else
#    import "MASDictionaryTransformer.h"
#endif

@interface MASShortcutBinder ()
@property(strong) NSMutableDictionary *actions;
@property(strong) NSMutableDictionary *shortcuts;
@end

@implementation MASShortcutBinder

#pragma mark Initialization

+ (void) initialize
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSValueTransformer *transformer = [MASDictionaryTransformer new];
        [NSValueTransformer setValueTransformer:transformer
                                        forName:MASDictionaryTransformerName];
    });
}

- (id) init
{
    self = [super init];
    [self setActions:[NSMutableDictionary dictionary]];
    [self setShortcuts:[NSMutableDictionary dictionary]];
    [self setShortcutMonitor:[MASShortcutMonitor sharedMonitor]];
    [self setBindingOptions:@{NSValueTransformerBindingOption: [NSValueTransformer valueTransformerForName:MASDictionaryTransformerName]}];
    return self;
}

- (void) dealloc
{
    for (NSString *bindingName in [_actions allKeys]) {
        [self unbind:bindingName];
    }
}

+ (instancetype) sharedBinder
{
    static dispatch_once_t once;
    static MASShortcutBinder *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

#pragma mark Registration

- (void) bindShortcutWithDefaultsKey: (NSString*) defaultsKeyName toAction: (dispatch_block_t) action
{
    NSAssert([defaultsKeyName rangeOfString:@"."].location == NSNotFound,
        @"Illegal character in binding name (“.”), please see http://git.io/x5YS.");
    NSAssert([defaultsKeyName rangeOfString:@" "].location == NSNotFound,
        @"Illegal character in binding name (“ ”), please see http://git.io/x5YS.");
    [_actions setObject:[action copy] forKey:defaultsKeyName];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:defaultsKeyName] options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:kMASShortcutBinderContext];
}

- (void) breakBindingWithDefaultsKey: (NSString*) defaultsKeyName
{
    [_shortcutMonitor unregisterShortcut:[_shortcuts objectForKey:defaultsKeyName]];
    [_shortcuts removeObjectForKey:defaultsKeyName];
    [_actions removeObjectForKey:defaultsKeyName];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:defaultsKeyName] context:kMASShortcutBinderContext];
}

- (void) registerDefaultShortcuts: (NSDictionary*) defaultShortcuts
{
    NSValueTransformer *transformer = [_bindingOptions valueForKey:NSValueTransformerBindingOption];
    if (transformer == nil) {
        NSString *transformerName = [_bindingOptions valueForKey:NSValueTransformerNameBindingOption];
        if (transformerName) {
            transformer = [NSValueTransformer valueTransformerForName:transformerName];
        }
    }

    NSAssert(transformer != nil, @"Can’t register default shortcuts without a transformer.");

    [defaultShortcuts enumerateKeysAndObjectsUsingBlock:^(NSString *defaultsKey, MASShortcut *shortcut, BOOL *stop) {
        id value = [transformer reverseTransformedValue:shortcut];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{defaultsKey:value}];
    }];
}

#pragma mark Old fashioned KVO

// Sorry, self bind: seems too unstable for this

static void * kMASShortcutBinderContext = &kMASShortcutBinderContext;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != kMASShortcutBinderContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if([[keyPath substringToIndex:7] isEqualToString:@"values."]) {
        NSString *defaultsKeyName = [keyPath stringByReplacingOccurrencesOfString:@"values." withString:@""];

        if([self isRegisteredAction:defaultsKeyName]) {
            NSValueTransformer *transformer = [_bindingOptions valueForKey:NSValueTransformerBindingOption];
            if (transformer == nil) {
                NSString *transformerName = [_bindingOptions valueForKey:NSValueTransformerNameBindingOption];
                if (transformerName) {
                    transformer = [NSValueTransformer valueTransformerForName:transformerName];
                }
            }

            NSAssert(transformer != nil, @"Can’t observe shortcuts without a transformer.");

            id value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:defaultsKeyName];
            MASShortcut *shortcut = [transformer transformedValue:value];

            [self setValue:shortcut forKey:defaultsKeyName];
        }
    }
}

#pragma mark Bindings

- (BOOL) isRegisteredAction: (NSString*) name
{
    return !![_actions objectForKey:name];
}

- (id) valueForUndefinedKey: (NSString*) key
{
    return [self isRegisteredAction:key] ?
        [_shortcuts objectForKey:key] :
        [super valueForUndefinedKey:key];
}

- (void) setValue: (id) value forUndefinedKey: (NSString*) key
{
    if (![self isRegisteredAction:key]) {
        [super setValue:value forUndefinedKey:key];
        return;
    }

    MASShortcut *newShortcut = value;
    MASShortcut *currentShortcut = [_shortcuts objectForKey:key];

    // Unbind previous shortcut if any
    if (currentShortcut != nil) {
        [_shortcutMonitor unregisterShortcut:currentShortcut];
    }

    // Just deleting the old shortcut
    if (newShortcut == nil) {
        [_shortcuts removeObjectForKey:key];
        return;
    }

    // Bind new shortcut
    [_shortcuts setObject:newShortcut forKey:key];
    [_shortcutMonitor registerShortcut:newShortcut withAction:[_actions objectForKey:key]];
}

@end
