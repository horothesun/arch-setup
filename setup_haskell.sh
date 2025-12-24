#!/bin/bash

STACK_LATEST_VERSION="3.7.1"

HLS_LATEST_VERSION="2.12.0.0"

CABAL_LATEST_VERSION="3.16.0.0"

# - LATEST stable Stack resolver (from www.stackage.org): "LTS 24.25"
# - hls-powered check from `ghcup tui`
GHC_LTS_24_25_AND_HLS_POWERED_VERSION="9.10.3"

ghcup install stack "${STACK_LATEST_VERSION}"
ghcup set stack "${STACK_LATEST_VERSION}"

ghcup install hls "${HLS_LATEST_VERSION}"
ghcup set hls "${HLS_LATEST_VERSION}"

ghcup install cabal "${CABAL_LATEST_VERSION}"
ghcup set cabal "${CABAL_LATEST_VERSION}"

ghcup install ghc "${GHC_LTS_24_25_AND_HLS_POWERED_VERSION}"
ghcup set ghc "${GHC_LTS_24_25_AND_HLS_POWERED_VERSION}"
