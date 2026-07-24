# Copyright lowRISC contributors.
#
# SPDX-License-Identifier: MIT
#
# OpenTitan pins an exact Bazel version in its `.bazelversion`, and both
# `bazelisk` and Bazel itself refuse to run a mismatched version. Rather than
# let bazelisk download that version over the network at runtime (non-hermetic,
# and the download lands in a per-user cache that is easy to get out of sync
# with the dev environment), we pin the official prebuilt release binary here.
#
# When this is on PATH, OpenTitan's `bazelisk.sh` detects it (its version
# matches `.bazelversion`) and uses it directly instead of downloading anything.
#
# NOTE: this deliberately does NOT patchelf the binary. The Bazel release is a
# self-extracting executable with a zip of its embedded JDK/tools appended after
# the ELF image; patchelf would corrupt that trailer. The binary is dynamically
# linked against a standard FHS runtime (interpreter /lib64/ld-linux-x86-64.so.2)
# and the eda FHS shell provides one. This is byte-for-byte the same binary
# bazelisk would fetch, so runtime behaviour is unchanged — only the fetch is now
# hermetic and version-pinned.
{
  lib,
  stdenvNoCC,
  fetchurl,
  bazel_8,
}:
stdenvNoCC.mkDerivation rec {
  pname = "bazel";
  version = "8.7.0";

  src = fetchurl {
    url = "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel-${version}-linux-x86_64";
    hash = "sha256-12BuZ5t4BnyBEJb7PWzxNSJbUog1yjluOk3d+VeFlUQ=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/bazel
    # bazelisk/Bazel release binaries ship no shell completion; borrow the
    # (version-agnostic) completion scripts from nixpkgs' Bazel, matching the
    # behaviour of the bazelisk-based package this replaces.
    cp -r ${bazel_8}/share $out/share
    runHook postInstall
  '';

  meta = {
    description = "Bazel ${version} official prebuilt release, pinned to OpenTitan's .bazelversion (expects an FHS runtime)";
    homepage = "https://bazel.build";
    license = lib.licenses.asl20;
    mainProgram = "bazel";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
}
