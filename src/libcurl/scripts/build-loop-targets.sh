#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for iPhoneOS, iPhoneSimulator and macCatalyst
unset LDFLAGS
unset EXTRA_CMAKE_ARGS

for TARGET in ${TARGETS}
do
  # Determine relevant SDK version
  if [[ "${TARGET}" == tvos* ]]; then
    SDKVERSION="${TVOS_SDKVERSION}"
  elif [[ "${TARGET}" == "mac-"* ]]; then
    SDKVERSION="${MACOSX_SDKVERSION}"
  else
    SDKVERSION="${IOS_SDKVERSION}"
  fi

  # These variables are used in the configuration file
  export SDKVERSION
  export IOS_MIN_SDK_VERSION
  export TVOS_MIN_SDK_VERSION
  export CONFIG_DISABLE_BITCODE

    # Determine platform
  if [[ "${TARGET}" == "ios-sim-cross-"* ]]; then
    PLATFORM="iPhoneSimulator"
  elif [[ "${TARGET}" == "tvos-sim-cross-"* ]]; then
    PLATFORM="AppleTVSimulator"
  elif [[ "${TARGET}" == "tvos64-cross-"* ]]; then
    PLATFORM="AppleTVOS"
  elif [[ "${TARGET}" == "mac-"* ]]; then
    PLATFORM="MacOSX"
    if [[ "${TARGET}" == "mac-catalyst-"* ]]; then
      PLATFORM_VARIANT="Catalyst"
    else
      PLATFORM_VARIANT="Mac"
    fi
  else
    PLATFORM="iPhoneOS"
  fi

  # Extract ARCH from TARGET (part after last dash)
  ARCH=$(echo "${TARGET}" | sed -E 's|^.*\-([^\-]+)$|\1|g')

  if [[ "$ARCH" == arm64* ]]; then
    HOST="aarch64-apple-darwin"
  else
    HOST="$ARCH-apple-darwin"
  fi 

  # Cross compile references, see Configurations/10-main.conf
  export CROSS_COMPILE="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
  export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
  export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
  export SDKROOT="${CROSS_TOP}/SDKs/${CROSS_SDK}"

  # Prepare TARGETDIR and SOURCEDIR
  prepare_target_source_dirs

  ## Determine config options
  # Add build target, --prefix and prevent async (references to getcontext(),
  # setcontext() and makecontext() result in App Store rejections) and creation
  # of shared libraruuuies (default since 1.1.0)
  if [[ "${PLATFORM}" == "MacOSX" ]]; then
    if [[ "${PLATFORM_VARIANT}" == "Catalyst" ]]; then
      export CFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT --target=$ARCH-apple-ios14.0-macabi -miphoneos-version-min=14.0  -fembed-bitcode -I${OPENSSLDIR}/include"
      export CPPFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT --target=$ARCH-apple-ios14.0-macabi -miphoneos-version-min=14.0 -I${OPENSSLDIR}/include"
    else
      export CFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT -fembed-bitcode -I${OPENSSLDIR}/include"
      export CPPFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT -I${OPENSSLDIR}/include"
    fi
  else
    export CFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT -mios-version-min=13.0 -fembed-bitcode -I${OPENSSLDIR}/include -fembed-bitcode"
    export CPPFLAGS="-arch $ARCH -pipe -Os -fPIE -isysroot $SDKROOT -mios-version-min=13.0 -I${OPENSSLDIR}/include -fembed-bitcode"
  fi
  if [[ "${PLATFORM}" == "iPhoneSimulator" ]]; then
    export CFLAGS="$CFLAGS --target=$ARCH-apple-ios12.0-simulator"
  fi  
  export LDFLAGS="-arch $ARCH -isysroot $SDKROOT -L${OPENSSLDIR}/lib -fembed-bitcode"
  export LOCAL_CONFIG_OPTIONS="--prefix=${TARGETDIR} --with-ssl=${OPENSSLDIR} --with-libssh2 --enable-ipv6 --host=${HOST} --disable-shared --enable-static --disable-manual -with-random=/dev/urandom"
  export PKG_CONFIG_PATH="{$TARGETDIR}/lib/pkgconfig/"
  export LIPO=""

  # Run Configure
  run_configure

  # Run make
  run_make

  # Run make install
  set -e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make install | tee -a "${LOG}"
  else
    make install >> "${LOG}" 2>&1
  fi

  # Remove source dir, add references to library files to relevant arrays
  # Keep reference to first build target for include file
  finish_build_loop
done
