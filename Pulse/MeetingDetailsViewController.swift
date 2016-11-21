//
//  MeetingDetailsViewController.swift
//  Pulse
//
//  Created by Bianca Curutan on 11/10/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import Parse
import UIKit

class MeetingDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var personTextField: UITextField! // Person ID // TODO should be name
    
    // TODO use objectkey.survey to display on labels
    @IBOutlet weak var survey1Low: UISwitch! // 0
    @IBOutlet weak var survey1Med: UISwitch! // 1
    @IBOutlet weak var survey1High: UISwitch! // 2
    
    @IBOutlet weak var survey2Low: UISwitch!
    @IBOutlet weak var survey2Med: UISwitch!
    @IBOutlet weak var survey2High: UISwitch!
    
    @IBOutlet weak var survey3Low: UISwitch!
    @IBOutlet weak var survey3Med: UISwitch!
    @IBOutlet weak var survey3High: UISwitch!
    
    var alertController: UIAlertController?
    
    var selectedCardsString: String? = ""
    var selectedCards: [Card] = []
    
    var meeting: Meeting!
    // var survey: Survey!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Meeting"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(onSaveButton(_:)))

        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: "MessageCellNib", bundle: nil), forCellReuseIdentifier: "MessageCell")
        
        alertController = UIAlertController(title: "Error", message: "Error", preferredStyle: .alert)
        alertController?.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Existing meeting
        if nil != meeting {
            personTextField.text = meeting.personId
            
            if let selectedCardsString = meeting.selectedCards {
                self.selectedCardsString = selectedCardsString
                for c in (meeting.selectedCards?.characters)! {
                    switch c {
                    case "d":
                        selectedCards.append(Constants.meetingCards[0])
                    case "n":
                        selectedCards.append(Constants.meetingCards[1])
                    case "p":
                        selectedCards.append(Constants.meetingCards[2])
                    default:
                        break
                    }
                }
            }
            
            let query = PFQuery(className: "Survey")
            query.whereKey(ObjectKeys.Survey.objectId, equalTo: meeting.surveyId)
            query.findObjectsInBackground { (surveys: [PFObject]?, error: Error?) in
                if let error = error {
                    print("Unable to find survey associated with survey id, error: \(error.localizedDescription)")
                } else {
                    if let surveys = surveys {
                        if surveys.count > 0 {
                            let survey = surveys[0]
                            
                            // Reset
                            self.survey1Med.isOn = false
                            self.survey2Med.isOn = false
                            self.survey3Med.isOn = false
                            
                            let survey1Value = survey[ObjectKeys.Survey.surveyValueId1] as! Int
                            if survey1Value == 0 {
                                self.survey1Low.isOn = true
                            } else if survey1Value == 1 {
                                self.survey1Med.isOn = true
                            } else if survey1Value == 2 {
                                self.survey1High.isOn = true
                            }
                            
                            let survey2Value = survey[ObjectKeys.Survey.surveyValueId2] as! Int
                            if survey2Value == 0 {
                                self.survey2Low.isOn = true
                            } else if survey2Value == 1 {
                                self.survey2Med.isOn = true
                            } else if survey2Value == 2 {
                                self.survey2High.isOn = true
                            }
                            
                            let survey3Value = survey[ObjectKeys.Survey.surveyValueId3] as! Int
                            if survey3Value == 0 {
                                self.survey3Low.isOn = true
                            } else if survey3Value == 1 {
                                self.survey3Med.isOn = true
                            } else if survey3Value == 2 {
                                self.survey3High.isOn = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func onSaveButton(_ sender: UIBarButtonItem) {
        
        let query = PFQuery(className: "Person")
        let firstName = personTextField.text! as String
        query.whereKey("firstName", equalTo: firstName)
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) -> Void in
            if let posts = posts {
                let person = posts[0]
                let personId = person.objectId
        
                debugPrint("no of items in posts: \(posts.count)")
                for post in posts {
                    debugPrint("post contains \(post.objectId!)")
                }
                
                
                // Survey
                let post = PFObject(className: "Survey")
                post["surveyDesc1"] = "happiness"
                post["surveyValueId1"] = (self.survey1Low.isOn ? 0 : (self.survey1High.isOn ? 2 : 1))
                post["surveyDesc2"] = "engagement"
                post["surveyValueId2"] = (self.survey2Low.isOn ? 0 : (self.survey2High.isOn ? 2 : 1))
                post["surveyDesc3"] = "workload"
                post["surveyValueId3"] = (self.survey3Low.isOn ? 0 : (self.survey3High.isOn ? 2 : 1))
                post.saveInBackground(block: { (success: Bool, error: Error?) in
                    
                    if success {
                        ParseClient.sharedInstance().getCurrentPerson(completion: { (person: PFObject?, error: Error?) in
                            if let person = person {
                                let managerId = person.objectId
                                let dictionary: [String: Any] = [
                                    "personId": personId, // TODO
                                    "managerId": managerId,
                                    "surveyId": post.objectId!,
                                    "meetingDate": Date()
                                ]
                                self.meeting = Meeting(dictionary: dictionary)
                                print("survey saved successfully")
                                
                                Meeting.saveMeetingToParse(meeting: self.meeting) { (success: Bool, error: Error?) in
                                    if success {
                                        print("Successfully saved meeting")
                                        let _ = self.navigationController?.popViewController(animated: true)
                                    } else {
                                        self.alertController?.message = "Meeting was unable to be saved"
                                        self.present(self.alertController!, animated: true)
                                    }
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func onSurvey1LowSwitch(_ sender: AnyObject) {
        // survey1Low.isOn = !survey1Low.isOn not working properly
        
        if survey1Low.isOn {
            survey1Med.isOn = false
            survey1High.isOn = false
        }
    }
    
    @IBAction func onSurvey1MedSwitch(_ sender: AnyObject) {
        if survey1Med.isOn {
            survey1Low.isOn = false
            survey1High.isOn = false
        }
    }
    
    @IBAction func onSurvey1HighSwitch(_ sender: AnyObject) {
        if survey1High.isOn {
            survey1Low.isOn = false
            survey1Med.isOn = false
        }
    }
    
    @IBAction func onSurvey2LowSwitch(_ sender: AnyObject) {
        if survey2Low.isOn {
            survey2Med.isOn = false
            survey2High.isOn = false
        }
    }
    
    @IBAction func onSurvey2MedSwitch(_ sender: AnyObject) {
        if survey2Med.isOn {
            survey2Low.isOn = false
            survey2High.isOn = false
        }
    }
    
    @IBAction func onSurvey2HighSwitch(_ sender: AnyObject) {
        if survey2High.isOn {
            survey2Low.isOn = false
            survey2Med.isOn = false
        }
    }
    
    @IBAction func onSurvey3LowSwitch(_ sender: AnyObject) {
        if survey3Low.isOn {
            survey3Med.isOn = false
            survey3High.isOn = false
        }
    }
    
    @IBAction func onSurvey3MedSwitch(_ sender: AnyObject) {
        if survey3Med.isOn {
            survey3Low.isOn = false
            survey3High.isOn = false
        }
    }
    
    @IBAction func onSurvey3HighSwitch(_ sender: AnyObject) {
        if survey3High.isOn {
            survey3Low.isOn = false
            survey3Med.isOn = false
        }
    }
    
    func onAddCard() {
        let storyboard = UIStoryboard(name: "Meeting", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MeetingDetailsSelectionViewController") as! MeetingDetailsSelectionViewController
        viewController.delegate = self
        viewController.selectedCards = selectedCards
        let navController = UINavigationController(rootViewController: viewController)
        present(navController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension MeetingDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == selectedCards.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            cell.message = "Tap here to manage cards"
            return cell
            
            // The actual cards
        } else {
            switch selectedCards[indexPath.row].id! {
            case "d":
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContainerCell", for: indexPath)
                let storyboard = UIStoryboard(name: "Todo", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "TodoVC") as! TodoViewController
                vc.meeting
                self.addChildViewController(vc)
                cell.contentView.addSubview(vc.view)
                return cell
                
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContainerCell", for: indexPath)
                for subview in cell.contentView.subviews  {
                    subview.removeFromSuperview() // Reset subviews
                }
                cell.textLabel?.text = selectedCards[indexPath.row].name
                return cell
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedCards.count + 1
    }
}

// MARK: - UITableViewDelegate

extension MeetingDetailsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        guard indexPath.row < selectedCards.count else {
            return 44
        }
        
        switch selectedCards[indexPath.row].id! {
        // TODO
        default:
            return 44
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row appearance after it has been selected
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == selectedCards.count {
            onAddCard()
        }
    }
}

// MARK: - MeetingDetailsSelectionViewControllerDelegate

extension MeetingDetailsViewController: MeetingDetailsSelectionViewControllerDelegate {
    
    func meetingDetailsSelectionViewController(meetingDetailsSelectionViewController: MeetingDetailsSelectionViewController, didAddCard card: Card) {
        let query = PFQuery(className: "Meetings")
        if let meetingId = meeting.objectId {
            query.whereKey("objectId", equalTo: meetingId)
        }
        
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            if let posts = posts,
                let id = card.id,
                let selectedCardsString = self.selectedCardsString {
                
                if posts.count > 0 {
                    let post = posts[0]
                    self.selectedCardsString = "\(id)\(selectedCardsString)"
                    post["selectedCards"] = selectedCardsString
                    post.saveInBackground { (success: Bool, error: Error?) in
                        if success {
                            print("successfully saved meeting card")
                        } else {
                            print(error?.localizedDescription)
                        }
                    }
                } else {
                    let post = PFObject(className: "Meetings")
                    post["selectedCards"] = selectedCardsString
                    post.saveInBackground()
                }
            } else {
                print(error?.localizedDescription)
            }
        }
        
        // Insert new card at the top of the table view
        selectedCards.insert(card, at: 0)
        tableView.reloadData()
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows!, with: .none)
    }
    
    func meetingDetailsSelectionViewController(meetingDetailsSelectionViewController: MeetingDetailsSelectionViewController, didRemoveCard card: Card) {
        
        let query = PFQuery(className: "Meetings")
        if let meetingId = meeting.objectId {
            query.whereKey("objectId", equalTo: meetingId)
        }
        
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            if let posts = posts,
                let id = card.id,
                let selectedCardsString = self.selectedCardsString {
                
                if posts.count > 0 {
                    let post = posts[0]
                    self.selectedCardsString = selectedCardsString.replacingOccurrences(of: id, with: "")
                    post["selectedCards"] = selectedCardsString
                    post.saveInBackground { (success: Bool, error: Error?) in
                        print("successfully removed dashboard card")
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
        
        // Remove card from table view
        for (index, dashboardCard) in selectedCards.enumerated() {
            if dashboardCard.id == card.id {
                selectedCards.remove(at: index)
            }
        }
        tableView.reloadData()
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows!, with: .none)
    }
}
