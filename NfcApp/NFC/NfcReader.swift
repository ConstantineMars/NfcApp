//
//  NfcReader.swift
//  NfcApp
//
//  Created by Constantine Mars on 2/21/21.
//

import Foundation
import CoreNFC

class NfcReader: NSObject, NFCNDEFReaderSessionDelegate {
    private var delegate: NfcReaderDelegate? = nil
    
    init(delegate: NfcReaderDelegate) {
        self.delegate = delegate
    }
    
    func read() {
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        
        session.alertMessage = "Hold your device near a tag to scan it."
        
        session.begin()
    }
    
    //    MARK: - NFCNDEFReaderSessionDelegate
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("Started scanning for tags")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Session did invalidate with error: \(error)")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        print("Detected tags with \(messages.count) messages")
        
        let record = messages.first!.records.first
        
        print("\t\t\tidentifier: \(String(describing: String(data: record!.identifier, encoding: .utf8)))")
        print("\t\t\ttype: \(String(describing: String(data: record!.type, encoding: .utf8)))")
        print("\t\t\tpayload: \(String(describing: String(data: record!.payload, encoding: .utf8)))")
        
        DispatchQueue.main.async {
            let tag = String(data: record!.payload, encoding: .utf8)!.replacingOccurrences(of: "^(\0)*", with: "", options: .regularExpression)
            self.delegate?.onTagRead(tag: tag)
        }
    }
}

protocol NfcReaderDelegate {
    func onTagRead(tag: String)
}
