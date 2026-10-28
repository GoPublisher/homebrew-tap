cask "actionclip" do
  version "2.3.4,649"
  sha256 "868f2d24ea914884e8ee3607738cf566e847c32e737bea42c63bba7da1c38aae"

  url "https://updates.actionclip.app/releases/#{version.csv.first}-#{version.csv.second}/ActionClip-#{version.csv.first}-#{version.csv.second}.dmg"
  name "ActionClip"
  desc "Run contextual actions on selected text"
  homepage "https://actionclip.app/"

  livecheck do
    url "https://updates.actionclip.app/appcast-v2.xml"
    strategy :sparkle, &:nice_version
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
