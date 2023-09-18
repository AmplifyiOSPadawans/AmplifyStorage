//
//  ViewController.swift
//  AmplifyStorage
//
//  Created by David Perez Espino on 18/09/23.
//

import UIKit
import Amplify

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var namesList: UILabel!
    
    
    var takenPhoto: UIImage?
    var nameHolder = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        namesList.lineBreakMode = .byWordWrapping
        namesList.numberOfLines = 0
    }

    @IBAction func openCamera(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func uploadImage(_ sender: UIButton) {
        if let photoData = takenPhoto?.jpegData(compressionQuality: 1)! {
            nameHolder = randomString(length: 10)
            let uploadTask = Amplify.Storage.uploadData(key: nameHolder, data: photoData)
            
            Task {
                for await progress in await uploadTask.progress {
                    print("Upload progress: \(progress)")
                }
                let value = try await uploadTask.value
                print("Upload Completed: \(value)")
            }
            
        }
    }
    
    @IBAction func downloadImage(_ sender: UIButton) {
        Task {
            if nameHolder != "" {
                let downloadTask = Amplify.Storage.downloadData(key: nameHolder)
                
                for await progress in await downloadTask.progress {
                    print("Download progress: \(progress.completedUnitCount)")
                }
                
                let data = try await downloadTask.value
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }
    }
    
    @IBAction func getListNames(_ sender: UIButton) {
        Task {
            let options = StorageListRequest.Options(pageSize: 1000)
            
            let listResult = try await Amplify.Storage.list(options: options)
            
            
            listResult.items.forEach { item in
                namesList.text = (namesList.text ?? "") + "\n\(item.key)"
            }
        }
    }
    
    @IBAction func deleteCurrentPhoto(_ sender: UIButton) {
        Task {
            let removedKey = try await Amplify.Storage.remove(key: nameHolder)
            print("Deleted \(removedKey)")
            nameHolder = ""
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return}
        
        takenPhoto = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
