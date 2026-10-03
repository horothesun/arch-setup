#!/bin/bash

# - LATEST stable Stack resolver (from www.stackage.org): "LTS 24.61"
# - hls-powered check from `ghcup tui`
GHC_LTS_24_61_AND_HLS_POWERED_VERSION="9.10.3"

CABAL_LATEST_VERSION="3.16.1.0"

STACK_LATEST_VERSION="3.11.1"

HLS_LATEST_VERSION="2.14.0.0"

ghcup install ghc "${GHC_LTS_24_61_AND_HLS_POWERED_VERSION}"
ghcup set ghc "${GHC_LTS_24_61_AND_HLS_POWERED_VERSION}"

ghcup install cabal "${CABAL_LATEST_VERSION}"
ghcup set cabal "${CABAL_LATEST_VERSION}"

ghcup install stack "${STACK_LATEST_VERSION}"
ghcup set stack "${STACK_LATEST_VERSION}"

ghcup compile hls --git-ref "${HLS_LATEST_VERSION}" --ghc "${GHC_LTS_24_61_AND_HLS_POWERED_VERSION}" --cabal-update
ghcup set hls "${HLS_LATEST_VERSION}"
