//
//  PersonDetailsViewController.swift
//  Pulse
//
//  Created by Alejandra Negrete on 11/13/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

class PersonDetailsViewController: UIViewController {

	@IBOutlet weak var photoImageView: PhotoImageView!
	@IBOutlet weak var firstNameTextField: UITextField!
	@IBOutlet weak var lastNameTextField: UITextField!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var phoneTextField: UITextField!
	@IBOutlet weak var callButton: UIButton!

	var photoData: Data?
	var person: Person?
    var personPFObject: PFObject?

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		initPerson()
		initImage()
		initViews()
	}

	// MARK: - Initializations

	func initImage() {
		photoImageView.delegate = self
		photoImageView.isEditable = true
	}

	func initPerson() {

		if let pfObject = personPFObject {

			let firstName =  pfObject[ObjectKeys.Person.firstName] as! String
			let lastName = pfObject[ObjectKeys.Person.lastName] as! String

            firstNameTextField.text = firstName
            lastNameTextField.text = lastName
            phoneTextField.text = pfObject[ObjectKeys.Person.phone] as? String
            emailTextField.text = pfObject[ObjectKeys.Person.email] as? String
			photoImageView.pffile = pfObject[ObjectKeys.Person.photo] as? PFFile

            parent?.navigationItem.title = firstName + " " + lastName
            setEditing(false, animated: true)
        }
		else {
			parent?.navigationItem.title = "New team member"
			setEditing(true, animated: true)
		}
	}

	func initViews() {
		callButton.layer.cornerRadius = 5
	}

	func heightForView() -> CGFloat {
		return 200; // TODO heightForView
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

	func onRightBarButtonTap(_ sender: UIBarButtonItem) {

		if isEditing {

			if isValid() {

				if personPFObject != nil {

					let personCurrentEmail:String = personPFObject![ObjectKeys.Person.email] as! String
					let personNewEmail:String = emailTextField.text!

					if  personCurrentEmail != personNewEmail {
						validateIfPersonExists(completion: { (success: Bool, error: Error?) in
							if (success) {
								self.editPerson()
								self.setEditing(false, animated: true)
							}
						})
					}
					else {
						editPerson()
						self.setEditing(false, animated: true)
					}
				}
				else {
					validateIfPersonExists(completion: { (success: Bool, error: Error?) in
						if (success) {
							self.createPerson()
							self.setEditing(false, animated: true)
						}
					})
				}
			}
		}
		else {
			setEditing(true, animated: true)
		}
	}

	// MARK: - Helpers

	func isValid() -> Bool {

		if (firstNameTextField.text?.isEmpty)! {
			ABIShowAlert(title: "Error!",
			          message: "First Name cannot be empty", sender: nil, handler: nil)
			return false
		}

		if (emailTextField.text?.isEmpty)! {
			ABIShowAlert(title: "Error!",
			          message: "Email cannot be empty", sender: nil, handler: nil)
			return false
		}

		if !emailTextField.text!.isValidEmail() {
			ABIShowAlert(title: "Error!",
			             message: "Please enter a valid email", sender: nil, handler: nil)
			return false
		}

		if !(phoneTextField.text?.isEmpty)! && !(phoneTextField.text?.isValidPhone())! {
			ABIShowAlert(title: "Error!",
			             message: "Please enter a valid phone", sender: nil, handler: nil)
			return false
		}

		return true
	}

	func validateIfPersonExists(completion: @escaping (_ success: Bool, _ error: Error?) -> ()) {

		ParseClient.sharedInstance().fetchPersonFor(email: emailTextField.text!) {
			(person: PFObject?, error: Error?) in

			if error != nil {
				completion(true, error)
			}
			else {
				self.ABIShowAlert(title: "Error!", message: "User already exists. Please enter a new email", sender: nil, handler: nil)
			}
		}
	}

	// MARK: - Edit/Save

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		parent?.setEditing(editing, animated: animated)

		phoneTextField.isUserInteractionEnabled = isEditing
		emailTextField.isUserInteractionEnabled = isEditing
		lastNameTextField.isUserInteractionEnabled = isEditing
		firstNameTextField.isUserInteractionEnabled = isEditing
		photoImageView.isUserInteractionEnabled = isEditing

		phoneTextField.borderStyle = isEditing ? .roundedRect : .none
		emailTextField.borderStyle = isEditing ? .roundedRect : .none
		lastNameTextField.borderStyle = isEditing ? .roundedRect : .none
		firstNameTextField.borderStyle = isEditing ? .roundedRect : .none

		callButton.isHidden = isEditing || (phoneTextField.text?.isEmpty)!
	}

	func editPerson() {

		NSLog("Editing current person")

		if let pfPerson = personPFObject {
			SVProgressHUD.show()
			let firstName = firstNameTextField.text!
			pfPerson[ObjectKeys.Person.firstName] = firstName

			let lastName = (lastNameTextField.text?.isEmpty)! ? firstName : lastNameTextField.text
			pfPerson[ObjectKeys.Person.lastName] = lastName
			lastNameTextField.text = lastName

			pfPerson[ObjectKeys.Person.email] = emailTextField.text
			pfPerson[ObjectKeys.Person.phone] = phoneTextField.text

			if let photoData = photoData {
				SVProgressHUD.show()

				Person.savePhotoInPerson(parsePerson: pfPerson, photo: photoData, withCompletion: {
					(success: Bool, error: Error?) in
					self.updatePersonFinished(success: success, error: error)
				})

			}
			else {
				pfPerson.saveInBackground(block: {
					(success: Bool, error: Error?) in
					self.updatePersonFinished(success: success, error: error)
				})
			}
		}
	}

	func updatePersonFinished(success: Bool, error: Error?) {

		SVProgressHUD.dismiss()

		if success {
			self.ABIShowAlert(title: "Success", message: "Update team member successful", sender: nil, handler: { (alertAction: UIAlertAction) in
				let _ = self.navigationController?.popViewController(animated: true)
			})
		}
		else {
			self.ABIShowAlert(title: "Error", message: "Unable to update team member with error: \(error?.localizedDescription)", sender: nil, handler: nil)
		}
	}


	func createPerson() {

		NSLog("Creating new person")

		validateIfPersonExists(completion: { (success: Bool, error: Error?) in
			if (success) {
				self.editPerson()
			}
		})

		let firstName = firstNameTextField.text!
		let lastName = (lastNameTextField.text?.isEmpty)! ? firstName : lastNameTextField.text
		lastNameTextField.text = lastName

		person = Person(firstName: firstName,
		                lastName: lastName!)
		person?.email = emailTextField.text
		person?.phone = phoneTextField.text
		person?.photo = photoData

		ParseClient.sharedInstance().getCurrentPerson(completion: { (manager: PFObject?, error: Error?) in
			if let error = error {
				debugPrint("Error finding the person matching current user, error: \(error.localizedDescription)")
			} else {
				self.person?.managerId = manager?.objectId
				self.person?.companyId = manager?[ObjectKeys.Person.companyId] as? String
				let positionId = (manager?[ObjectKeys.Person.positionId] as? String)!
				self.person?.positionId = String(Int(positionId)! - 1)

				Person.savePersonToParse(person: self.person!) {
					(success: Bool, error: Error?) in
					if success {
						self.ABIShowAlert(title: "Success", message: "Team member created successfully!", sender: nil, handler: { (alertAction: UIAlertAction) in
							SVProgressHUD.dismiss()
							self.dismiss(animated: true, completion: nil)
							NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.Team.addTeamMemberSuccessful), object: self, userInfo: nil)
						})
					}
				}
			}
		})
	}
}

// MARK: - PhotoImageViewDelegate

extension PersonDetailsViewController : PhotoImageViewDelegate {

	func didSelectImage(sender: PhotoImageView) {
		self.photoData = sender.photoData
	}
}
