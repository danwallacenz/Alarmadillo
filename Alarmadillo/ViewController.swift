//
//  ViewController.swift
//  Alarmadillo
//
//  Created by Daniel Wallace on 12/02/17.
//  Copyright © 2017 Daniel Wallace. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UITableViewController {

    var groups = [Group]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleAttributes = [NSFontAttributeName: UIFont(name: "Arial Rounded MT Bold", size: 20)!]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        title = "Alarmadillo"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Groups", style: .plain, target: nil, action: nil)
        
        // dummy data
//        groups.append(Group(name: "Enabled group", playSound: true, enabled: true, alarms: []))
//        groups.append(Group(name: "Disabled group", playSound: true, enabled: false, alarms: []))
        
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: Notification.Name("save"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        groups.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        save()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Group", for: indexPath)
        
        let group = groups[indexPath.row]
        cell.textLabel?.text = group.name
        
        if group.enabled {
            cell.textLabel?.textColor = UIColor.black
        } else {
            cell.textLabel?.textColor = UIColor.red
        }
        
        if group.alarms.count == 1 {
            cell.detailTextLabel?.text = "1 alarm"
        } else {
            cell.detailTextLabel?.text = "\(group.alarms.count) alarms"
        }
        
        return cell
    }
    
    func addGroup() {
        
        let newGroup = Group(name: "Name this group", playSound: true, enabled: false, alarms: [])
        groups.append(newGroup)
        
        performSegue(withIdentifier: "EditGroup", sender: newGroup)
        
        save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let groupToEdit: Group
        
        if sender is Group {
            // we were called from addGroup(); use what it sent us
            groupToEdit = sender as! Group
        } else {
            // we were called by a table view cell; figure out which group we're attached to send send that
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
            groupToEdit = groups[selectedIndexPath.row]
        }
        
        // unwrap our destination from the segue
        if let groupViewController = segue.destination as? GroupViewController {
            // give it whatever group we decided above
            groupViewController.group = groupToEdit
        }
    }
    
    func save() {
        do {
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = NSKeyedArchiver.archivedData(withRootObject: groups)
            try data.write(to: path)
            
            updateNotifications()
            
        } catch {
            print("Failed to save")
        }
    }
    
    func load() {
        do {
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = try Data(contentsOf: path)
            groups = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Group] ?? [Group]()
        } catch {
            print("Failed to load")
        }
        
        tableView.reloadData()
    }
    
    func updateNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { [unowned self] (granted, error) in
            if granted {
                self.createNotifications()
            }
        }
    }
    
    func createNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // 1: remove any pending notifications
        center.removeAllPendingNotificationRequests()
        
        for group in groups {
            // 2: ignore disabled groups
            guard group.enabled == true else { continue }
            
            for alarm in group.alarms {
                // 3: create a notification request from each alarm
                let notification = createNotificationRequest(group: group, alarm: alarm)
                
                // 4: schedule that notification for delivery
                center.add(notification) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }
    
    func createNotificationRequest(group: Group, alarm: Alarm) -> UNNotificationRequest {
        // start by creating the content for the notification
        let content = UNMutableNotificationContent()
        
        // assign the alarms's name and caption
        content.title = alarm.name
        content.body = alarm.caption
        
        // give it an identifier we can attach to custom buttons later on
        content.categoryIdentifier = "alarm"
        
        // attach the group ID and alarm ID for this alarm
        content.userInfo = ["group": group.id, "alarm": alarm.id]
        
        // if the user requested a sound for this group, attach their default alert sound
        if group.playSound {
            content.sound = UNNotificationSound.default()
        }
        
        // use createNotificationAttachments to attach a picture for this alert if there is one
        content.attachments = createNotificationAttachments(alarm: alarm)
        
        // get a calendar ready to pull out date components
        let cal = Calendar.current
        
        // pull out the hour and minute components from this alarm's date
        var dateComponents = DateComponents()
        dateComponents.hour = cal.component(.hour, from: alarm.time)
        dateComponents.minute = cal.component(.minute, from: alarm.time)
        
        // create a trigger matching those date components, set to repeat
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        // for testing
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        
        // combine the content and the trigger to create a notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // pass that object back to createNotifications() for scheduling
        return request
    }
    
    func createNotificationAttachments(alarm: Alarm) -> [UNNotificationAttachment] {
        
        // 1: return if there is no image to attach
        guard alarm.image.characters.count > 0 else { return [] }
        
        let fm = FileManager.default
        
        do {
            /* When you attach an image to a notification, it gets moved into a separate location so that it can be guaranteed to exist when shown. That means you cannot just use the same file we placed into the documents directory, because it will get moved away – and thus lost. */
            
            // 2: get the full path to the alarm image
            let imageURL = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            
            // 3: create a temporary filename
            let copyURL = Helper.getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).jpg")
            
            // 4: copy the alarm image to the temporary filename
            try fm.copyItem(at: imageURL, to: copyURL)
            
            // 5: create an attachment from the temporary filename, giving it a random identifier
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: copyURL)
            
            // 6: return the attachment back to createNotificationRequest()
            return [attachment]
        
        } catch {
            print("Failed to attach alarm image: \(error)")
            return []
        }
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    /// when app is running
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
            completionHandler([.alert])
    }
    
    /// app in background or on lock screen
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // pull out the buried userInfo dictionary
        let userInfo = response.notification.request.content.userInfo
        
        if let groupID = userInfo["group"] as? String {
            // if we got a group ID, we're good to go!
            switch response.actionIdentifier {
            
            // the user swiped to unlock; do nothing
            case UNNotificationDefaultActionIdentifier:
                print("Default identifier - swiped to unlock or dimiss")
                
            // the user dismissed the alert; do nothing
            case UNNotificationDismissActionIdentifier:
                print("Dismiss identifier")
                
            // the user asked to see the group, so call display()
            case "show":
                display(group: groupID)
                break
                
            // the user asked to destroy the group, so call destroy()
            case "destroy":
                destroy(group: groupID)
                break
                
            // the user asked to rename the group, so safely unwrap their text response and call rename()
            case "rename":
                if let textResponse = response as? UNTextInputNotificationResponse {
                    rename(group: groupID, newName: textResponse.userText)
                }
                break
                
            default:
                break
            }
        }
        
        // you need to call the completion handler when you're done
        completionHandler()
    }
    
    func display(group groupID: String) {
        
        _ = navigationController?.popToRootViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                performSegue(withIdentifier: "EditGroup", sender: group)
                return
            }
        }
    }
    
    func destroy(group groupID: String) {
        _ = navigationController?.popToRootViewController(animated: false)
        
        for (index, group) in groups.enumerated() {
            if group.id == groupID {
                groups.remove(at: index)
                break
            }
        }
        save()
        load()
    }
    
    func rename(group groupID: String, newName: String) {
        _ = navigationController?.popToRootViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                group.name = newName
                break
            }
        }
        save()
        load()
    }
}
