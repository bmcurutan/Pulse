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
    
    func fetchTeamMembersForCurrentPerson(completion: @escaping (_ success: Bool, _ error: Error?) -> ()) {
        parseClient.getCurrentPerson { (person: PFObject?, error: Error?) in
            if let error = error {
                completion(false, error)
            } else {
                if let person = person {
                    self.currentPerson = person
                    self.parseClient.fetchTeamMembersFor(managerId: person.objectId!, isAscending1: true, isAscending2: nil, orderBy1: ObjectKeys.Person.lastName, orderBy2: nil, isDeleted: false, completion: { (members: [PFObject]?, error: Error?) in
                        if let error = error {
                            completion(false, error)
                        } else {
                            if let members = members {
                                self.teamMembers = members
                                completion(true, nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func refreshTeamMembersData() {
        fetchTeamMembersForCurrentPerson { (success: Bool, error: Error?) in
            if success {
                debugPrint("refresh data successful")
            } else {
                debugPrint("refresh data error: \(error?.localizedDescription)")
            }
        }
    }
    
    func fetchLatestMeetingForTeam(personId: String, orderBy: String, limit: Int, completion: @escaping (PFObject?, Error?) -> ()) {
        
        parseClient.getCurrentPerson { (manager: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("Error getting current person with error: \(error.localizedDescription)")
            } else {
                if let manager = manager {
                    //let predicate = NSPredicate(format: "\(ObjectKeys.Meeting.meetingDate) <= '\(NSDate())'")
                    
                    //debugPrint("predicate in manager is \(predicate)")
                    //debugPrint("manager is \(manager)")
                    
                    self.parseClient.fetchMeetingsFor(personId: personId, managerId: manager.objectId!, meetingDate: nil, orderBy: orderBy , limit: limit, isDeleted: false, predicate: nil, completion: { (meetings: [PFObject]?, error: Error?) in
                        
                        debugPrint("in fetch latest: personId: \(personId), managerId: \(manager.objectId!)")
                        
                        if let error = error {
                            debugPrint("Failed in fetching meetings: \(error.localizedDescription)")
                            completion(nil, error)
                        } else {
                            debugPrint("Success in fetching meetings, \(meetings?.count)")
                            if let meetings = meetings {
                                let meeting = meetings[0]
                                completion(meeting, nil)
                                
                                for meeting in meetings {
                                    debugPrint("meeting is \(meeting)")
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func getSelectedPersonObjectAt(indexPath: IndexPath) -> PFObject? {
        return teamMembers[indexPath.row]
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

        fetchLatestMeetingForTeam(personId: teamMembers[indexPath.row].objectId!, orderBy: ObjectKeys.Meeting.meetingDate, limit: 5) {(meeting: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("error: \(error.localizedDescription)")
            } else {
                debugPrint("meeting is \(meeting)")
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

        fetchLatestMeetingForTeam(personId: teamMembers[indexPath.row].objectId!, orderBy: ObjectKeys.Meeting.meetingDate, limit: 5) {(meeting: PFObject?, error: Error?) in
            if let error = error {
                debugPrint("error: \(error.localizedDescription)")
            } else {
                debugPrint("meeting is \(meeting)")
            }
        }
    
        debugPrint("indexPath.row \(indexPath.row)")
        return cell
    }
}

