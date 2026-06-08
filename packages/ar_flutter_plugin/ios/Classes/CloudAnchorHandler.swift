import Foundation

// Cloud Anchors stubbed out — ARCore removed to fix nanopb conflict with Firebase.
// This app uses ARKit only; Cloud Anchor functionality is not needed.

protocol CloudAnchorListener {
    func onCloudTaskComplete(anchorName: String?, anchor: AnyObject?)
}

class CloudAnchorHandler: NSObject {
    override init() { super.init() }

    func hostCloudAnchor(anchorName: String, anchor: AnyObject?, listener: CloudAnchorListener?) {}
    func hostCloudAnchorWithTtl(anchorName: String, anchor: AnyObject?, listener: CloudAnchorListener?, ttl: Int) {}
    func resolveCloudAnchor(anchorId: String, listener: CloudAnchorListener?) {}
    func clearListeners() {}
}
