cask "typeflow" do
  version "0.1.4"
  sha256 "4f2ca19b697d675b2bb8f77eb8cbe549f1e51690554b7f260c779a2825309751"

  url "https://github.com/0hEve/typeflow/releases/download/v#{version}/TypeFlow-#{version}-macos-arm64.zip"
  name "TypeFlow"
  desc "Menu bar app for configurable natural-paced typing"
  homepage "https://github.com/0hEve/typeflow"

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "TypeFlow.app"

  zap trash: "~/Library/Preferences/com.kevin.typeflow.plist"
end
