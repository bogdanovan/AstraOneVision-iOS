//
//  ViewController.swift
//  AstraOne Vision
//
//  Created by Anatolii Bogdanov on 08/02/2019.
//  Copyright © 2019 bogdanof. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var categoryLavel: [UILabel]!
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)) as UIActivityIndicatorView
    let imagePicker = UIImagePickerController()
    
    private var timer: Timer?
    private var timerCount: Int = 0
    
    private let firstImageCategories = ["• city car", "• car", "• watch", "• man", "• city view", "• driving"]
    private let secondImageCategories = ["• footwear", "• shoe", "• beach", "• leg", "• jeans", "• vacation"]
    private let thirdImageCategories = ["• nail", "• finger", "• hand", "• manicure", "• beauty", "• bracelet"]
    private let fourthImageCategories = ["• grass", "• football", "• green", "• player", "• football shoes", "• ball"]
    private let fifthImageCategories = ["• technology", "• electronic device", "• mobile phone", "• audio equipment", "• headphones", "• gadget"]
    
    private var arrayOfCategoriesForImages = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arrayOfCategoriesForImages.append(contentsOf: [firstImageCategories, secondImageCategories, thirdImageCategories, fourthImageCategories, fifthImageCategories])
        
        timerStart()
    }
    
    // MARK: setting initial slideshow
    @objc private func slideMainImage() {
        for index in 1...6 {
            if let currentCatLabel = self.view.viewWithTag(index) as? UILabel {
                currentCatLabel.text = arrayOfCategoriesForImages[timerCount][index - 1]
            }
        }
        
        imageView.image = UIImage(named: "mainVCimage\(timerCount + 1)")
        timerCount = timerCount != 4 ? timerCount + 1 : 0
    }
    

    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            timerStop()
            settingActivityIndicator()
            self.activityIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                DispatchQueue.main.sync {
                    self!.imageView.image = image
                    self!.imagePicker.dismiss(animated: true, completion: nil)
                    
                    print("yyy")
                }
                
                guard let ciimage = CIImage(image: image) else {
                    fatalError("Error converting Uiimage to Ciimage")
                }
                
                self!.imageDetection(image: ciimage)
            }
        }
    }
    
    
    func imageDetection(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Error converting Inception to VNCoreMLModle")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("Error converting result to Classification")
            }

            DispatchQueue.main.sync {
                self.settingImgCategories(result)
                self.activityIndicator.stopAnimating()
                
                if let loadingView = self.view.viewWithTag(100) {
                    loadingView.removeFromSuperview()
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    

    @IBAction func uploadButtomPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Choose from gallery", style: .default) { (action) in
            self.openGallery()
        })
        
        alert.addAction(UIAlertAction(title: "Take a picture", style: .default) { (alert) in
            self.openCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    private func settingActivityIndicator() {
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = imageView.center
        loadingView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        loadingView.tag = 100
        
        activityIndicator.center = loadingView.center
        activityIndicator.frame = CGRect(x: loadingView.frame.width/4, y: loadingView.frame.height/4, width: 40, height: 40)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .whiteLarge
        
        loadingView.addSubview(activityIndicator)
        self.view.addSubview(loadingView)
    }
    
    
    private func settingImgCategories(_ result: [VNClassificationObservation]) {
        for index in 1...6 {
            let isConfident = result[index - 1].confidence < 0.5
            
            guard let label = self.view.viewWithTag(index) as? UILabel else {
                fatalError("Error getting element by tag")
            }
            
            if isConfident {
                if index == 1 {
                    label.text = "Невозможно определить объекты"
                } else {
                    label.isHidden = true
                }
            } else if !isConfident {
                label.text = "• \(result[index - 1].identifier) - \(round(10000 * result[index - 1].confidence) / 100) %"
            }
        }
    }
    
    
    private func timerStart() {
        if timer == nil {
            slideMainImage()
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(ViewController.slideMainImage), userInfo: nil, repeats: true)
        }
    }
    
    private func timerStop() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    
    private func openCamera() {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "There is no camera on this device", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func openGallery() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }

}

