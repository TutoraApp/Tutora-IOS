//
//  ChatViewController.swift
//  tutorapp
//
//  Created by Sahas D on 6/11/16.
//  Copyright © 2016 sahasd. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import JSQMessagesViewController
import Alamofire

public protocol Unwrappable {
    func unwrap() -> Any?
}

extension Optional: Unwrappable {
    public func unwrap() -> Any? {
        switch self {
        case .None:
            return nil
        case .Some(let unwrappable as Unwrappable):
            return unwrappable.unwrap()
        case .Some (let some):
            return some
        }
    }
}

public extension String {
    init(stringInterpolationSegment expr: Unwrappable) {
        self = String(expr.unwrap() ?? "")
    }
}

class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var messages = [JSQMessage]()
    
    let ref = Firebase(url:"https://project-6564761374345501298.firebaseio.com/messages")
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chatting"
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        setupBubbles()
        
        self.senderId = "Sahas"
        self.senderDisplayName = "Sahas"
        
        
        ref.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            print(snapshot.value)
            let id = snapshot.value["senderId"] as! String
            if let text = snapshot.value["text"] as? String{
                self.addMessage(id, text: text)
            }
            if let myImage = snapshot.value["picture"] as? String{
                if (myImage != ""){
                    let actualImage =  UIImage(data: NSData(contentsOfURL: NSURL(string:myImage)!)!)
                    self.addMediaImage(id, text: "", image: actualImage!)
                }
            }
            self.finishReceivingMessage()

        }
        
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //observeMessages()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func addMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message)
    }
    
    func addMediaImage (id: String, text: String, image: UIImage) {
        let media = JSQPhotoMediaItem(image: image)
        let message = JSQMessage(senderId: id, displayName: text, media: media)
        messages.append(message)
    }
    

    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.whiteColor()
        } else {
            cell.textView?.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,senderDisplayName: String!, date: NSDate!) {
        
        let messageItem = [ // 2
            "text": text,
            "senderId": senderId,
            "picture" : ""
        ]
        let itemRef = ref.childByAutoId()
        itemRef.setValue(messageItem) // 3
        
        // 4
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        // 5
        finishSendingMessage()
    }
    
    /*private func observeMessages() {
        //let messagesQuery = ref.queryLimitedToLast(25)
        ref.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            print(snapshot.value)
            let id = snapshot.value["senderId"] as! String
            let text = snapshot.value["text"] as! String
            self.addMessage(id, text: text)
            self.finishReceivingMessage()
        }
    }*/
    
    override func didPressAccessoryButton(sender: UIButton!) {
        print("pressed button");
        self.inputToolbar.contentView.textView.resignFirstResponder()
        selectPicture()

    }
    
    func selectPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var newImage: UIImage
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
        } else {
            return
        }
        
        // do something interesting here!
        sendImage(newImage)

        
        
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sendImage(image: UIImage)  {
        var returnURL : String?
        print("at Send Image")
        let imageData:NSData = UIImagePNGRepresentation(image)!
        let strBase64:String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        let params : [String: String] = [
            "data" : strBase64
        ]
        print(strBase64)
        Alamofire.request(.POST, "http://tutorbot-superdev.rhcloud.com/addme", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value {
                    returnURL = String("\(JSON.url!)")
                    print (returnURL)
                }
                
                let messageItem = [ // 2
                    "text": "",
                    "senderId": self.senderId,
                    "picture" : returnURL
                ]
                let itemRef = self.ref.childByAutoId()
                itemRef.setValue(messageItem)
                self.finishSendingMessage()
        
        }
        
    }
}



