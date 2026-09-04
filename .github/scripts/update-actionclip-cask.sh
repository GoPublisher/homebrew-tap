#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cask_file="$repository_root/Casks/actionclip.rb"
release_api="https://updates.actionclip.app/api/releases/latest"

scratch_directory="$(mktemp -d)"
metadata_file="$scratch_directory/release.json"
dmg_file="$scratch_directory/ActionClip.dmg"

cleanup() {
  rm -f "$metadata_file" "$dmg_file"
  rmdir "$scratch_directory"
}
trap cleanup EXIT

curl --fail --location --silent --show-error \
  "$release_api" \
  --output "$metadata_file"

release_fields="$({ ruby -rjson -e '
  document = JSON.parse(File.read(ARGV.fetch(0)))
  release = document.fetch("latest")
  dmg = release.fetch("assets").find { |asset| asset["kind"] == "dmg" }
  abort "The latest stable release has no DMG asset" unless dmg

  values = [
    document.fetch("channel"),
    release.fetch("status"),
    release.fetch("version"),
    release.fetch("build"),
    dmg.fetch("url"),
    dmg.fetch("sha256"),
  ]
  abort "Release metadata contains a tab or newline" if values.any? { |value| value.to_s.match?(/[\t\r\n]/) }
  puts values.join("\t")
' "$metadata_file"; } 2>&1)" || {
  printf '%s\n' "$release_fields" >&2
  exit 1
}

IFS=$'\t' read -r channel status version build dmg_url published_sha256 <<<"$release_fields"

[[ "$channel" == "stable" ]] || {
  echo "Expected the stable channel, received: $channel" >&2
  exit 1
}
[[ "$status" == "published" ]] || {
  echo "Latest stable release is not published: $status" >&2
  exit 1
}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Unexpected release version: $version" >&2
  exit 1
}
[[ "$build" =~ ^[0-9]+$ ]] || {
  echo "Unexpected release build: $build" >&2
  exit 1
}
[[ "$published_sha256" =~ ^[0-9a-f]{64}$ ]] || {
  echo "Unexpected release checksum: $published_sha256" >&2
  exit 1
}

expected_url="https://updates.actionclip.app/releases/$version/ActionClip-$version.dmg"
[[ "$dmg_url" == "$expected_url" ]] || {
  echo "Unexpected DMG URL: $dmg_url" >&2
  exit 1
}

current_version="$(ruby -e 'puts File.read(ARGV.fetch(0))[/^  version "([^"]+)"$/, 1]' "$cask_file")"
current_sha256="$(ruby -e 'puts File.read(ARGV.fetch(0))[/^  sha256 "([0-9a-f]+)"$/, 1]' "$cask_file")"

if [[ "$current_version" == "$version" ]]; then
  if [[ "$current_sha256" != "$published_sha256" ]]; then
    echo "Refusing to update a reused version URL with a different checksum." >&2
    echo "Published ActionClip versions must remain immutable." >&2
    exit 1
  fi

  echo "ActionClip $version ($build) is already current."
  exit 0
fi

curl --fail --location --silent --show-error \
  "$dmg_url" \
  --output "$dmg_file"

downloaded_sha256="$(shasum --algorithm 256 "$dmg_file" | awk '{print $1}')"
[[ "$downloaded_sha256" == "$published_sha256" ]] || {
  echo "Downloaded DMG checksum does not match published release metadata." >&2
  exit 1
}

ACTIONCLIP_CASK_FILE="$cask_file" \
ACTIONCLIP_VERSION="$version" \
ACTIONCLIP_SHA256="$downloaded_sha256" \
ruby <<'RUBY'
path = ENV.fetch("ACTIONCLIP_CASK_FILE")
version = ENV.fetch("ACTIONCLIP_VERSION")
sha256 = ENV.fetch("ACTIONCLIP_SHA256")
content = File.read(path)

version_changes = content.gsub!(/^  version "[^"]+"$/, %(  version "#{version}"))
sha_changes = content.gsub!(/^  sha256 "[0-9a-f]+"$/, %(  sha256 "#{sha256}"))
abort "Could not update the cask version" unless version_changes
abort "Could not update the cask checksum" unless sha_changes

File.write(path, content)
RUBY

echo "Updated ActionClip cask to $version ($build)."
