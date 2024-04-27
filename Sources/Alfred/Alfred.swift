import Foundation

public class Alfred {
  private static let fs: FileManager = FileManager.default
  private static let home: URL = fs.homeDirectoryForCurrentUser

  // Declare type prop as optional via '?' to allow for later reassignment
  // https://stackoverflow.com/questions/36557858/swift-how-to-declare-a-static-member-variable-which-is-a-class
  static var appBundlePath: URL?
    if fs.fileExists(atPath: "/Applications/Alfred 5.app") {
      appBundlePath = URL(fileURLWithPath: "/Applications/Alfred 5.app")
    } else {
      appBundlePath = URL(fileURLWithPath: "/Applications/Alfred 4.app")
    }

  private static let alfredPlist: Plist =
    Plist(path: appBundlePath/"Contents"/"Info.plist")

  static let bundleID: String = alfredPlist.get(
    "CFBundleIdentifier",
    orElse: "com.runningwithcrayons.Alfred"
  )

  public static let appSupportDir: URL =
    home/"Library"/"Application Support"/"Alfred"

  public static let cacheDir: URL =
    home/"Library"/"Caches"/bundleID

  public static let prefsDir: URL = {
    let prefsJsonPath = appSupportDir/"prefs.json"
    if let dict = jsonObj(contentsOf: prefsJsonPath) {
      if let dirPath = dict["current"] as? String {
        return URL(fileURLWithPath: dirPath)
      }
    }
    return URL(fileURLWithPath: "/dev/null")
  }()

  public static let localPrefsDir: URL = {
    let localPrefsParent = Alfred.prefsDir/"preferences"/"local"
    if let localHash = envVarsAtInvocation?.prefsLocalHash {
      return localPrefsParent/localHash
    }
    log("Local prefs dir not available from env vars.")
    let localPrefsDirs = localPrefsParent.subDirs()
    if localPrefsDirs.count > 1 {
      let dirNames = localPrefsDirs.map(\.pathComponents.last!)
      log("Found multiple local preference dirs: \(dirNames)")
      log("Using: \(dirNames[0])")
    } else if localPrefsDirs.count == 0 {
      log("Error: found no local prefs dir in \(localPrefsParent.path)")
    }
    return localPrefsDirs[0]
  }()

  public static let isInstalled: Bool = fs.exists(appBundlePath)

  public static let build: Int =
    Int(alfredPlist.get("CFBundleVersion", orElse: "0"))!

  public static let version: Semver = Semver(alfredPlist.get(
    "CFBundleShortVersionString",
    orElse: "0.0.0"
  ))!
}
