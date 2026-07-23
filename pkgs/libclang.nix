# Copyright lowRISC Contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
#
# A minimal, Bazel-consumable LLVM tree (clang binary + libclang.so + C++
# runtime), sourced from nixpkgs. Instantiate per LLVM release, e.g.
#   libclang_21 = pkgs.callPackage ./libclang.nix { llvmPackages = pkgs.llvmPackages_21; };
#
# Motivation: OpenTitan's rules_rust bindgen toolchain dlopen's a libclang.so.
# The prebuilt LLVM release Bazel would otherwise download has RUNPATH
# `$ORIGIN/../lib` and relies on the system loader to find libtinfo/libstdc++ --
# which fails under Nix, where bindgen-cli uses the nixpkgs glibc loader that
# ignores /etc/ld.so.cache. The nixpkgs libclang.so instead carries an absolute
# nix-store RUNPATH, so it resolves its own dependencies with no env fix-ups.
#
# Layout mirrors the three targets a bindgen toolchain references:
#   bin/clang, lib/libclang.so, lib/libc++.so
{
  lib,
  runCommand,
  llvmPackages,
  stdenv,
}: let
  inherit (llvmPackages) libclang clang-unwrapped;
  # The C++ runtime the nixpkgs libclang is actually linked against (its RUNPATH
  # points here); exposed under the `libc++.so` name a toolchain expects.
  cxxLib = stdenv.cc.cc.lib;
in
  runCommand "libclang-${libclang.version}" {
    passthru = {inherit (libclang) version;};
    meta.description = "nixpkgs libclang ${libclang.version} tree for a Bazel bindgen toolchain";
  } ''
    mkdir -p $out/bin $out/lib
    ln -s ${clang-unwrapped}/bin/clang $out/bin/clang
    ln -s ${lib.getLib libclang}/lib/libclang.so $out/lib/libclang.so
    ln -s ${cxxLib}/lib/libstdc++.so $out/lib/libc++.so
  ''
