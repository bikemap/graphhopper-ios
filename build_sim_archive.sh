SCHEME_NAME="graphhopper"
FRAMEWORK_NAME="graphhopper"

SIMULATOR_ARCHIVE_PATH="${BUILD_DIR}/${CONFIGURATION}/${FRAMEWORK_NAME}-iphonesimulator.xcarchive"
DEVICE_ARCHIVE_PATH="${BUILD_DIR}/${CONFIGURATION}/${FRAMEWORK_NAME}-iphoneos.xcarchive"

OUTPUT_DIR="./Products/"

# Simulator xcarchive (arm64 + x86_64)
xcodebuild archive \
  ONLY_ACTIVE_ARCH=NO \
  -scheme ${SCHEME_NAME} \
  -project "${SCHEME_NAME}.xcodeproj" \
  -archivePath ${SIMULATOR_ARCHIVE_PATH} \
  -sdk iphonesimulator \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# Device xcarchive (arm64)
xcodebuild archive \
  -scheme ${SCHEME_NAME} \
  -project "${SCHEME_NAME}.xcodeproj" \
  -archivePath ${DEVICE_ARCHIVE_PATH} \
  -sdk iphoneos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# Clean-up any existing instance of this xcframework from the Products directory
rm -rf "${OUTPUT_DIR}${SCHEME_NAME}.xcframework"

# Create final xcframework
xcodebuild -create-xcframework \
  -framework ${DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
  -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
  -output ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework