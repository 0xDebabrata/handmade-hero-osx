#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <stdio.h>

#define internal static
#define local_persist static
#define global_variable static

internal bool running = true;
global_variable uint8_t *bitmapMemory;
global_variable int bitmapWidth = 1280;
global_variable int bitmapHeight = 720;
global_variable int bytesPerPixel = 4;

void renderWeirdGradient(int xOffset, int yOffset) {
  int pitch = bitmapWidth * bytesPerPixel;
  uint8_t *row = bitmapMemory;
  for (int y = 0; y < bitmapHeight; y++) {
    uint32_t *pixel = (uint32_t *)row;
    for (int x = 0; x < bitmapWidth; x++) {
      // write pixel data
      uint8_t red = 0;
      uint8_t blue = (uint8_t)(x + xOffset);
      uint8_t green = (uint8_t)(y + yOffset);
      uint8_t alpha = 255;
      *pixel++ = (alpha << 24) | (blue << 16) | (green << 8) | red;
    }
    row += pitch;
  }
}

void redrawBuffer(NSWindow *window) {
  @autoreleasepool {
    NSBitmapImageRep *img = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:&bitmapMemory
                      pixelsWide:bitmapWidth
                      pixelsHigh:bitmapHeight
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:true
                        isPlanar:false
                  colorSpaceName:NSDeviceRGBColorSpace
                     bytesPerRow:bytesPerPixel * bitmapWidth
                    bitsPerPixel:bytesPerPixel * 8] autorelease];
    NSImage *display =
        [[[NSImage alloc] initWithData:[img TIFFRepresentation]] autorelease];
    window.contentView.layer.contents = display;
  }
}

@interface WindowDelegate : NSObject <NSWindowDelegate>
@end

void allocateBuffer(NSWindow *window, NSSize frameSize) {
  int initialWidth = window.contentView.bounds.size.width;
  int initialHeight = window.contentView.bounds.size.height;
  if (bitmapMemory) {
    vm_address_t *buffer_vm_address = (vm_address_t *)&bitmapMemory;
    vm_deallocate((vm_map_t)mach_task_self(), *buffer_vm_address,
                  (vm_size_t)(initialWidth * initialHeight * bytesPerPixel));
  }
  bitmapWidth = frameSize.width;
  bitmapHeight = frameSize.height;
  int bytesPerPixel = 4;
  // Use vm_allocate to allocate large chunks of memory instead of malloc.
  // Allocated memory is 0 filled.
  vm_address_t buffer_vm_address;
  kern_return_t err =
      vm_allocate((vm_map_t)mach_task_self(), &buffer_vm_address,
                  (vm_size_t)(bitmapWidth * bitmapHeight * bytesPerPixel),
                  VM_FLAGS_ANYWHERE);
  if (err != KERN_SUCCESS) {
    NSLog(
        @"Encountered an error trying to allocate virtual memory for buffer.");
  }
  bitmapMemory = (uint8_t *)buffer_vm_address;
}

@implementation WindowDelegate
/* NSWindowDelegate protocols */
- (void)windowWillClose:(NSNotification *)notification {
  running = false;
}
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  // fill bitmap with content
  allocateBuffer(sender, frameSize);
  renderWeirdGradient(0, 0);
  redrawBuffer(sender);

  return frameSize;
}
@end

int main(int argc, const char *argv[]) {
  int xOffset = 0;
  int yOffset = 0;
  WindowDelegate *delegate = [[WindowDelegate alloc] init];

  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, bitmapWidth, bitmapHeight)
                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable |
                           NSWindowStyleMaskFullSizeContentView)
                  backing:NSBackingStoreBuffered
                    defer:NO];

  [window setDelegate:delegate];
  [window setTitle:@"Handmade Hero"];
  [window makeKeyAndOrderFront:nil];

  allocateBuffer(window, NSMakeSize(bitmapWidth, bitmapHeight));
  while (running) {
    renderWeirdGradient(xOffset, yOffset);
    redrawBuffer(window);
    xOffset++;
    yOffset++;

    NSEvent *event;

    do {
      event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                 untilDate:nil
                                    inMode:NSDefaultRunLoopMode
                                   dequeue:YES];
      switch ([event type]) {
      default:
        [NSApp sendEvent:event];
      }
    } while (event != nil);
  }

  return 0;
}
