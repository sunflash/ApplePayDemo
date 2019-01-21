//
//  PaymentViewController.swift
//  ApplePayDemo
//
//  Created by Min Wu on 07/09/2018.
//  Copyright © 2018 Min Wu. All rights reserved.
//

import Foundation
import PassKit

class PaymentViewController: UIViewController {

    let paymentHandler = PaymentHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {

        let result = PaymentHandler.applePayStatus()
        var button: PKPaymentButton?

        if result.canMakePayments {
            button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(payPressed(sender:)), for: .touchUpInside)
        } else if result.canSetupCards {
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(setupPressed(sender:)), for: .touchUpInside)
        }

        if let paymentButton = button {
            paymentButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(paymentButton)
            paymentButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            paymentButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
            paymentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            paymentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
    
    @objc func payPressed(sender: AnyObject) {

        let fare = PKPaymentSummaryItem(label: "Fare", amount: NSDecimalNumber(string: "99.99"), type: .final)
        let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "20.00"), type: .final)
        let total = PKPaymentSummaryItem(label: "PaymentDemo", amount: NSDecimalNumber(string: "119.99"), type: .final)

        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = Configuration.Merchant.identififer
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        paymentRequest.requiredBillingContactFields = [.name, .postalAddress]
        paymentRequest.paymentSummaryItems = [fare, tax, total]

        paymentHandler.startPayment(paymentRequest) { [weak self] result in
            switch result {
            case.success(let payment):
                self?.performSegue(withIdentifier: "Confirmation", sender: payment)
            case.failure(let errors):
                let messege = errors.map {$0.localizedDescription}.joined(separator: "\n")
                let alert = UIAlertController(title: "Billing Address", message: messege, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                errors.forEach {print($0.localizedDescription)}
            case .cancel:
                let alert = UIAlertController(title: nil, message: "Payment is cancel", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }

    @objc func setupPressed(sender: AnyObject) {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let confirmationVC = segue.destination as? ConfirmationViewController {
            confirmationVC.payment = sender as? PKPayment
        }
    }
}

