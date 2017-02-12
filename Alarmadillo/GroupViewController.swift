//
//  GroupViewController.swift
//  Alarmadillo
//
//  Created by Daniel Wallace on 12/02/17.
//  Copyright © 2017 Daniel Wallace. All rights reserved.
//

import UIKit

class GroupViewController: UITableViewController, UITextFieldDelegate {

    let playSoundTag = 1001
    let enabledTag = 1002
    
    var group: Group!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAlarm))
        title = group.name
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // return nothing if we're the first section
        if section == 0 { return nil }
        
        // if we're still here, it means we're the second section – do we have at least 1 alarm?
        if group.alarms.count > 0 { return "Alarms" }
        
        // if we're still here we have 0 alarms, so return nothing
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return group.alarms.count
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        group.alarms.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .
            automatic)
        
        save()
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.tag == playSoundTag {
            group.playSound = sender.isOn
        } else {
            group.enabled = sender.isOn
        }
        save()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        group.name = textField.text!
        title = group.name
        
        save()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func addAlarm() {
        let newAlarm = Alarm(name: "Name this alarm", caption: "Add an optional description", time: Date(), image: "")
        group.alarms.append(newAlarm)
        
        performSegue(withIdentifier: "EditAlarm", sender: newAlarm)
        
        save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let alarmToEdit: Alarm
        
        if sender is Alarm {
            alarmToEdit = sender as! Alarm
        } else {
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
            alarmToEdit = group.alarms[selectedIndexPath.row]
        }
        
        if let alarmViewController = segue.destination as? AlarmViewController {
            alarmViewController.alarm = alarmToEdit
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // 1: pass the hard work onto a different method if we're in the first section
            return createGroupCell(for: indexPath, in: tableView)
        } else {
            // 2: if we're here it means we're an alarm, so pull out a RightDetail cell for display
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetail", for: indexPath)
            
            // 3: pull out the correct alarm from the alarms array
            let alarm = group.alarms[indexPath.row]
            
            // 4: use the alarm to configure the cell, drawing on DateFormatter's localized date parsing
            cell.textLabel?.text = alarm.name
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: alarm.time, dateStyle: .none, timeStyle: .short)
            
            return cell
        }
    }
    
    func createGroupCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            // this is the first cell: editing the name of the group
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditableText", for: indexPath)
            
            // look for the text field inside the cell...
            if let cellTextField = cell.viewWithTag(1) as? UITextField {
                // ...then give it the group name
                cellTextField.text = group.name
            }
            
            return cell
            
        case 1:
            // this is the "play sound" cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            
            // look for both the label and the switch
            if let cellLabel = cell.viewWithTag(1) as? UILabel, let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                // configure the cell with correct settings
                cellLabel.text = "Play Sound"
                cellSwitch.isOn = group.playSound
                
                // set the switch up with the playSoundTag tag so we know which one was changed later on
                cellSwitch.tag = playSoundTag
            }
            return cell
            
        default:
            // if we're anything else, we must be the "enabled" switch, which is basically the same as the "play sound" switch
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            
            if let cellLabel = cell.viewWithTag(1) as?UILabel, let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                // obviously it's configured a little differently below!
                cellLabel.text = "Enabled"
                cellSwitch.isOn = group.enabled
                cellSwitch.tag = enabledTag
            }
            
            return cell
        }
    }
    
    func save() {
        NotificationCenter.default.post(name: Notification.Name("save"), object: nil)
    }
    
    // fix layout alignment
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = true
        cell.contentView.preservesSuperviewLayoutMargins = true
    }
}
