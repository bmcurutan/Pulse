//
//  GraphViewController.swift
//  Pulse
//
//  Created by Bianca Curutan on 11/20/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import Parse
import SwiftChart
import UIKit

class GraphViewController: UIViewController {

    @IBOutlet weak var chartTitleLabel: UILabel!
    
    @IBOutlet weak var chart1: Chart!
    @IBOutlet weak var chart2: Chart!
    @IBOutlet weak var chart3: Chart!
    
    var survey1Values: [Float] = []
    var survey2Values: [Float] = []
    var survey3Values: [Float] = []
    var personIdValues: [String] = []
    var highLowValues = ["Poor", "Good", "Great"]
    
    var parseClient = ParseClient.sharedInstance()
    var teamMemberIds = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadChartForCompany(false)
    }
    
    // isCompany == true, load chart for whole company
    // isCompany == false, load chart for my team only
    func loadChartForCompany(_ isCompany: Bool) {
        
        // Reset values
        survey1Values = []
        survey2Values = []
        survey3Values = []
        
        chartTitleLabel.text = isCompany ? "Company Pulse" : "Team Pulse"
        
        let query = PFQuery(className: "Survey")
        query.whereKey("companyId", equalTo: "Pulse")
        
        // filter by last 30 days
        var pastDate = Date() // this is current date
        pastDate.addTimeInterval(-30*24*60*60)
        query.whereKey("meetingDate", greaterThan: pastDate)
        query.order(byDescending: "meetingDate")
        
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            if let posts = posts {
                self.fetchMyTeamMembers() { (success: Bool, error: Error?) in
                    if nil != error {
                        print("Error fetched team members")
                    } else {
                        print("Successfully fetched team members")
                        for post in posts {
                            if let personId = post["personId"] as? String {
                                if isCompany {
                                    if !self.personIdValues.contains(personId) {
                                        self.survey1Values.append(post["surveyValueId1"] as! Float)
                                        self.survey2Values.append(post["surveyValueId2"] as! Float)
                                        self.survey3Values.append(post["surveyValueId3"] as! Float)
                                        self.personIdValues.append(personId)
                                    }
                                } else {
                                    if !self.personIdValues.contains(personId) &&
                                        self.teamMemberIds.contains(personId) {
                                        self.survey1Values.append(post["surveyValueId1"] as! Float)
                                        self.survey2Values.append(post["surveyValueId2"] as! Float)
                                        self.survey3Values.append(post["surveyValueId3"] as! Float)
                                        self.personIdValues.append(personId)
                                    }
                                }
                            }
                        }
                    }
                }
                self.setupCharts()
            }
        }
    }
    
    func fetchMyTeamMembers(completion: @escaping (_ success: Bool, _ error: Error?) -> ()) {
        parseClient.getCurrentPerson { (person: PFObject?, error: Error?) in
            if let error = error {
                completion(false, error)
            } else {
                if let person = person {
                    self.parseClient.fetchTeamMembersFor(managerId: person.objectId!, isAscending1: true, isAscending2: nil, orderBy1: ObjectKeys.Person.lastName, orderBy2: nil, isDeleted: false) { (members: [PFObject]?, error: Error?) in
                        if let error = error {
                            completion(false, error)
                        } else {
                            if let members = members, members.count > 0 {
                                for member in members {
                                    if let personId = member.objectId,
                                        !self.teamMemberIds.contains(personId) {
                                        self.teamMemberIds.append(personId)
                                    }
                                }
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
    }
    
    func setupCharts() {
        chart1.backgroundColor = UIColor.clear
        chart2.backgroundColor = UIColor.clear
        chart3.backgroundColor = UIColor.clear
        
        if personIdValues.count > 0 {
            var data1: [(x: Float, y: Float)] = []
            var data2: [(x: Float, y: Float)] = []
            var data3: [(x: Float, y: Float)] = []
            
            for i in 0...personIdValues.count-1 {
                data1.append((x: Float(i), y: survey1Values[i])) // Happiness
                data2.append((x: Float(i), y: survey2Values[i])) // Engagement
                data3.append((x: Float(i), y: survey3Values[i])) // Workload
            }
            
            let survey1Series = ChartSeries(data: data1)
            survey1Series.color = UIColor.pulseAccentColor()
            survey1Series.area = true
            chart1.add(survey1Series)
            
            let survey2Series = ChartSeries(data: data2)
            survey2Series.color = UIColor.pulseAccentColor()
            survey2Series.area = true
            chart2.add(survey2Series)
            
            let survey3Series = ChartSeries(data: data3)
            survey3Series.color = UIColor.pulseAccentColor()
            survey3Series.area = true
            chart3.add(survey3Series)
        }

        chart1.labelColor = UIColor.pulseLightPrimaryColor()
        chart1.lineWidth = 2
        chart1.yLabels = [0, 1, 2]
        chart1.yLabelsFormatter = { self.highLowValues[Int($1)] }
        
        
        chart2.labelColor = UIColor.pulseLightPrimaryColor()
        chart2.lineWidth = 2
        chart2.yLabels = [0, 1, 2]
        chart2.yLabelsFormatter = { self.highLowValues[Int($1)] }

        chart3.labelColor = UIColor.pulseLightPrimaryColor()
        chart3.lineWidth = 2
        chart3.yLabels = [0, 1, 2]
        chart3.yLabelsFormatter = { self.highLowValues[Int($1)] }
        
        UIView.animate(withDuration: 1, animations: {
            self.chart1.alpha = 1.0
            self.chart2.alpha = 1.0
            self.chart3.alpha = 1.0
        })
    }

    func heightForView() -> CGFloat {
        // Calculated with bottom-most element (y position + height + 8)
        return 282 + 80 + 8
    }

    @IBAction func onChartSwitch(_ sender: UISwitch) {
        if sender.isOn { // Team pulse
            loadChartForCompany(false)
        } else { // Company pulse
            loadChartForCompany(true)
        }
    }
}
