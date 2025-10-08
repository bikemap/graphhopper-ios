graphhopper-ios
===============

graphhopper-ios wraps [graphhopper](https://github.com/graphhopper/graphhopper/) 
and creates the `libgraphhopper.a` library to be used on iOS. 
Theoretically it should be possible to include other architectures, but for example MacOS currently doesn't work. 

It uses [j2objc](https://github.com/google/j2objc) to translate the .java sources 
into Objective-C.

> **Disclaimer:** This is experimental so treat it accordingly. [Feel free to help](CONTRIBUTING.md) in any way.


## Prerequistes
JDK 8 (Yes, jts source needs JDK 8), recommended is AdoptOpenJDK8
Maven 
XCode 11.4+ (works with XCode 13)

## Getting Started

To get started run the following commands in Terminal:

```sh
git clone https://github.com/graphhopper/graphhopper-ios.git
cd graphhopper-ios
git submodule init
git submodule update
git submodule update --remote --init --recursive graphhopper
make cleanall
make class.list
make translate
make
./graphhopper-ios-sample/import-sample.sh
open graphhopper-ios-sample/graphhopper-ios-sample.xcodeproj
```

Switch scheme to graphhoppper-ios-sample and run against Simulator or the real device
(requires Apple Developer account and signing setup in place).

To integrate GraphHopper in your project see Usage section below.
 
## Community

Feel free to raise problems or questions in [our forum](https://discuss.graphhopper.com/c/graphhopper/graphhopper-ios-and-android).

## Usage

- You can add *graphhopper.xcodeproj* as subproject to your project (see details in Xcode section).
- Or you can compile it as a XCFramework (see Terminal section)

### Xcode

To configure your project to use *graphhopper.xcodeproj* follow the steps below:

- Drag&drop *graphhopper.xcodeproj* into your project (or use the menu File -> Add Files to...)
- Expand graphhopper.xcodeproj and drag&drop the **Translations** and **Libraries** 
groups into your project (make sure you check "Create folder references" and have 
your target selected in "Add to targets:")
- In the Build Settings of your project:
    - add `-ObjC` to your target's Other Linker Flags
    - add `{path-to-graphhopper-ios}/j2objc/include` and `{path-to-graphhopper-ios}/src` 
    to your target's User Header Search Paths
- In the Build Phases of your project:
    - in Target Dependencies add the **graphhopper** target
    - in Link Binary With Libraries add **Security.framework** (to support secure hash generation), 
**libz.dylib** (needed to support java.util.zip) and **libicucore.dylib** (to support java.text, 
which is a dependency introduced by [j2objc 0.9.5](https://github.com/google/j2objc/releases/tag/0.9.5))

You're now ready to use GraphHopper on iOS and OS X.

> You are responsible for importing graph data. For an example check out 
[graphhopper-ios-sample](graphhopper-ios-sample).

### Terminal

Alternatively, you can translate and compile the library by invoking `make`  in the Terminal.
You can modify `common.mk` and `library.mk` to include all necessary arhitectures. This article provides
good overview of options: https://docs.elementscompiler.com/Platforms/Cocoa/CpuArchitectures/ 
Currently scripts include Simulator (arm64) and iPhone architectures. 

After you get libraries (achitecture-libgraphhopper.a) using `make`, create XCFramework form it using 
```xcodebuild -create-xcframework \
    -library "build/iphone64-libgraphhopper.a" \
    -library "build/simulator-libgraphhopper.a" \
    -output "xcframeworks/GraphHopperLib.xcframework"
```
To make Obj-C libraries available from swift code we should decorate xcframework as a module.
For this inside each architecture folder in framework we create Headers folder where we add:
module.modulemap file, all headers from graphhopper (could be found in src folder)
and umbrella header GraphHopperLib.h where we list interfaces available from swift.
Here is content of module.modulemap
```
module GraphHopperLib {
    umbrella header "GraphHopperLib.h"
    export *
}
```
Along with resulting GraphHopper.xcframework we also need to add JRE.xcframework to the project to
provide runtime Java libraries. To make project binary smaller as alternative we coudl instead create manually
xcframeworks for these libraries using ios-arm64 and ios-arm64-simulator archs:
- libjre_core.a
- libjre_net.a
- libjre_security.a
- libjre_io.a
- libire_util.a
- libjre_xml.a
- libjre_zip.a

To make link phase succeed we also need to add structured headers for all obj-c libraries included.
For this we copy src folder from graphhopper and include folder from j2objc to the project but we don’t need
to add them to project structure. Instead both should be added to User Header Search Paths of Build Settings
with recursive option. 
`${SRCROOT}/GraphHopper/Headers`

## Example

![iPhone-offline-routing](screenshots/iPhone-offline-routing.gif)

## Requirements

* iOS 14.0+ or OS X 10.10 (it might work on older versions but haven't tested)
* JDK 21 or higher
* Xcode 13.0 or higher

## Troubleshooting

If you run into problems, you can try one of the following:

* if using Xcode, try cleaning up the project (Product -> Clean)
* if using the Terminal, you can use one of these 2 cleanup commands:
  * `make clean` - will delete the /graphhopper-ios/build directory
  * `make cleanall` - if the first one didn't do it, this will delete everything 
related to the build process (you then need to run `make class.list`)

## Refresh Code

The dependencies j2objc, hppc and jts should be downloaded automatically if not present. You can force to reload by removing them: 

```rm -rf dependencies/hppc dependencies/jts j2objc
make dependencies/hppc dependencies/jts j2objc
```

## Updating GraphHopper

It's not a trivial process which might require changes on all sides: Java, build scripts, Xcode project.
But general steps are:

1. Update graphhopper submodule to point to the branch of graphhopper with version you want to target.
Usually it's `ios_compatibility` If the submodule was already cloned to get the latest commit of the branch
you have to delete submobule and add it again using commands:
```
git submodule deinit -f -- graphhopper
git rm -f graphhopper
rm -rf .git/modules/graphhopper 
git submodule add -b ios_compatibility https://github.com/graphhopper/graphhopper.git graphhopper
git submodule update --init --recursive
```

2. Try to run
```
make cleanall
make class.list
make translate
```
You will most probably get errors due to missing dependencies. Install missing dependencies as submodules.
If necessary some folders of dependencies could be ignored on `class.list` creation.
For example tests should be always excluded as we don't need them and they often bring other unwanted dependencies.
Sometimes Java code must be adjusted to get rid of dependency. For example `javax.` is only used on Java compilation step
and we can't add it as dependency to this pipeflow. 

3. After you get `.a` libraries combine them as xcframework as described in Terminal and try to add to the project.
Try to run it. Most likely you will get errors due to changed interfaces. Adjust swift code accordingly.

