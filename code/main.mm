#include <AppKit/AppKit.h>
#include <stdio.h>

@interface WindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation WindowDelegate
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  return frameSize;
}
@end

int main(int argc, const char *argv[]) {
  NSApplication *app = [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 1280, 720)
                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable |
                           NSWindowStyleMaskFullSizeContentView)
                  backing:NSBackingStoreBuffered
                    defer:NO];

  WindowDelegate *delegate = [[WindowDelegate alloc] init];

  [window setDelegate:delegate];
  [window setBackgroundColor:NSColor.purpleColor];
  [window setTitle:@"Handmade Hero"];
  [window makeKeyAndOrderFront:nil];

  [app run];
  printf("handmade hero");
  return 0;
}
