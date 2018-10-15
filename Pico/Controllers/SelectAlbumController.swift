//
//  SelectAlbumController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/7/11.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

protocol AlbumSelectDelegator {
    func onAlbumSelected(album: Album)
}

class SelectAlbumController: UITableViewController {
    
    var albums: [Album] = [Album]()
    var selectDelegator: AlbumSelectDelegator?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath) as! AlbumCell
        
        let album = albums[indexPath.item]
        
        cell.title.text = album.collection.localizedTitle
        cell.count.text = String(album.items.count)
        
        if let image = album.items.first {
            let imageSize = CGSize(width: 25*UIScreen.main.scale, height: 25*UIScreen.main.scale)
            
            let options = PHImageRequestOptions()
            options.resizeMode = .exact
            PHImageManager.default().requestImage(for: image.asset, targetSize: imageSize, contentMode: .aspectFill,  options: options) { [weak self] (image, _) in
                cell.thumbernail.image = image
            }            
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return albums.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = albums[indexPath.item]
        selectDelegator?.onAlbumSelected(album: album)
    }
}
