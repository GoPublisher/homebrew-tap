cask "actionclip" do
  version "2.3.2"
  sha256 "46698037f478c42e419687fd96b9b786b495c0628bb3ef14b24a38754a5e5985"

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
