cask "actionclip" do
  version "2.3.0"
  sha256 "6d8d2b5afbf829505cffe3e2fb8f3ae556d64aa0119397588fa524ccff498efc"

  url "https://updates.actionclip.app/releases/#{version}/ActionClip-#{version}.dmg"
  name "ActionClip"
  desc "Run contextual actions on selected text"
  homepage "https://actionclip.app/"

  livecheck do
    url "https://updates.actionclip.app/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sequoia

  app "ActionClip.app"

  uninstall quit:       "app.actionclip.ActionClip",
            login_item: "ActionClip"

  zap trash: [
    "~/Library/Application Support/ActionClip",
    "~/Library/Caches/app.actionclip.ActionClip",
    "~/Library/HTTPStorages/app.actionclip.ActionClip",
    "~/Library/Preferences/app.actionclip.ActionClip.plist",
    "~/Library/Saved Application State/app.actionclip.ActionClip.savedState",
    "~/Library/WebKit/app.actionclip.ActionClip",
  ]
end
