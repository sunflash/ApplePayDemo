//
//  ConfirmationViewController
//  ApplePayDemo
//
//  Created by Min Wu on 08/09/2018.
//  Copyright © 2018 Min Wu. All rights reserved.
//

import Foundation
import PassKit

class ConfirmationViewController: UIViewController {

    @IBOutlet private weak var contentTextView: UITextView!

    var token: PKPaymentToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        displayToken()
    }

    private func displayToken() {
        self.title = token?.paymentMethod.displayName
        guard let paymentData = token?.paymentData else {return}
        let tokenString = String(data: paymentData, encoding: .utf8)
        contentTextView.text = tokenString
    }
}
