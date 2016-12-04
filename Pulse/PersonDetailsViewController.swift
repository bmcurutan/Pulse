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
	@IBOutlet weak var emailButton: UIButton!

	var photoData: Data?
	var person: Person?
    var personPFObject: PFObject?
	var personInfoParentViewController: Person2DetailsViewController?

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
        personInfoParentViewController?.navigationItem.title = "New Team Member"

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
			lastNameTextField.text = firstName == lastName ? "" : lastName
            phoneTextField.text = pfObject[ObjectKeys.Person.phone] as? String
            emailTextField.text = pfObject[ObjectKeys.Person.email] as? String
			photoImageView.pffile = pfObject[ObjectKeys.Person.photo] as? PFFile

            personInfoParentViewController?.navigationItem.title = firstName + " " + lastName
            setEditing(false, animated: true)
        }
		else {
			setEditing(true, animated: true)
		}
	}

	func initViews() {
		callButton.layer.cornerRadius = 5
		phoneTextField.delegate = PhoneTextFieldDelegate.shared
	}

	func heightForView() -> CGFloat {
		return 150; // TODO heightForView
	}

	// MARK: - UI Actions

	@IBAction func didTapEmailButton(_ sender: UIButton) {
		if let email = emailTextField.text {
			UIApplication.shared.mailTo(email: email)
		}
	}

	@IBAction func didTapCallButton(_ sender: UIButton) {
		if let phone = self.phoneTextField.text {
			UIApplication.shared.call(phoneNumber: phone)
		}
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
			ABIShowDropDownAlert(type: AlertTypes.alert, title: "Alert!", message: "First Name cannot be empty")
			return false
		}

		if (emailTextField.text?.isEmpty)! {
			ABIShowDropDownAlert(type: AlertTypes.alert, title: "Alert!", message: "Email cannot be empty")
			return false
		}

		if !emailTextField.text!.isValidEmail() {
			ABIShowDropDownAlert(type: AlertTypes.alert, title: "Alert!", message: "Please enter a valid email")
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
				self.ABIShowDropDownAlert(type: AlertTypes.alert, title: "Alert!", message: "User already exists. Please enter a new email")
			}
		}
	}

	func configureButton(textField: UITextField, button: UIButton) {
		let text = textField.text ?? ""
		let buttonTitle = NSMutableAttributedString(
			string:text,
			attributes: [NSForegroundColorAttributeName : UIColor.pulseAccentColor(),
			             NSUnderlineStyleAttributeName : 1] as [String : Any])
		textField.isHidden = !isEditing
		button.isHidden = isEditing || text == ""
		button.setAttributedTitle(buttonTitle, for: .normal)
	}

	override func viewDidLayoutSubviews() {
		setupViews()
	}

	func setupViews() {

		if isEditing {
			UIExtensions.setupDarkViewFor(textField: firstNameTextField)
			UIExtensions.setupDarkViewFor(textField: lastNameTextField)
			UIExtensions.setupDarkViewFor(textField: emailTextField)
			UIExtensions.setupDarkViewFor(textField: phoneTextField)
		}
		else {
			phoneTextField.layer.sublayers?[0].removeFromSuperlayer()
			emailTextField.layer.sublayers?[0].removeFromSuperlayer()
			lastNameTextField.layer.sublayers?[0].removeFromSuperlayer()
			firstNameTextField.layer.sublayers?[0].removeFromSuperlayer()
		}
	}

	// MARK: - Edit/Save

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		personInfoParentViewController?.setEditing(editing, animated: animated)

		phoneTextField.isUserInteractionEnabled = isEditing
		emailTextField.isUserInteractionEnabled = isEditing
		lastNameTextField.isUserInteractionEnabled = isEditing
		firstNameTextField.isUserInteractionEnabled = isEditing
		photoImageView.isUserInteractionEnabled = isEditing

		configureButton(textField: phoneTextField, button: callButton)
		configureButton(textField: emailTextField, button: emailButton)

		setupViews()
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
			ABIShowDropDownAlert(type: AlertTypes.success, title: "Success!", message: "Successfully updated team member")
		}
		else {
			ABIShowDropDownAlert(type: AlertTypes.failure, title: "Error", message: "Unable to update team member")
			debugPrint(error?.localizedDescription as Any)
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
						self.ABIShowDropDownAlert(
							type: AlertTypes.success,
							title: "Success!",
							message: "Successfully added team member")
						SVProgressHUD.dismiss()
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.Team.addTeamMemberSuccessful), object: self, userInfo: nil)
                        
                        // Temporary fix to pop page after new person was created to "hide" bugs
                        // Really though, if new person is created, page shouldn't be popped so the user can still use that page to add To Do items, meetings, etc.
                        self.navigationController?.popViewController(animated: true)
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
