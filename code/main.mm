#include <AppKit/AppKit.h>
#include <stdio.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@end

@implementation AppDelegate
/* NSApplicationDelegate protocols */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:
    (NSApplication *)sender {
  return NSTerminateNow;
}

/* NSWindowDelegate protocols */
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  return frameSize;
}
@end

int main(int argc, const char *argv[]) {
  NSApplication *app = [NSApplication sharedApplication];
  AppDelegate *delegate = [[AppDelegate alloc] init];

  [app setDelegate:delegate];
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 1280, 720)
                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable |
                           NSWindowStyleMaskFullSizeContentView)
                  backing:NSBackingStoreBuffered
                    defer:NO];

  [window setDelegate:delegate];
  [window setBackgroundColor:NSColor.purpleColor];
  [window setTitle:@"Handmade Hero"];
  [window makeKeyAndOrderFront:nil];

  [app run];
  return 0;
}
