//
//  eventsTableViewCell.swift
//  SampleBroadcaster-Swift
//
//  Created by Patrick O'Grady on 9/9/15.
//  Copyright © 2015 videocore. All rights reserved.
//

import UIKit

class eventsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        eventTitle.sizeToFit()
        eventTitle.numberOfLines = 0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var viewsText: UILabel!
    @IBOutlet weak var distanceTitle: UILabel!

}
