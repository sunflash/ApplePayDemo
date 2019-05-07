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

    var payment: PKPayment?

    override func viewDidLoad() {
        super.viewDidLoad()
        displayToken()
    }

    private func displayToken() {
        self.title = payment?.token.paymentMethod.displayName
        guard let paymentData = payment?.token.paymentData else {return}
        let tokenString = String(data: paymentData, encoding: .utf8)
        contentTextView.text = tokenString

        print("BillingContact")
        print(payment?.billingContact?.postalAddress ?? "")
        print("ShippingContact")
        print(payment?.shippingContact?.emailAddress ?? "")
        print(payment?.shippingContact?.phoneNumber ?? "")
    }
}
