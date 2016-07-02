#!/usr/bin/env sh
set -euo pipefail

PLATFORM="linux"
REPO="https://dl.google.com/android/repository/"
REPOXML="${REPO}repository-11.xml"

fetch_repository_xml() {
  echo "Fetching ${REPOXML}" >&2
  wget -q -O - "$REPOXML"
}

parse_repository_xml() {
  echo "Parsing repository" >&2
  cat | awk -vplatform="$PLATFORM" '
    BEGIN {
      RS = "<[^>]*>"
    }

    RT == "<sdk:platform-tool>" {
      in_platform_tools = 1
    }

    in_platform_tools && RT == "<sdk:archive>" {
      in_platform_tools_archive = 1
      os = ""
      sha = ""
      url = ""
    }

    in_platform_tools_archive && RT == "</sdk:url>" {
      url = $1
    }

    in_platform_tools_archive && RT == "</sdk:checksum>" {
      sha = $1
    }

    in_platform_tools_archive && RT == "</sdk:host-os>" && $1 == platform {
      in_platform_tools_archive_linux = 1
    }

    in_platform_tools_archive_linux && RT == "</sdk:archive>" {
      in_platform_tools_archive_linux = 0
      print sha " " url
    }

    in_platform_tools_archive && RT == "</sdk:archive>" {
      in_platform_tools_archive = 0;
      os = ""
      sha = ""
      url = ""
    }

    in_platform_tools && RT == "</sdk:platform-tool>" {
      in_platform_tools = 0
    }
  '
}

install_platform_tools() {
  local SHA="$1"
  local URL="$2"
  local TMPFILE=$(mktemp)

  mkdir -p /opt
  echo "Fetching ${URL}" >&2
  wget -O "$TMPFILE" "${REPO}${URL}"
  echo "Verifying sha1 checksum ${SHA}" >&2
  echo "$SHA  $TMPFILE" | sha1sum -sc

  echo "Removing previous version of platform tools if any" >&2
  rm -rf /opt/platform-tools

  echo "Unpacking platform tools" >&2
  unzip -d /opt "$TMPFILE"
  rm "$TMPFILE"

  echo "Platform tools installed!" >&2
}

install_platform_tools $(fetch_repository_xml | parse_repository_xml)
