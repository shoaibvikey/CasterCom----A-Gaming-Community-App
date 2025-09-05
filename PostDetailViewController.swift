//
//  PostDetailViewController.swift
//  BGClan
//
//  Created by Divyanshu rai on 12/06/24.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
class PostDetailViewController: UIViewController ,UITableViewDataSource,UITableViewDelegate{

    var postsOnHome: [PostModel] = []
    var username: String?
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        tableView.dataSource=self
        tableView.delegate=self
        tableView.register(UINib(nibName: "PostLayoutTilesCell", bundle: nil), forCellReuseIdentifier: "postcell")
        if let username = username {
                  print("Username: \(username)")
                fetchPosts(for: username)
                
              }
        
                
    }
    
    func fetchPosts(for username: String) {
        let db = Firestore.firestore()
        db.collection("posts").whereField("username", isEqualTo: username).order(by: "timestamp", descending: true).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
            } else {
                guard let documents = snapshot?.documents else { return }
                let group = DispatchGroup()
                self.postsOnHome = []
                
                for document in documents {
                    let data = document.data()
                    guard let username = data["username"] as? String,
                          let caption = data["caption"] as? String,
                          let imageUrl = data["imageUrl"] as? String else {
                        continue
                    }
                    
                    let postingTime = data["postingTime"] as? String
                    let likesCount = data["likesCount"] as? Int
                    let commentsCount = data["commentsCount"] as? Int
                    
                    group.enter()
                    self.fetchProfileImageUrl(for: username) { profileImageUrl in
                        let post = PostModel(
                            caption: caption,
                            contentPath: imageUrl,
                            postingTime: postingTime ?? "",
                            likesCount: likesCount ?? 0,
                            commentsCount: commentsCount ?? 0,
                            username: username,
                            profileImageUrl: profileImageUrl
                        )
                        self.postsOnHome.append(post)
                        print("Success")
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.tableView.reloadData()
                }
            }
        }
    }
//    func PostDetailTableViewController(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 600
//    }
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        600
//    }
    func fetchProfileImageUrl(for username: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                completion(nil)
            } else {
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("User document for \(username) does not exist.")
                    completion(nil)
                    return
                }
                
                let document = documents[0]
                print("Document data for \(username): \(document.data())")
                let profileImageUrl = document.data()["profilePictureURL"] as? String
                print("Fetched profileImageUrl for \(username): \(profileImageUrl ?? "nil")")
                completion(profileImageUrl)
            }
        }
    }



    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsOnHome.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postcell", for: indexPath) as! PostLayoutTilesCell

        let post = postsOnHome[indexPath.row]
        cell.PostCaptionOutlet?.text = post.caption
        // cell.PostTimeOutlet?.text = post.postingTime
        cell.UsernameOutlet?.text = post.username
        cell.PostLikesCountOutlet?.text = "\(post.likesCount)"

        // Download post image from Firebase Storage
        let postImageRef = Storage.storage().reference(forURL: post.contentPath)
        postImageRef.getData(maxSize: 100 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading post image: \(error.localizedDescription)")
            } else {
                cell.PostImageOutlet?.image = UIImage(data: data!)
            }
        }

        // Download profile image from Firebase Storage if available
        if let profileImageUrl = post.profilePicture {
            let profileImageRef = Storage.storage().reference(forURL: profileImageUrl)
            profileImageRef.getData(maxSize: 100 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading profile image: \(error.localizedDescription)")
                } else {
                    cell.ProfilePhotoOutlet?.image = UIImage(data: data!)
                }
            }
        }

        return cell
    }

   
    

 

}
