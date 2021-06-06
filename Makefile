#
#  Makefile
#  libgit2 for Apple stuff
#
#

DEFAULTTARGETS="ios64-cross mac-catalyst-x86_64"
DEFAULTFWTARGETS="iOS-arm64 macOS-x86_64 simulator-x86_64 simulator-arm64"
OPENSSLVER="1.1.1k"
LIBSSHVER="1.9.0"

CUR_DIR = $(CURDIR)
TARGETDIR := target

BUILD_OPENSSL := $(realpath $(CUR_DIR)/src/openssl/build-libssl.sh)
BUILD_LIBSSH := $(realpath $(CUR_DIR)/src/libssh2/build-libssh.sh)
BUILD_LIBGIT := $(realpath $(CUR_DIR)/src/libgit2/build-libgit.sh)
CREATE_FRAMEWORK := $(realpath $(CUR_DIR)/create-ngit-framework.sh)

STATIC_IOS := $(TARGETDIR)/iOS-arm64/libgit2static.a
STATIC_MACOS := $(TARGETDIR)/macOS-x86_64/libgit2static.a
STATIC_MACOS_ARM64 := $(TARGETDIR)/macOS-arm64/libgit2static.a
STATIC_SIM := $(TARGETDIR)/simulator-x86_64/libgit2static.a
STATIC_SIM_ARM64 := $(TARGETDIR)/simulator-arm64/libgit2static.a

FRAMEWORK_IOS := $(TARGETDIR)/frameworks/iOS-arm64/libgit2.framework
FRAMEWORK_MACOS := $(TARGETDIR)/frameworks/macOS-x86_64/libgit2.framework
FRAMEWORK_MACOS_ARM64 := $(TARGETDIR)/frameworks/macOS-arm64/libgit2.framework
FRAMEWORK_SIM := $(TARGETDIR)/frameworks/simulator-x86_64/libgit2.framework
FRAMEWORK_SIM_ARM64 := $(TARGETDIR)/frameworks/simulator-arm64/libgit2.framework

OUTPUT_DIR := framework

default: framework_static

${TARGETDIR}:
	mkdir -p ${TARGETDIR}

build_ios: ${FRAMEWORK_IOS}
${FRAMEWORK_IOS}: ${TARGETDIR} openssl_ios libssh2_ios libgit2_ios
openssl_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="ios-cross-arm64" --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="ios-cross-arm64" --verbose-on-error --version=$(LIBSSHVER)
libgit2_ios:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="ios-cross-arm64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="iOS-arm64"

build_macos: ${FRAMEWORK_MACOS}
${FRAMEWORK_MACOS}: ${TARGETDIR} openssl_mac libssh2_mac libgit2_mac
openssl_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="mac-catalyst-x86_64" --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="mac-catalyst-x86_64" --verbose --version=$(LIBSSHVER)
libgit2_mac:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="mac-catalyst-x86_64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="macOS-x86_64"

build_macos_arm64: ${FRAMEWORK_MACOS_ARM64}
${FRAMEWORK_MACOS_ARM64}: ${TARGETDIR} openssl_mac_arm64 libssh2_mac_arm64 libgit2_mac_arm64
openssl_mac_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="mac-catalyst-arm64" --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_mac_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="mac-catalyst-arm64" --verbose --version=$(LIBSSHVER)
libgit2_mac_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="mac-catalyst-arm64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="macOS-arm64"

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

build_sim_arm64: ${FRAMEWORK_SIM_ARM64}
${FRAMEWORK_SIM_ARM64}: ${TARGETDIR} openssl_sim_arm64 libssh2_sim_arm64 libgit2_sim_arm64
openssl_sim_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_OPENSSL) --targets="ios-sim-cross-arm64" --verbose --ec-nistp-64-gcc-128 --version=${OPENSSLVER}
libssh2_sim_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBSSH) --targets="ios-sim-cross-arm64" --verbose --version=$(LIBSSHVER)
libgit2_sim_arm64:
	cd ./$(TARGETDIR) && \
	$(BUILD_LIBGIT) --targets="ios-sim-cross-arm64" --verbose && \
	$(CREATE_FRAMEWORK) --targets="simulator-arm64"

framework_static: build_ios build_macos build_macos_arm64 build_sim build_sim_arm64 libgit2.xcframework
libgit2.xcframework:
	lipo -create $(STATIC_MACOS) $(STATIC_MACOS_ARM64) -output libgit2static_catalyst.a
	xcodebuild -create-xcframework \
		-library $(STATIC_IOS) \
		-library libgit2static_catalyst.a \
		-library ${STATIC_SIM_ARM64} \
		-output libgit2.xcframework

codesign:
	codesign_identity=$(security find-identity -v -p codesigning | grep A33F2F2 | grep -o -E '\w{40}' | head -n 1)
	codesign -f --deep -s 769B34C9C0E7AA7E0B0D60FF33C9F6F565288DBC libgit2.xcframework

clean:
	@echo " Cleaning...";
	@$(RM) -r $(TARGETDIR)
	@$(RM) libgit2static_*.a
.PHONY: clean
