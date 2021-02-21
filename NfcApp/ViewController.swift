//
//  ViewController.swift
//  NfcApp
//
//  Created by Constantine Mars on 2/17/21.
//

import UIKit
import CoreNFC

class ViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var ndefMessage: NFCNDEFMessage?
    var isWriting: Bool = false
    
    @IBAction func readNfcButtonClicked(_ sender: Any) {
        guard NFCReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        label.text = "available"
        
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )

        session.alertMessage = "Hold your device near a tag to scan it."

        session.begin()
    }
    
    @IBAction func writeNfcButtonClicked(_ sender: Any) {
        guard NFCReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        isWriting = true
        
        label.text = "available"
        
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false
        )

        session.alertMessage = "Hold your device near a tag to write it."

        session.begin()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
    }
    
    private func createPayload() {
        DispatchQueue.main.sync {
            let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                string: textField.text!,
                locale: Locale(identifier: "En")
            )
            
//            let urlComponent = URLComponents(string: "https://fishtagcreator.example.com/")
//            let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent?.url)!)
            
            ndefMessage = NFCNDEFMessage(records: [
    //                                        urlPayload!,
                                            textPayload!
            ])
        }
        
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
                
                for messageIndex in 0 ..< messages.count {
                    
                    let message = messages[messageIndex]
                    print("\tMessage \(messageIndex) with length \(message.length)")
                    
//                    for recordIndex in 0 ..< message.records.count {
                        
                        let record = message.records.first // [recordIndex]
//                        print("\t\tRecord \(recordIndex)")
                
                    print("\t\t\tidentifier: \(String(describing: String(data: record!.identifier, encoding: .utf8)))")
                    print("\t\t\ttype: \(String(describing: String(data: record!.type, encoding: .utf8)))")
                    print("\t\t\tpayload: \(String(describing: String(data: record!.payload, encoding: .utf8)))")
                        DispatchQueue.main.async {
                            self.label.text = "From tag: \(String(describing: String(data: record!.payload, encoding: .utf8)!))"
                        }
//                    }
                }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if (!isWriting) {
            return
        }
        isWriting = false

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
                    self.createPayload()
                    tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                        if error != nil {
                            print(error?.localizedDescription!)
                            session.invalidate(errorMessage: "Update tag failed. Please try again.")
                        } else {
                            session.alertMessage = "Update success!"
                            session.invalidate()
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                }
            }
        }
    }
}

