#!/bin/bash

# - Nightly Stack resolver (from www.stackage.org): nightly 2026-10-03
# - hls-powered check from `ghcup tui`
GHC_NIGHTLY_AND_HLS_POWERED_VERSION="9.12.4"

CABAL_LATEST_VERSION="3.16.1.0"

STACK_LATEST_VERSION="3.11.1"

HLS_LATEST_VERSION="2.14.0.0"

ghcup install ghc "${GHC_NIGHTLY_AND_HLS_POWERED_VERSION}"
ghcup set ghc "${GHC_NIGHTLY_AND_HLS_POWERED_VERSION}"

ghcup install cabal "${CABAL_LATEST_VERSION}"
ghcup set cabal "${CABAL_LATEST_VERSION}"

ghcup install stack "${STACK_LATEST_VERSION}"
ghcup set stack "${STACK_LATEST_VERSION}"

ghcup compile hls --git-ref "${HLS_LATEST_VERSION}" --ghc "${GHC_NIGHTLY_AND_HLS_POWERED_VERSION}" --cabal-update
ghcup set hls "${HLS_LATEST_VERSION}"
