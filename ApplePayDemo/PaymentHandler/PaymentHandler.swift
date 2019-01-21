//
//  PaymentHandler.swift
//  ApplePayDemo
//
//  Created by Min Wu on 07/09/2018.
//  Copyright © 2018 Min Wu. All rights reserved.
//

import UIKit
import PassKit

enum PaymentResult {

    case success(PKPayment)

    case failure([Error])

    case cancel
}

typealias PaymentCompletionHandler = (PaymentResult) -> Void

class PaymentHandler: NSObject {

    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]

    // Payment request
    private var paymentSummaryItems: [PKPaymentSummaryItem] = []
    private var requiredBillingContactFields: Set<PKContactField> = []
    private var requiredShippingContactFields: Set<PKContactField> = []
    private var completionHandler: PaymentCompletionHandler?

    // Private payment state
    private var paymentController: PKPaymentAuthorizationController?
    private var paymentAuthorizationResult: PKPaymentAuthorizationResult = PKPaymentAuthorizationResult(status: .failure, errors: nil)
    private var payment: PKPayment?
    private var didAuthorizePayment = false

    static func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (PKPaymentAuthorizationController.canMakePayments(),
                PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }

    func startPayment(_ paymentRequest: PKPaymentRequest, completion: @escaping PaymentCompletionHandler) {

        paymentSummaryItems = paymentRequest.paymentSummaryItems
        requiredBillingContactFields = paymentRequest.requiredBillingContactFields
        requiredShippingContactFields = paymentRequest.requiredShippingContactFields
        completionHandler = completion

        paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
        paymentRequest.merchantCapabilities = .capability3DS

        // Display our payment request
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present { presented in
            if presented {
                // Presented payment controller
            } else {
                let error = NSError(domain: PKPaymentErrorDomain,
                                    code: PKPaymentError.unknownError.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: "!! Failed to present payment controller"])
                self.completionHandler?(PaymentResult.failure([error]))
            }
        }
    }

    private func resetPaymentState() {
        paymentSummaryItems = []
        requiredBillingContactFields = []
        requiredShippingContactFields = []
        completionHandler = nil
        paymentAuthorizationResult = PKPaymentAuthorizationResult(status: .failure, errors: nil)
        payment = nil
        didAuthorizePayment = false
    }
}

// PKPaymentAuthorizationControllerDelegate conformance (iOS 11+).
extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        self.payment = payment
        didAuthorizePayment = true

        let billingValidationResult = PaymentContactValidation.performContactValidation(payment: payment,
                                                                                        type: .billing,
                                                                                        requiredContactFields: requiredBillingContactFields)

        let shippingValidationResult = PaymentContactValidation.performContactValidation(payment: payment,
                                                                                         type: .shipping,
                                                                                         requiredContactFields: requiredShippingContactFields)

        let tokenUnavailableDescription = NSLocalizedString("TokenUnavailableDescription", comment: "PaymentError")
        let tokenUnavailableError = NSError(domain: PKPaymentErrorDomain,
                                            code: PKPaymentError.unknownError.rawValue,
                                            userInfo: [NSLocalizedDescriptionKey: tokenUnavailableDescription])

        let tokenString = String(data: payment.token.paymentData, encoding: .utf8)
        let tokenValidationStatus: PKPaymentAuthorizationStatus = (tokenString?.isEmpty == true) ? .failure : .success
        let tokenError = (tokenValidationStatus == .failure) ? [tokenUnavailableError] : nil
        let tokenValidationResult = PKPaymentAuthorizationResult(status: tokenValidationStatus, errors: tokenError)

        let validationResults = [billingValidationResult, shippingValidationResult, tokenValidationResult]

        if (validationResults.contains {$0.status == .failure}) {
            let allValidationErrors = validationResults.compactMap {$0.errors}.flatMap {$0}
            let combineFaiureResult = PKPaymentAuthorizationResult(status: .failure, errors: allValidationErrors)
            paymentAuthorizationResult = combineFaiureResult
        } else {
            let successResult = PKPaymentAuthorizationResult(status: .success, errors: nil)
            paymentAuthorizationResult = successResult
        }
        completion(paymentAuthorizationResult)
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        DispatchQueue.main.async { [weak self] in
            if self?.didAuthorizePayment == false {
                self?.completionHandler?(PaymentResult.cancel)
            } else if self?.paymentAuthorizationResult.status == .success, let payment = self?.payment {
                self?.completionHandler?(PaymentResult.success(payment))
            } else {
                let errors = self?.paymentAuthorizationResult.errors ?? [Error]()
                self?.completionHandler?(PaymentResult.failure(errors))
            }
            self?.resetPaymentState()
            controller.dismiss {}
        }
    }
}


