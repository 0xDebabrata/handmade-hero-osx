#include <AppKit/AppKit.h>
#include <cstdint>
#include <cstdlib>
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
  int width = frameSize.width;
  int height = frameSize.height;
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

  int width = window.contentView.bounds.size.width;
  int height = window.contentView.bounds.size.height;
  int bytesPerPixel = 4;
  // Use vm_allocate to allocate large chunks of memory instead of malloc.
  // Allocated memory is 0 filled.
  vm_address_t buffer_vm_address;
  kern_return_t err = vm_allocate(
      (vm_map_t)mach_task_self(), &buffer_vm_address,
      (vm_size_t)(width * height * bytesPerPixel), VM_FLAGS_ANYWHERE);
  if (err != KERN_SUCCESS) {
    NSLog(
        @"Encountered an error trying to allocate virtual memory for buffer.");
  }
  uint8_t *buffer = (uint8_t *)buffer_vm_address;

  NSBitmapImageRep *img = [[[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:&buffer
                    pixelsWide:width
                    pixelsHigh:height
                 bitsPerSample:8
               samplesPerPixel:4
                      hasAlpha:true
                      isPlanar:false
                colorSpaceName:NSDeviceRGBColorSpace
                   bytesPerRow:bytesPerPixel * width
                  bitsPerPixel:bytesPerPixel * 8] autorelease];

  [app run];
  return 0;
}
