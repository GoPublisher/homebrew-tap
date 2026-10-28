cask "actionclip" do
  version "2.3.4"
  sha256 "7c960ad9f056707d9e687df853903454708b2209ac41c0829f1cbebad3c26420"

  url "https://updates.actionclip.app/releases/#{version}/ActionClip-#{version}.dmg"
  name "ActionClip"
  desc "Run contextual actions on selected text"
  homepage "https://actionclip.app/"

  livecheck do
    url "https://updates.actionclip.app/appcast-v2.xml"
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
