#
#  Makefile
#  libgit2 for Apple stuff
#
#

DEFAULTTARGETS="ios64-cross mac-catalyst-x86_64"
DEFAULTFWTARGETS="iOS-arm64 macOS-x86_64 simulator-x86_64"
OPENSSLVER="1.1.1h"
LIBSSHVER="1.9.0"

CUR_DIR = $(CURDIR)
TARGETDIR := target

BUILD_OPENSSL := $(realpath $(CUR_DIR)/src/openssl/build-libssl.sh)
BUILD_LIBSSH := $(realpath $(CUR_DIR)/src/libssh2/build-libssh.sh)
BUILD_LIBGIT := $(realpath $(CUR_DIR)/src/libgit2/build-libgit.sh)
CREATE_FRAMEWORK := $(realpath $(CUR_DIR)/create-ngit-framework.sh)

STATIC_IOS := $(TARGETDIR)/iOS-arm64/libgit2static.a
STATIC_MACOS := $(TARGETDIR)/macOS-x86_64/libgit2static.a
STATIC_SIM := $(TARGETDIR)/simulator-x86_64/libgit2static.a

FRAMEWORK_IOS := $(TARGETDIR)/frameworks/iOS-arm64/libgit2.framework
FRAMEWORK_MACOS := $(TARGETDIR)/frameworks/macOS-x86_64/libgit2.framework
FRAMEWORK_SIM := $(TARGETDIR)/frameworks/simulator-x86_64/libgit2.framework

OUTPUT_DIR := framework

default: framework_static

${TARGETDIR}:
	mkdir -p ${TARGETDIR}

build_ios: ${FRAMEWORK_IOS}
${FRAMEWORK_IOS}: ${TARGETDIR} openssl_ios libssh2_ios libgit2_ios
openssl_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="ios64-cross-arm64" --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="ios64-cross-arm64" --version=$(LIBSSHVER)
libgit2_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="ios64-cross-arm64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="iOS-arm64"

build_macos: ${FRAMEWORK_MACOS}
${FRAMEWORK_MACOS}: ${TARGETDIR} openssl_mac libssh2_mac libgit2_mac
openssl_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="mac-catalyst-x86_64" --ec-nistp-64-gcc-128 --macosx-sdk="10.15" --version=${OPENSSLVER}
libssh2_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="mac-catalyst-x86_64" --version=$(LIBSSHVER) --macosx-sdk="10.15"
libgit2_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="mac-catalyst-x86_64" --macosx-sdk="10.15" --verbose && \
	$(CREATE_FRAMEWORK) --targets="macOS-x86_64"

build_sim: ${FRAMEWORK_SIM}
${FRAMEWORK_SIM}: ${TARGETDIR} openssl_sim libssh2_sim libgit2_sim
openssl_sim:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="ios-sim-cross-x86_64" --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_sim:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="ios-sim-cross-x86_64" --version=$(LIBSSHVER)
libgit2_sim:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="ios-sim-cross-x86_64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="simulator-x86_64"

framework: build_ios build_macos build_sim git2.xcframework
git2.xcframework:
	xcodebuild -create-xcframework \
		-framework ${FRAMEWORK_IOS} \
		-framework ${FRAMEWORK_MACOS} \
		-framework ${FRAMEWORK_SIM} \
		-output git2.xcframework

framework_static: build_ios build_macos build_sim libgit2.xcframework
libgit2.xcframework:
	xcodebuild -create-xcframework \
		-library $(STATIC_IOS) \
		-library ${STATIC_MACOS} \
		-library ${STATIC_SIM} \
		-output libgit2.xcframework

codesign:
	codesign_identity=$(security find-identity -v -p codesigning | grep A33F2F2 | grep -o -E '\w{40}' | head -n 1)
	codesign -f --deep -s 769B34C9C0E7AA7E0B0D60FF33C9F6F565288DBC libgit2.xcframework

clean:
	@echo " Cleaning...";
	@$(RM) -r $(TARGETDIR)

.PHONY: clean
