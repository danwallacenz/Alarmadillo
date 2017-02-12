//
//  AlarmViewController.swift
//  Alarmadillo
//
//  Created by Daniel Wallace on 12/02/17.
//  Copyright © 2017 Daniel Wallace. All rights reserved.
//

import UIKit

class AlarmViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var caption: UITextField!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var tapToSelectImage: UILabel!
    
    var alarm: Alarm!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = alarm.name
        name.text = alarm.name
        caption.text = alarm.caption
        datePicker.date = alarm.time
        
        if alarm.image.characters.count > 0 {
            // if we have an image, try to load it
            let imageFilename = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            imageView.image = UIImage(contentsOfFile: imageFilename.path)
            tapToSelectImage.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        alarm.time = sender.date
    }
    
    @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // 1: dismiss the image picker
        dismiss(animated: true)
        
        // 2: fetch the image that was picked
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        let fm = FileManager()
        
        if alarm.image.characters.count > 0 {
            // 3: the alarm already has an image, so delete it
            do {
                let currentImage = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
                
                if fm.fileExists(atPath: currentImage.path) {
                    try fm.removeItem(at: currentImage)
                }
            } catch {
                print("Failed to remove current image")
            }
        }
        
        do {
            // 4: generate a new filename for the image
            alarm.image = "\(UUID().uuidString).jpg"
            
            // 5: write the new image to the documents directory
            let newPath = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            
            let jpeg = UIImageJPEGRepresentation(image, 80)
            try jpeg?.write(to: newPath)
        } catch {
            print("Failed to save new image")
        }
        
        // 6: update the user interface
        imageView.image = image
        tapToSelectImage.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        alarm.name = name.text!
        alarm.caption = caption.text!
        title = alarm.name
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
