cask "ghostty" do
  version :latest
  sha256 :no_check
  depends_on macos: ">= :monterey"

  name "Ghostty"
  desc "Fast, native, feature-rich terminal emulator pushing modern features."
  homepage "https://github.com/mitchellh/ghostty"
  url do
    assets = GitHub.get_release("mitchellh", "ghostty", "tip").fetch("assets")
    latest = assets.find{|a| a["name"] == "ghostty-macos-universal.zip" }.fetch("url")
    [latest, header: [
      "Accept: application/octet-stream",
      "Authorization: bearer #{GitHub::API.credentials}"
    ]]
  end

  app "Ghostty.app"

  zap trash: [
    "~/Library/Caches/com.mitchellh.ghostty",
    "~/Library/HTTPStorages/com.mitchellh.ghostty",
    "~/Library/Preferences/com.mitchellh.ghostty.plist",
    "~/Library/Saved Application State/com.mitchellh.ghostty.savedState",
  ]
end
