//
//  SyncViewController.swift
//  PredictionPOC
//
//  Created by Agrawal, Kishori (US - Mumbai) on 10/9/18.
//  Copyright © 2018 Agrawal, Kishori (US - Mumbai). All rights reserved.
//

import UIKit
import CoreML

class SyncViewController: UIViewController {
    
    private enum SyncStatus: Int {
        case downloading = 0
        case downloaded = 1
        case downloadFailed = 2
        
        case compiling = 3
        case compilingFailed = 4
        
        case savedModel = 5
        case savingModelFailed = 6
        
        case modelReplaced = 7
        case creatingModelFailed = 8
    }

    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    let downloadUrl = URL(string: "https://s3.amazonaws.com/dd-computer-vision-v2/resnet50-chest_xray-5-epoch.mlmodel")!
     
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressView.progress = 0
        self.progressView.isHidden = true
        self.statusLabel.text = nil
        
        syncButton.layer.cornerRadius = 15
        syncButton.layer.borderWidth = 1
        syncButton.layer.borderColor = UIColor.gray.cgColor
    }
    
    @IBAction func startSyncTapped(sender: UIButton) {
        syncButton.isEnabled = false
        initiateDownload()
    }
    
    private func initiateDownload() {
        let task = downloadsSession.downloadTask(with: downloadUrl)
        task.resume()
    }
    
    private func updateProgress(progress: Float = 0, status: SyncStatus) {
        DispatchQueue.main.async {
            switch status {
            case .downloading:
                self.progressView.isHidden = false
                self.progressView.progress = progress
                self.statusLabel.text = "Downloading \(progress * 100)%"
                
            case .downloaded:
                self.progressView.isHidden = false
                self.progressView.progress = progress
                self.statusLabel.text = "Downloaded!"
                
            case .downloadFailed:
                self.progressView.isHidden = true
                self.statusLabel.text = "Failed to download model file!"
                self.syncButton.isEnabled = true
            
            case .compiling:
                self.progressView.isHidden = true
                self.statusLabel.text = "Compiling CoreML model..."
                
            case .compilingFailed:
                self.progressView.isHidden = true
                self.statusLabel.text = "Compiling CoreML model failed"
                self.syncButton.isEnabled = true
                
            case .savedModel:
                self.progressView.isHidden = true
                self.statusLabel.text = "Model compiled and saved!"
                
            case .savingModelFailed:
                self.progressView.isHidden = true
                self.statusLabel.text = "Model could not be saved"
                self.syncButton.isEnabled = true
                
            case .modelReplaced:
                self.progressView.isHidden = true
                self.statusLabel.text = "Model is replaced dynamically and is ready for use!"
                self.syncButton.isEnabled = true
                
            case .creatingModelFailed:
                self.progressView.isHidden = true
                self.statusLabel.text = "Model creation failed"
                self.syncButton.isEnabled = true
            }
        }
    }
    
    private func prepareModelFile(modelUrl: URL) {
        updateProgress(status: .compiling)
        do {
            let compiledUrl = try MLModel.compileModel(at: modelUrl)
            
            // If .mlmodelc is successfully compiled, save it at the permanent location
            saveCompiledModel(compiledUrl: compiledUrl)
            
            //Update model
            let isModelUpdated = Predictor.standard.updateModelWith(url: compiledUrl)
            if isModelUpdated {
                updateProgress(status: .modelReplaced)
            }
            else {
                updateProgress(status: .creatingModelFailed)
            }
        }
        catch {
            updateProgress(status: .compilingFailed)
            print("Compiling model failed \(error)")
        }
    }
    
    private func saveCompiledModel(compiledUrl: URL) {
        // find the app support directory
        let fileManager = FileManager.default
        let appSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory,
                                                       in: .userDomainMask, appropriateFor: compiledUrl, create: true)
        // create a permanent URL in the app support directory
        let permanentUrl = appSupportDirectory.appendingPathComponent(compiledUrl.lastPathComponent)
        do {
            // if the file exists, replace it. Otherwise, copy the file to the destination.
            if fileManager.fileExists(atPath: permanentUrl.absoluteString) {
                _ = try fileManager.replaceItemAt(permanentUrl, withItemAt: compiledUrl)
            } else {
                try fileManager.copyItem(at: compiledUrl, to: permanentUrl)
            }
            updateProgress(status: .savedModel)
        } catch {
            updateProgress(status: .savingModelFailed)
            print("Error during copy: \(error.localizedDescription)")
        }
    }

}

extension SyncViewController: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            updateProgress(progress: progress, status: SyncStatus.downloading)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished: \(location)")
        updateProgress(progress: 1, status: SyncStatus.downloaded)
        prepareModelFile(modelUrl: location)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let errorOccurred = error {
            updateProgress(status: SyncStatus.downloadFailed)
            print("Task failed: \(task), with error: \(errorOccurred)")
        }
        else {
            print("Task completed: \(task)")
        }
    }
    
}
