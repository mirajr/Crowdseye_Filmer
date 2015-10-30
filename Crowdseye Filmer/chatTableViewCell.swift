//
//  chatTableViewCell.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/8/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit

class chatTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var authorText: UILabel!
    @IBOutlet weak var messageText: UILabel!

}
