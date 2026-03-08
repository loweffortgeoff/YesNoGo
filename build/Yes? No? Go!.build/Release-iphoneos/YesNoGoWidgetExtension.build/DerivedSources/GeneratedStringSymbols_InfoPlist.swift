// 
// GeneratedStringSymbols_InfoPlist.swift
// Auto-Generated symbols for localized strings defined in “InfoPlist.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private let resourceBundleDescription = LocalizedStringResource.BundleDescription.atURL(resourceBundle.bundleURL)
#else

private class ResourceBundleClass {}
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private let resourceBundleDescription = LocalizedStringResource.BundleDescription.forClass(ResourceBundleClass.self)
#endif

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension LocalizedStringResource {
    /// Namespace for strings in file “InfoPlist.xcstrings”.
    enum InfoPlist {
        /**
         Localized string for key “CFBundleDisplayName” in table “InfoPlist.xcstrings”.
         */
        static var cfbundleDisplayName: LocalizedStringResource {
            LocalizedStringResource("CFBundleDisplayName", table: "InfoPlist", bundle: resourceBundleDescription)
        }
    }
}