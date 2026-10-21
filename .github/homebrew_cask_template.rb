cask "skyward" do
  version "VERSION"

  on_macos do
    arch arm: "arm64", intel: "amd64"

    sha256 arm:   "ARM_SHA256",
           intel: "AMD_SHA256"

    url "https://github.com/aqiyoung/Skyward/releases/download/v#{version}/Skyward-#{version}-macos-#{arch}.dmg"
  end

  name "Skyward"
  desc "Multi-platform proxy client based on ClashMeta"
  homepage "https://github.com/aqiyoung/Skyward"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "Skyward.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-rd", "com.apple.quarantine", "{{appdir}}/Skyward.app"],
        writable_paths: ["Skyward.app"],
        writable_base:  :appdir
  end

  uninstall quit: "com.follow.clash"

  zap trash: [
    "~/Library/Application Support/com.follow.clash",
    "~/Library/Caches/com.follow.clash",
    "~/Library/Preferences/com.follow.clash.plist",
    "~/Library/Saved Application State/com.follow.clash.savedState",
  ]
end
