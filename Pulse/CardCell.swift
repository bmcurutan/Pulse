//
//  CardCell.swift
//  Pulse
//
//  Created by Bianca Curutan on 11/10/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit

protocol CardCellDelegate: class {
    func cardCell(cardCell: CardCell, didMoveUp card: Card)
    func cardCell(cardCell: CardCell, didMoveDown card: Card)
    func cardCell(cardCell: CardCell, didDelete card: Card)
}

class CardCell: UITableViewCell {

    weak var delegate: CardCellDelegate?
    
    var informationView: UIView!
    var originalCenter: CGPoint!
    
    var card: Card! {
        didSet {
            /*let testVC = MeetingDetailsViewController()
            let nib = UINib(nibName: "MeetingDetailsViewController", bundle: nil)
            let objects = nib.instantiate(withOwner: testVC, options: nil)
            let newView = objects.first as! UIView
            newView.frame = contentView.frame

            let longPressGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
            longPressGesture.delegate = self
            newView.addGestureRecognizer(longPressGesture)
            
            contentView.addSubview(newView)
            
            trailingSpaceConstraint = NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: newView, attribute: .trailing, multiplier: 1, constant: 20)
            newView.addConstraint(trailingSpaceConstraint)*/
            
        }
    }
    
    @objc fileprivate func onPanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)
        let velocity = sender.velocity(in: contentView)
        
        if sender.state == UIGestureRecognizerState.began {
            originalCenter = sender.view?.center
            
        } else if sender.state == UIGestureRecognizerState.changed {
            sender.view?.center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            
        } else if sender.state == UIGestureRecognizerState.ended {
            UIView.animate(withDuration: 0.3,
                animations: {
                    if velocity.x > 0 { // Hide action view
                        self.informationView.center = self.contentView.center
                    } else { // Show action view
                        self.informationView.center = CGPoint(x: self.originalCenter.x - 100, y: self.originalCenter.y)
                    }
                    //self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let testVC = MeetingDetailsViewController()
        let nib = UINib(nibName: "MeetingDetailsViewController", bundle: nil)
        let objects = nib.instantiate(withOwner: testVC, options: nil)
        informationView = objects.first as! UIView
        informationView.frame = contentView.frame
        
        let longPressGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        longPressGesture.delegate = self
        informationView.addGestureRecognizer(longPressGesture)
        
        contentView.addSubview(informationView)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onUpButton(_ sender: AnyObject) {
        print("up")
        delegate?.cardCell(cardCell: self, didMoveUp: card)
    }

    @IBAction func onDownButton(_ sender: AnyObject) {
        print("down")
        delegate?.cardCell(cardCell: self, didMoveDown: card)
    }
    
    @IBAction func onDeleteButton(_ sender: AnyObject) {
        print("delete")
        delegate?.cardCell(cardCell: self, didDelete: card)
    }
}