//
//  feedsTableViewCell.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/9/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit

class feedsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet weak var feedTitle: UILabel!
    @IBOutlet weak var feedAuthor: UILabel!
    @IBOutlet weak var feedViews: UILabel!
    @IBOutlet weak var feedPreview: UIImageView!

}
