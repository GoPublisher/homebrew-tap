cask "actionclip" do
  version "2.3.5,651"
  sha256 "fa60eae1d1735ee5ade4c49b78b9a9369887530e94caede57f4aa097e8db352c"

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
