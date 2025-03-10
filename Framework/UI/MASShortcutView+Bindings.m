#import "MASShortcutView+Bindings.h"
#import "MASDictionaryTransformer.h"

@implementation MASShortcutView (Bindings)

static void * kMASShortcutViewBindingsContext = &kMASShortcutViewBindingsContext;

- (NSString*) associatedUserDefaultsKey
{
    return defaultsKey;
}

- (void) setAssociatedUserDefaultsKey: (NSString*) newKey withTransformer: (NSValueTransformer*) transformer
{
    // Break previous binding if the new binding is nil
    if(defaultsKey && [defaultsKey length]) {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:defaultsKey] context:kMASShortcutViewBindingsContext];
        defaultsKey = nil;
    }

    if (newKey == nil) {
        return;
    }

    defaultsTransformer = transformer;
    defaultsKey = newKey;
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:newKey] options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:kMASShortcutViewBindingsContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != kMASShortcutViewBindingsContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if([[keyPath substringToIndex:7] isEqualToString:@"values."]) {
        NSString *defaultsKeyName = [keyPath stringByReplacingOccurrencesOfString:@"values." withString:@""];

        if([defaultsKeyName isEqualToString:defaultsKey]) {
            NSValueTransformer *transformer = defaultsTransformer;

            NSAssert(transformer != nil, @"Can’t observe shortcuts without a transformer.");

            id value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:defaultsKeyName];
            MASShortcut *shortcut = [transformer transformedValue:value];

            [self setShortcutValue:shortcut andPropagate:NO];
        }
    }
}


- (void) setAssociatedUserDefaultsKey: (NSString*) newKey withTransformerName: (NSString*) transformerName
{
    [self setAssociatedUserDefaultsKey:newKey withTransformer:[NSValueTransformer valueTransformerForName:transformerName]];
}

- (void) setAssociatedUserDefaultsKey: (NSString*) newKey
{
    [self setAssociatedUserDefaultsKey:newKey withTransformerName:MASDictionaryTransformerName];
}

@end
