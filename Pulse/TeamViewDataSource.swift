//
//  TeamViewDataSource.swift
//  Pulse
//
//  Created by Itasari on 11/13/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit
import Parse

@objc protocol TeamViewDataSourceDelegate {
    @objc optional func teamViewDataSource(_ teamViewDataSource: TeamViewDataSource, at indexPath: IndexPath)
}

class TeamViewDataSource: NSObject {
    
    // MARK: - Properties
    
    var parseClient = ParseClient.sharedInstance()
    //var teamMembers = [Person]()
    var teamMembers = [PFObject]()
    //var meetings = [Meeting]()
    var currentPerson: PFObject?
    
    weak var delegate: TeamViewDataSourceDelegate?
    
    // MARK: - Shared instance
    class func sharedInstance() -> TeamViewDataSource {
        struct Singleton {
            static var sharedInstance = TeamViewDataSource()
        }
        return Singleton.sharedInstance
    }
    
    func fetchTeamMembersForCurrentPerson(person: PFObject?, completion: @escaping (_ success: Bool, _ error: Error?) -> ()) {
        if person == nil { // In Dashboard
            parseClient.getCurrentPerson { (person: PFObject?, error: Error?) in
                if let error = error {
                    completion(false, error)
                } else {
                    if let person = person {
                        self.currentPerson = person
                        self.parseClient.fetchTeamMembersFor(managerId: person.objectId!, isAscending1: true, isAscending2: nil, orderBy1: ObjectKeys.Person.lastName, orderBy2: nil, isDeleted: false) { (members: [PFObject]?, error: Error?) in
                            if let error = error {
                                completion(false, error)
                            } else {
                                if let members = members, members.count > 0 {
                                    self.teamMembers = members
                                    completion(true, nil)
                                } else {
                                    debugPrint("Fetch members returned 0 members")
                                    completion(true, nil)
                                }
                            }
                        }
                    }
                }
            }
        } else { // In Person
            self.currentPerson = person!
            parseClient.fetchTeamMembersFor(managerId: person!.objectId!, isAscending1: true, isAscending2: nil, orderBy1: ObjectKeys.Person.lastName, orderBy2: nil, isDeleted: false) { (members: [PFObject]?, error:Error?) in
                if let error = error {
                    completion(false, error)
                } else {
                    if let members = members, members.count > 0 {
                        self.teamMembers = members
                        completion(true, nil)
                    } else {
                        debugPrint("Fetch members returned 0 members")
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    /*
    func refreshTeamMembersData() {
        fetchTeamMembersForCurrentPerson { (success: Bool, error: Error?) in
            if success {
                debugPrint("refresh data successful")
            } else {
                debugPrint("refresh data error: \(error?.localizedDescription)")
            }
        }
    }*/
    
    func fetchLatestSurveyFor(personId: String, orderBy: String, limit: Int, completion: @escaping (PFObject?, Error?) -> ()) {
        parseClient.getCurrentPerson { (manager: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("Error getting current person with error: \(error.localizedDescription)")
                completion(nil, error)
            } else {
                if let manager = manager {
                    // TODO: check if meeting < current date?
                    
                    self.parseClient.fetchMeetingsFor(personId: personId, managerId: manager.objectId!, meetingDate: nil, isAscending: false, orderBy: orderBy, limit: limit, isDeleted: false) { (meetings: [PFObject]?, error: Error?) in
                        
                        if let error = error {
                            debugPrint("Failed in fetching meetings: \(error.localizedDescription)")
                            completion(nil, error)
                        } else {
                            debugPrint("Success in fetching meetings, \(meetings?.count)")
                            if let meetings = meetings, meetings.count > 0 {
                                let meeting = meetings[0]
                                
                                if let surveyId = meeting[ObjectKeys.Meeting.surveyId] as? String {
                                    self.parseClient.fetchSurveyFor(surveyId: surveyId, isAscending: nil, orderBy: nil) { (survey: PFObject?, error: Error?) in
                                        if let error = error {
                                            completion(nil, error)
                                        } else {
                                            completion(survey, nil)
                                        }
                                    }
                                } else {
                                    debugPrint("Could not find key surveyId in Meeting object")
                                    completion(nil, error)
                                }
                            } else {
                                let userInfo = [NSLocalizedDescriptionKey: "Fetch meeting returned 0 meeting"]
                                let error = NSError(domain: "TeamViewDataSource fetchLatestSurvey", code: 0, userInfo: userInfo)
                                completion(nil, error)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getSelectedPersonObjectAt(indexPath: IndexPath) -> PFObject? {
        return teamMembers[indexPath.row]
    }
    
    func isPersonManager(personId: String, isDeleted: Bool, isManager: @escaping (Bool, Error?)->()) {
        parseClient.isPersonManager(personId: personId, isDeleted: isDeleted, isManager: isManager)
    }
    
    func removeSelectedPersonObjectAt(indexPath: IndexPath, completion: @escaping (Bool, Error?)->()) {
        // update Parse
        let person = teamMembers[indexPath.row]
        person[ObjectKeys.Person.deletedAt] = Date()
        
        person.saveInBackground { (success: Bool, error: Error?) in
            if success {
                debugPrint("Deleting \(person) successful")
                self.teamMembers.remove(at: indexPath.row)
                completion(true, nil)
            } else {
                debugPrint("Unable to delete \(person) with error: \(error?.localizedDescription)")
                completion(false, error)
            }
        }
    }
    
    func numberOfMembers() -> Int {
        return teamMembers.count
    }
}

extension TeamViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseIdentifier.Team.teamListCell, for: indexPath) as! TeamTableViewCell
        let firstName = teamMembers[indexPath.row][ObjectKeys.Person.firstName] as? String ?? ""
        let lastName = teamMembers[indexPath.row][ObjectKeys.Person.lastName] as? String ?? ""
        cell.firstNameLabel.text = "\(firstName) \(lastName)"
        cell.emailLabel.text = teamMembers[indexPath.row][ObjectKeys.Person.email] as? String

		cell.profileImageView.pffile = teamMembers[indexPath.row][ObjectKeys.Person.photo] as? PFFile

        fetchLatestSurveyFor(personId: teamMembers[indexPath.row].objectId!, orderBy: ObjectKeys.Meeting.meetingDate, limit: 1) { (survey: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("Unable to fetch survey data: \(error.localizedDescription)")
            } else {
                debugPrint("survey is \(survey)")
                cell.survey = survey
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate?.teamViewDataSource?(self, at: indexPath)
        }
    }
}

extension TeamViewDataSource: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        debugPrint("teamMembers count: \(teamMembers.count)")
        return teamMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdentifier.Team.teamCollectionCell, for: indexPath) as! TeamCollectionCell

        let firstName = teamMembers[indexPath.row][ObjectKeys.Person.firstName] as? String ?? ""
        let lastName = teamMembers[indexPath.row][ObjectKeys.Person.lastName] as? String ?? ""
        cell.nameLabel.text = "\(firstName) \(lastName)"
		cell.profileImageView.pffile = teamMembers[indexPath.row][ObjectKeys.Person.photo] as? PFFile
        cell.profileImageView.layer.cornerRadius = 5

        fetchLatestSurveyFor(personId: teamMembers[indexPath.row].objectId!, orderBy: ObjectKeys.Meeting.meetingDate, limit: 1) {(survey: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("error: \(error.localizedDescription)")
            } else {
                //debugPrint("survey is \(survey)")
                cell.survey = survey
            }
        }
    
        return cell
    }
}

