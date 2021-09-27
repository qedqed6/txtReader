//
//  string+CodingFormat.swift
//  txtReader
//
//  Created by peter on 2021/9/21.
//

import Foundation
import UniversalCharsetDetection

extension String {
    init?(utf8Data: Data) {
        if let str = String(data: utf8Data, encoding: .utf8) {
            self = str
        } else {
            return nil
        }
    }
    
    init?(utf16Data: Data) {
        if let str = String(data: utf16Data, encoding: .utf16) {
            self = str
        } else {
            return nil
        }
    }
    
    init?(GB_18030_2000Data: Data) {
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        let str = NSString(data: GB_18030_2000Data, encoding: encoding)
        if str != nil  {
            self = str! as String
        } else {
            return nil
        }
    }
    
    init?(big5Data: Data) {
        let cfEncoding = CFStringEncodings.big5
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        let str = NSString(data: big5Data, encoding: encoding)
        if str != nil  {
            self = str! as String
        } else {
            return nil
        }
    }
    
    init?(big5_HKSCS_1999Data: Data) {
        let cfEncoding = CFStringEncodings.big5_HKSCS_1999
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        if let str = NSString(data: big5_HKSCS_1999Data, encoding: encoding) {
            self = str as String
        } else {
            return nil
        }
    }
    
    init?(big5_EData: Data) {
        let cfEncoding = CFStringEncodings.big5_E
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        if let str = NSString(data: big5_EData, encoding: encoding) {
            self = str as String
        } else {
            return nil
        }
    }
    
    init?(ansiData: Data) {
        let cfEncoding = CFStringEncodings.dosLatin1
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        if let str = NSString(data: ansiData, encoding: encoding) {
            self = str as String
        } else {
            return nil
        }
    }
    
    static func decoding(data: Data) -> String? {
        guard let encoding = data.detectedCharacterEncoding else {
            return "無法偵測編碼"
        }
        print("encoding : \(encoding)")
        
        switch encoding {
        case "UTF-8":
            if let fileString = Self(utf8Data: data) {
                return fileString
            }
        case "UTF-16":
            if let fileString = Self(utf16Data: data) {
                return fileString
            }
        case "GB18030":
            if let fileString = Self(GB_18030_2000Data: data) {
                return fileString
            }
        case "BIG5":
            print("Start")
            if let fileString = Self(big5_HKSCS_1999Data: data) {
                return fileString
            }
            if let fileString = Self(big5Data: data) {
                return fileString
            }
            if let fileString = Self(big5_EData: data) {
                return fileString
            }
        default:
            return "暫時不支援\(encoding)"
        }
        
        return "解碼失敗\(encoding)"
    }
}
