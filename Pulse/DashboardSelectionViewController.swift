//
//  DashboardSelectionViewController.swift
//  Pulse
//
//  Created by Bianca Curutan on 11/9/16.
//  Copyright © 2016 ABI. All rights reserved.
//

import UIKit

protocol DashboardSelectionViewControllerDelegate: class {
    func dashboardSelectionViewController(dashboardSelectionViewController: DashboardSelectionViewController, didDismissSelector _: Bool)
    func dashboardSelectionViewController(dashboardSelectionViewController: DashboardSelectionViewController, didAddCard card: Card)
    func dashboardSelectionViewController(dashboardSelectionViewController: DashboardSelectionViewController, didRemoveCard card: Card)
}

class DashboardSelectionViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: DashboardSelectionViewControllerDelegate?
    var selectedCards: [Card] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Modules"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 5
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: "CustomTextCell", bundle: nil), forCellReuseIdentifier: "CustomTextCell")
    }
    
    // MARK: - IBAction
    
    @IBAction func onDismiss(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
        delegate?.dashboardSelectionViewController(dashboardSelectionViewController: self, didDismissSelector: true)
    }
}

// MARK: - UITableViewDataSource

extension DashboardSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let card = Constants.dashboardCards[indexPath.row]
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTextCell", for: indexPath) as! CustomTextCell
        cell.message = card.name
        cell.submessage = card.descr
        cell.imageName = card.imageName
        
        if selectedCards.contains(card) {
            cell.accessoryType =  .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.dashboardCards.count
    }
}

// MARK: - UITableViewDelegate

extension DashboardSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row appearance after it has been selected
        tableView.deselectRow(at: indexPath, animated: true)
        
        let card = Constants.dashboardCards[indexPath.row]
        
        if selectedCards.contains(card) {
            for (index, dashboardCard) in selectedCards.enumerated() {
                // Double check to avoid index out of bounds
                if dashboardCard.id == card.id && 0 <= index && selectedCards.count > index {
                    selectedCards.remove(at: index)
                }
            }
            delegate?.dashboardSelectionViewController(dashboardSelectionViewController: self, didRemoveCard: card)
        } else {
            if 0 <= indexPath.row && indexPath.row < Constants.dashboardCards.count {
                selectedCards.append(card)
                delegate?.dashboardSelectionViewController(dashboardSelectionViewController: self, didAddCard: card)
            }
        }
        
        tableView.reloadData()
    }
}
