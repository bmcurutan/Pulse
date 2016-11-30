//
//  TeamTableViewCell.swift
//  Pulse
//
//  Created by Itasari on 11/14/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit
import Parse

class TeamTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: PhotoImageView!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var surveyValue1Button: UIButton!
    @IBOutlet weak var surveyValue2Button: UIButton!
    @IBOutlet weak var surveyValue3Button: UIButton!
    
    var survey: PFObject! {
        didSet {
            let surveyValue1 = survey[ObjectKeys.Survey.surveyValueId1] as? Int ?? 99
            let surveyValue2 = survey[ObjectKeys.Survey.surveyValueId2] as? Int ?? 99
            let surveyValue3 = survey[ObjectKeys.Survey.surveyValueId3] as? Int ?? 99
            debugPrint("surveyValue1 is \(surveyValue1)")
            debugPrint("surveyValue2 is \(surveyValue2)")
            debugPrint("surveyValue3 is \(surveyValue3)")
            
            setUpSurvey1(value: surveyValue1)
            setUpSurvey2(value: surveyValue2)
            setUpSurvey3(value: surveyValue3)
        }
    }
    
    // happiness
    fileprivate func setUpSurvey1(value: Int) {
        switch value {
        case 0:
            surveyValue1Button.tintColor = UIColor.red
            surveyValue1Button.backgroundColor = UIColor.clear
        case 1:
            surveyValue1Button.tintColor = UIColor.yellow
            surveyValue1Button.backgroundColor = UIColor.clear
        case 2:
            surveyValue1Button.tintColor = UIColor.green
            surveyValue1Button.backgroundColor = UIColor.clear
        default:
            surveyValue1Button.tintColor = UIColor.black
        }
    }
    
    // engagement
    fileprivate func setUpSurvey2(value: Int) {
        switch value {
        case 0:
            surveyValue2Button.tintColor = UIColor.red
            surveyValue2Button.backgroundColor = UIColor.clear
        case 1:
            surveyValue2Button.tintColor = UIColor.yellow
            surveyValue2Button.backgroundColor = UIColor.clear
        case 2:
            surveyValue2Button.tintColor = UIColor.green
            surveyValue2Button.backgroundColor = UIColor.clear
        default:
            surveyValue2Button.tintColor = UIColor.black
        }
    }
    
    // workload
    fileprivate func setUpSurvey3(value: Int) {
        switch value {
        case 0:
            surveyValue3Button.tintColor = UIColor.green
            surveyValue3Button.backgroundColor = UIColor.clear
        case 1:
            surveyValue3Button.tintColor = UIColor.yellow
            surveyValue3Button.backgroundColor = UIColor.clear
        case 2:
            surveyValue3Button.tintColor = UIColor.red
            surveyValue3Button.backgroundColor = UIColor.clear
        default:
            surveyValue3Button.tintColor = UIColor.black
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        surveyValue1Button.tintColor = UIColor.clear
        surveyValue2Button.tintColor = UIColor.clear
        surveyValue3Button.tintColor = UIColor.clear
    }
}
