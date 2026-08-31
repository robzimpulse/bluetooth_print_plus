//
//  GSDKStubs.m
//  GSDK — iOS Simulator stub
//
//  PURPOSE
//  -------
//  This file is the *entire* implementation of the GSDK slice that ships in
//  GSDK.xcframework's `ios-arm64_x86_64-simulator` directory. It exists so the
//  app can be built and run on an iOS Simulator at all.
//
//  The real GSDK is a static library whose every slice — arm64 included — is
//  tagged LC_VERSION_MIN_IPHONEOS, i.e. iOS *device*. Xcode refuses to link a
//  device-tagged arm64 slice into an arm64 simulator build, and since Xcode 26
//  ships only arm64-only simulator runtimes, there is no x86_64 fallback left.
//  Retagging the real objects is not an option either: all 11 of them have
//  exactly zero bytes of padding between their load commands and their first
//  section, so LC_VERSION_MIN_IPHONEOS (16 bytes) cannot grow into
//  LC_BUILD_VERSION (24 bytes) without relocating every section and rewriting
//  every offset in the file.
//
//  Nothing is lost by stubbing. GSDK drives a Bluetooth thermal printer, and a
//  simulator has no Bluetooth, so the printer path could never be exercised
//  there under any implementation. The device slice of the xcframework is the
//  untouched real library, so hardware builds are completely unaffected.
//
//  HOW IT WORKS
//  ------------
//  Each GSDK class is declared with an empty @implementation, which is enough
//  to emit the _OBJC_CLASS_$_ symbols the linker needs, and to synthesise every
//  @property declared in the real headers.
//
//  Method bodies are supplied dynamically instead of being written out one by
//  one: +resolveInstanceMethod:/+resolveClassMethod: install a single no-op IMP
//  for whatever selector is sent. That is safe here only because *every* method
//  GSDK declares returns either void or an object pointer — checked across all
//  11 headers: 160 `void`, 9 `NSData *`, 4 `UIImage *`, 1 `NSString *`, 1 `id`,
//  and no float, double, or struct returns. A function returning `id` therefore
//  satisfies the ABI in both cases: object returns get nil, and void returns
//  ignore the register. If a future GSDK header adds a method returning a float
//  or a struct, this shortcut stops being valid and that method must be written
//  out explicitly.
//
//  Every call is logged, loudly and once per selector, so a developer never
//  mistakes a simulator no-op for working printing.
//
//  REGENERATING
//  ------------
//  Do not edit the built artifact. Run ./build_xcframework.sh from this
//  directory; see README.md.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "BLEConnecter.h"
#import "CPCLCommand.h"
#import "CPCLData.h"
#import "Connecter.h"
#import "ConnecterBlock.h"
#import "EscCommand.h"
#import "EthernetConnecter.h"
#import "GPUtils.h"
#import "TscCommand.h"
#import "ZplCommand.h"
#import "ZplConfig.h"

// Every method is supplied at runtime by +resolveInstanceMethod: rather than
// being written out, so the compiler correctly observes that each
// @implementation below is "incomplete". That is the design, not an oversight —
// silence the warning here so a real problem in this file is not buried under
// ~176 expected ones.
#pragma clang diagnostic ignored "-Wincomplete-implementation"

/// Single no-op used for every dynamically resolved GSDK method.
///
/// Returns `id` so that object-returning methods yield nil and void-returning
/// methods simply leave an ignored value in the return register. Extra
/// arguments are untouched, which is safe on both arm64 and x86_64 because the
/// callee never reads them.
static id GSDKStubNoop(id self, SEL _cmd) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSLog(@"[GSDK] ⚠️ This build links the iOS Simulator STUB of GSDK. Every "
          @"printer call is a no-op and nothing will be printed. Simulators "
          @"have no Bluetooth — use a physical device to test printing.");
  });
  NSLog(@"[GSDK] stub no-op: %@[%@ %@]",
        class_isMetaClass(object_getClass(self)) ? @"+" : @"-",
        NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  return nil;
}

/// Declares an empty implementation for a GSDK class and routes any selector
/// sent to it (instance or class) at `GSDKStubNoop`.
#define GSDK_STUB_CLASS(NAME)                                                  \
  @implementation NAME                                                         \
  +(BOOL)resolveInstanceMethod : (SEL)sel {                                    \
    class_addMethod(self, sel, (IMP)GSDKStubNoop, "@@:");                      \
    return YES;                                                                \
  }                                                                            \
  +(BOOL)resolveClassMethod : (SEL)sel {                                       \
    class_addMethod(object_getClass(self), sel, (IMP)GSDKStubNoop, "@@:");     \
    return YES;                                                                \
  }                                                                            \
  @end

GSDK_STUB_CLASS(Connecter)
GSDK_STUB_CLASS(BLEConnecter)
GSDK_STUB_CLASS(EthernetConnecter)
GSDK_STUB_CLASS(CPCLCommand)
GSDK_STUB_CLASS(CPCLData)
GSDK_STUB_CLASS(BitmapImage)
GSDK_STUB_CLASS(EscCommand)
GSDK_STUB_CLASS(TscCommand)
GSDK_STUB_CLASS(ZplCommand)
GSDK_STUB_CLASS(GPUtils)
GSDK_STUB_CLASS(BarCodeConfig)
GSDK_STUB_CLASS(QrCodeConfig)
