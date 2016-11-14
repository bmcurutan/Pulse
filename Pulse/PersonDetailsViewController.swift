//
//  PersonDetailsViewController.swift
//  Pulse
//
//  Created by Alejandra Negrete on 11/13/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit
import AFNetworking
import Parse

class PersonDetailsViewController: UIViewController {

	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var firstNameTextField: UITextField!
	@IBOutlet weak var lastNameTextField: UITextField!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var phoneTextField: UITextField!
	@IBOutlet weak var callButton: UIButton!
	@IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var scheduleMeetingLabel: UILabel!
	@IBOutlet weak var scheduleMeetingDatePicker: UIDatePicker!

	let imagePicker = UIImagePickerController()
	var photoData: Data?
	var person: Person?

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		initPerson()
		initImage()
		initViews()
	}

	// MARK: - Initializations

	func initImage() {
		imagePicker.delegate = self

		profileImageView.layer.cornerRadius = 3
		profileImageView.clipsToBounds = true

		if let photo = person?.photoUrl {
			profileImageView.setImageWith(photo)
		}
	}

	func initPerson() {
		if let person = person {
			firstNameTextField.text = person.firstName
			lastNameTextField.text = person.lastName
			phoneTextField.text = person.phone
			emailTextField.text = person.email

			navigationItem.title = person.firstName + " " + person.lastName
			setEditing(false, animated: true)
		}
		else {
			navigationItem.title = "New team member"
			setEditing(true, animated: true)
		}
	}

	func initViews() {
		callButton.layer.cornerRadius = 3
	}

	// MARK: - UI Actions

	@IBAction func didTapCallButton(_ sender: UIButton) {

		let okAction = UIAlertAction(title: "Phone", style: .default, handler: {
			(UIAlertAction) in
			if let phone = self.person?.phone {
				UIApplication.shared.callNumber(phoneNumber: phone)
			}
		})

		let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
		let alertController = UIAlertController(
			title: "Call",
			message: "Are you sure you want to call this number?",
			preferredStyle: .alert)

		alertController.addAction(okAction)
		alertController.addAction(cancelAction)
		present(alertController, animated: true, completion: nil)
	}

	@IBAction func onRightBarButtonTap(_ sender: UIBarButtonItem) {

		if isEditing {
			if isValid() {
				setEditing(false, animated: true)
				savePerson()
			}
		}
		else {
			setEditing(true, animated: true)
		}
	}

	func isValid() -> Bool {
		if (firstNameTextField.text?.isEmpty)! {
			showAlert(title: "Error!",
			          message: "First Name cannot be empty", sender: nil, handler: nil)
			return false
		}

		if (lastNameTextField.text?.isEmpty)! {
			showAlert(title: "Error!",
			          message: "Last Name cannot be empty", sender: nil, handler: nil)
			return false
		}

		if (emailTextField.text?.isEmpty)! {
			showAlert(title: "Error!",
			          message: "Email cannot be empty", sender: nil, handler: nil)
			return false
		}

		return true
	}


	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)

		phoneTextField.isUserInteractionEnabled = isEditing
		emailTextField.isUserInteractionEnabled = isEditing
		lastNameTextField.isUserInteractionEnabled = isEditing
		firstNameTextField.isUserInteractionEnabled = isEditing
		profileImageView.isUserInteractionEnabled = isEditing

		phoneTextField.borderStyle = isEditing ? .roundedRect : .none
		emailTextField.borderStyle = isEditing ? .roundedRect : .none
		lastNameTextField.borderStyle = isEditing ? .roundedRect : .none
		firstNameTextField.borderStyle = isEditing ? .roundedRect : .none

		callButton.isHidden = isEditing || (phoneTextField.text?.isEmpty)!
		scheduleMeetingLabel.isHidden = person == nil
		scheduleMeetingDatePicker.isHidden = person == nil

		rightBarButtonItem.title = isEditing ? "Save" : "Edit"
	}


	func savePerson() {

		if let person = person {
			NSLog("Editing current person")
			// TODO: Save current person to Parse
		}
		else {
			NSLog("Creating new person")
			person = Person(firstName: firstNameTextField.text!,
			                lastName: lastNameTextField.text!)
			person?.email = emailTextField.text
			person?.phone = phoneTextField.text
			person?.photo = photoData

			Person.savePersonToParse(person: person!) {
				(success: Bool, error: Error?) in
				NSLog("Created ok!")
			}
		}
	}

	// MARK: - Image

	@IBAction func didTapProfileImageView(_ sender: UITapGestureRecognizer) {
		showAlertAction()
	}

	func showAlertAction() {

		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let chooseFromLibraryAction = UIAlertAction(title: "Choose from library", style: .default) {
			(UIAlertAction) in
			self.chooseFromLibrary()
		}

		let takeProfilePhotoAction = UIAlertAction(title: "Take profile photo", style: .default) {
			(UIAlertAction) in
			self.takeProfilePhoto()
		}

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alertController.addAction(chooseFromLibraryAction)
		alertController.addAction(takeProfilePhotoAction)
		alertController.addAction(cancelAction)

		present(alertController, animated: true, completion: nil)
	}

	func takeProfilePhoto() {
		imagePicker.allowsEditing = false
		imagePicker.sourceType = UIImagePickerControllerSourceType.camera
		imagePicker.cameraCaptureMode = .photo
		imagePicker.modalPresentationStyle = .fullScreen
		present(imagePicker, animated: true, completion: nil)
	}

	func chooseFromLibrary() {
		imagePicker.allowsEditing = false
		imagePicker.sourceType = .photoLibrary
		present(imagePicker, animated: true, completion: nil)
	}
}

// MARK: - UIImagePickerControllerDelegate

extension PersonDetailsViewController : UIImagePickerControllerDelegate {

	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
		profileImageView.contentMode = .scaleAspectFill
		profileImageView.image = chosenImage
		profileImageView.layer.cornerRadius = 3
		profileImageView.clipsToBounds = true

		let scaledImage = scaleImageWith(newImage: chosenImage, newSize: CGSize(width: 120, height: 120))
		photoData = UIImagePNGRepresentation(scaledImage)

		dismiss(animated: true, completion: nil)
	}

	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}

	func scaleImageWith(newImage:UIImage, newSize:CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
		newImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
		UIGraphicsEndImageContext()
		return newImage
	}
}

// MARK: - UINavigationControllerDelegate

extension PersonDetailsViewController : UINavigationControllerDelegate {
}
