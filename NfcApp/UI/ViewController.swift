//
//  ViewController.swift
//  NfcApp
//
//  Created by Constantine Mars on 2/17/21.
//

import UIKit
import CoreNFC

class ViewController: UIViewController, NfcReaderDelegate, NfcWriterDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var nfcWriter: NfcWriter? = nil
    var nfcReader: NfcReader? = nil
    
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
        
        nfcReader?.read()
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
        
        label.text = "available"
        let tag = self.textField.text!

        self.nfcWriter?.write(tag: tag)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        
        nfcReader = NfcReader(delegate: self)
        nfcWriter = NfcWriter(delegate: self)
    }
    
//    MARK: - NfcReaderDelegate
    
    func onTagRead(tag: String) {
        self.label.text = tag
    }
    
//    MARK: - NfcWriterDelegate
    func onWriteSuccess() {
        label.text = "Success"
    }
    
    func onWriteError() {
        label.text = "Error"
    }
}

