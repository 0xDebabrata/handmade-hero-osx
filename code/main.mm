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

struct offscreenBuffer {
  uint8_t *memory;
  int width;
  int height;
  int bytesPerPixel;
};

global_variable bool running = true;
global_variable offscreenBuffer globalBackBuffer;

void renderWeirdGradient(offscreenBuffer buffer, int xOffset, int yOffset) {
  int pitch = buffer.width * buffer.bytesPerPixel;
  uint8_t *row = buffer.memory;
  for (int y = 0; y < buffer.height; y++) {
    uint32_t *pixel = (uint32_t *)row;
    for (int x = 0; x < buffer.width; x++) {
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

void redrawBuffer(NSWindow *window, offscreenBuffer buffer) {
  @autoreleasepool {
    NSBitmapImageRep *img = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:&buffer.memory
                      pixelsWide:buffer.width
                      pixelsHigh:buffer.height
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:true
                        isPlanar:false
                  colorSpaceName:NSDeviceRGBColorSpace
                     bytesPerRow:buffer.bytesPerPixel * buffer.width
                    bitsPerPixel:buffer.bytesPerPixel * 8] autorelease];
    NSImage *display =
        [[[NSImage alloc] initWithData:[img TIFFRepresentation]] autorelease];
    window.contentView.layer.contents = display;
  }
}

@interface WindowDelegate : NSObject <NSWindowDelegate>
@end

void allocateBuffer(NSWindow *window, NSSize frameSize,
                    offscreenBuffer *buffer) {
  int initialWidth = window.contentView.bounds.size.width;
  int initialHeight = window.contentView.bounds.size.height;
  if (buffer->memory) {
    vm_address_t *buffer_vm_address = (vm_address_t *)&buffer->memory;
    vm_deallocate(
        (vm_map_t)mach_task_self(), *buffer_vm_address,
        (vm_size_t)(initialWidth * initialHeight * buffer->bytesPerPixel));
  }
  buffer->width = frameSize.width;
  buffer->height = frameSize.height;
  // Use vm_allocate to allocate large chunks of memory instead of malloc.
  // Allocated memory is 0 filled.
  vm_address_t buffer_vm_address;
  kern_return_t err = vm_allocate(
      (vm_map_t)mach_task_self(), &buffer_vm_address,
      (vm_size_t)(buffer->width * buffer->height * buffer->bytesPerPixel),
      VM_FLAGS_ANYWHERE);
  if (err != KERN_SUCCESS) {
    NSLog(
        @"Encountered an error trying to allocate virtual memory for buffer.");
  }
  buffer->memory = (uint8_t *)buffer_vm_address;
}

@implementation WindowDelegate
/* NSWindowDelegate protocols */
- (void)windowWillClose:(NSNotification *)notification {
  running = false;
}
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  // fill bitmap with content
  allocateBuffer(sender, frameSize, &globalBackBuffer);
  renderWeirdGradient(globalBackBuffer, 0, 0);
  redrawBuffer(sender, globalBackBuffer);

  return frameSize;
}
@end

int main(int argc, const char *argv[]) {
  int xOffset = 0;
  int yOffset = 0;
  globalBackBuffer.width = 1280;
  globalBackBuffer.height = 720;
  globalBackBuffer.bytesPerPixel = 4;
  WindowDelegate *delegate = [[WindowDelegate alloc] init];

  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, globalBackBuffer.width,
                                     globalBackBuffer.height)
                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable |
                           NSWindowStyleMaskFullSizeContentView)
                  backing:NSBackingStoreBuffered
                    defer:NO];

  [window setDelegate:delegate];
  [window setTitle:@"Handmade Hero"];
  [window makeKeyAndOrderFront:nil];

  allocateBuffer(window,
                 NSMakeSize(globalBackBuffer.width, globalBackBuffer.height),
                 &globalBackBuffer);

  while (running) {
    renderWeirdGradient(globalBackBuffer, xOffset, yOffset);
    redrawBuffer(window, globalBackBuffer);
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
