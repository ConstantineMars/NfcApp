//
//  NfcWriter.swift
//  NfcApp
//
//  Created by Constantine Mars on 2/20/21.
//

import Foundation
import CoreNFC

class NfcWriter: NSObject, NFCNDEFReaderSessionDelegate {
    
    var delegate: NfcWriterDelegate? = nil
    var ndefMessage: NFCNDEFMessage?
    
    init(delegate: NfcWriterDelegate) {
        self.delegate = delegate
    }
    
    func write(tag: String) {
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false
        )
        session.alertMessage = "Hold your device near a tag to write it."
        
        self.createPayload(tag: tag)
        
        session.begin()
    }
    
    //    MARK: - NFCNDEFReaderSessionDelegate
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("Started scanning for tags")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Session did invalidate with error: \(error)")
    }
    
    private func createPayload(tag: String) {
        let urlComponent = URLComponents(string: tag)
        let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent?.url)!)
        
        self.ndefMessage = NFCNDEFMessage(records: [
            urlPayload!
        ])
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        
        if tags.count > 1 {
            session.alertMessage = "More than 1 tags found. Please present only 1 tag."
            return
        }
        
        // You connect to the desired tag.
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            if error != nil {
                session.restartPolling()
                return
            }
            
            // You then query the NDEF status of tag.
            tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                    return
                }
                
                if status == .readOnly {
                    print("readOnly")
                    session.invalidate(errorMessage: "Tag is not writable.")
                } else if status == .readWrite {
                    print("readWrite")
                    
                    if self.ndefMessage!.length > capacity {
                        session.invalidate(errorMessage: "Tag capacity is too small.  Minimum size requirement is \(self.ndefMessage!.length) bytes.")
                        return
                    }
                    
                    tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                        if error != nil {
                            session.invalidate(errorMessage: "Update tag failed. Please try again.")
                            
                            DispatchQueue.main.async {
                                self.delegate?.onWriteError()
                            }
                            //                            print(error?.localizedDescription)
                        } else {
                            session.alertMessage = "Update success!"
                            session.invalidate()
                            
                            DispatchQueue.main.async {
                                self.delegate?.onWriteSuccess()
                            }
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("readerSession didDetectNDEFs")
    }
}
protocol NfcWriterDelegate {
    func onWriteSuccess()
    func onWriteError()
}
