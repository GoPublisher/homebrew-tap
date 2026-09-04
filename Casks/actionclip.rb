cask "actionclip" do
  version "2.1.1"
  sha256 "630f84834a40b44ab1d2cc8ff3463a011c9d8a3e98e97bfcbcae518b1b9ece91"

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
