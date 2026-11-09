// sim-audio <udid> <host-output-uid>: send a booted simulator's audio output to one host device.
// Uses CoreSimulator's private audio route, the one Simulator.app's I/O > Audio Output menu sets.
// The route resets when the simulator boots. ios-sim builds and runs this.
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/message.h>

static NSString *const CORESIMULATOR = @"/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator";
static NSString *const AUDIO_ROUTE_PORT = @"com.apple.CoreSimulator.Audio.HostRoute";
// Guest scope argument for output; found by probing, not documented.
static const unsigned GUEST_OUTPUT_SCOPE = 2;
// CoreSimulator's value for "follow the Mac's default output", the route a booted simulator starts with.
static NSString *const DEFAULT_OUTPUT_UID = @"__sim__hostUseSystemDefaultDeviceUID";
static const int64_t ROUTE_TIMEOUT_NS = 5 * NSEC_PER_SEC;

@protocol SimAudioHostRoutable
- (void)routeGuestDeviceScope:(unsigned)scope toHostDeviceUID:(NSString *)uid completionQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSError *))handler;
- (NSString *)guestOutputHostDeviceUID;
@end

@protocol SimDeviceIOPort
- (id)descriptor;
- (NSString *)portIdentifier;
@end

static int fail(NSString *message) {
  fprintf(stderr, "sim-audio: %s\n", message.UTF8String);
  return 1;
}

static id findDevice(NSString *udid) {
  NSString *developerDir = NSProcessInfo.processInfo.environment[@"DEVELOPER_DIR"] ?: @"/Applications/Xcode.app/Contents/Developer";
  NSError *error = nil;
  id context = ((id (*)(id, SEL, id, NSError **))objc_msgSend)(NSClassFromString(@"SimServiceContext"), @selector(sharedServiceContextForDeveloperDir:error:), developerDir, &error);
  id deviceSet = ((id (*)(id, SEL, NSError **))objc_msgSend)(context, @selector(defaultDeviceSetWithError:), &error);
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:udid];
  return uuid ? [deviceSet valueForKey:@"devicesByUDID"][uuid] : nil;
}

static id<SimAudioHostRoutable> findAudioRoute(id device) {
  for (id<SimDeviceIOPort> port in [[device valueForKey:@"io"] valueForKey:@"ioPorts"]) {
    id descriptor = [port descriptor];
    if ([[descriptor portIdentifier] isEqual:AUDIO_ROUTE_PORT]) return descriptor;
  }
  return nil;
}

// Returns an error message, or nil once the route call completes.
static NSString *routeOutput(id<SimAudioHostRoutable> route, NSString *hostUID) {
  dispatch_semaphore_t done = dispatch_semaphore_create(0);
  __block NSError *routeError = nil;
  [route routeGuestDeviceScope:GUEST_OUTPUT_SCOPE toHostDeviceUID:hostUID completionQueue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0) completionHandler:^(NSError *error) {
    routeError = error;
    dispatch_semaphore_signal(done);
  }];
  if (dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, ROUTE_TIMEOUT_NS))) return @"timed out routing audio";
  return routeError.localizedDescription;
}

int main(int argc, char **argv) {
  @autoreleasepool {
    if (argc != 3) return fail(@"usage: sim-audio <udid> <host-output-uid>");
    NSString *udid = @(argv[1]);
    NSString *hostUID = @(argv[2]);
    if (!dlopen(CORESIMULATOR.UTF8String, RTLD_NOW)) return fail([NSString stringWithFormat:@"cannot load CoreSimulator: %s", dlerror()]);
    id device = findDevice(udid);
    if (!device) return fail([NSString stringWithFormat:@"no simulator %@", udid]);
    id<SimAudioHostRoutable> route = findAudioRoute(device);
    if (!route) return fail([NSString stringWithFormat:@"simulator %@ has no audio route; is it booted?", udid]);

    NSString *routeError = routeOutput(route, hostUID);
    if (routeError) return fail(routeError);
    // An unknown UID is accepted without error and pins the output to the current default device,
    // so put back the route that follows the default.
    NSString *actual = [route guestOutputHostDeviceUID];
    if (![actual isEqual:hostUID]) {
      routeOutput(route, DEFAULT_OUTPUT_UID);
      return fail([NSString stringWithFormat:@"output went to %@, not %@; is that device installed?", actual, hostUID]);
    }
  }
  return 0;
}
