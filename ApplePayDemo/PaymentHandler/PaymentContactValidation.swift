//
//  PaymentContactValidation.swift
//  ApplePayDemo
//
//  Created by Min Wu on 07/09/2018.
//  Copyright © 2018 Min Wu. All rights reserved.
//

import Foundation
import PassKit

struct PaymentContactValidation {

    enum ContactType: String {
        case billing
        case shipping
    }

    private static func validateContactName(_ name: PersonNameComponents?) -> Error? {

        let invalidNameDescription = NSLocalizedString("InvalidNameDescription", comment: "PaymentContactError")

        guard let nameComponents = name,
            nameComponents.givenName?.isEmpty == false,
            nameComponents.familyName?.isEmpty == false else {
                let contactNameError = PKPaymentRequest.paymentContactInvalidError(withContactField: .name, localizedDescription: invalidNameDescription)
                return contactNameError
        }
        return nil
    }

    private static func validateContactEmail(_ email: String?) -> Error? {

        let invalidEmailDescription = NSLocalizedString("InvalidEmailDescription", comment: "PaymentContactError")

        guard let emailString = email, emailString.isValidEmail == false else {
            let contactEmailError = PKPaymentRequest.paymentContactInvalidError(withContactField: .emailAddress, localizedDescription: invalidEmailDescription)
            return contactEmailError
        }
        return nil
    }

    private static func validatePhoneNumber(_ phoneNumber: CNPhoneNumber?) -> Error? {

        let invalidPhoneNumberDescription = NSLocalizedString("InvalidPhoneNumberDescription", comment: "PaymentContactError")

        guard let number = phoneNumber, number.stringValue.isEmpty == false else {
            let phoneNumberError = PKPaymentRequest.paymentContactInvalidError(withContactField: .phoneNumber, localizedDescription: invalidPhoneNumberDescription)
            return phoneNumberError
        }
        return nil
    }

    private static func addressErrorByType(_ type: ContactType,
                                    input: String,
                                    errors: inout [Error],
                                    billingError: Error,
                                    shippingError: Error) {

        guard input.isEmpty == true else {return}

        switch type {
        case .billing:
            errors.append(billingError)
        case .shipping:
            errors.append(shippingError)
        }
    }

    private static func validateAddress(_ postalAddress: CNPostalAddress?, type: ContactType) -> [Error] {

        guard let address = postalAddress else {
            let missingAddressDescription = NSLocalizedString("MissingAddressDescription", comment: "PaymentContactError")
            let missingAddressError = PKPaymentRequest.paymentContactInvalidError(withContactField: .postalAddress, localizedDescription: missingAddressDescription)
            return [missingAddressError]
        }

        var errors = [Error]()

        let missingStreetDescription = NSLocalizedString("MissingStreetDescription", comment: "PaymentContactError")
        let billingStreetError = PKPaymentRequest.paymentBillingAddressInvalidError(withKey: CNPostalAddressStreetKey, localizedDescription: missingStreetDescription)
        let shippingStreetError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressStreetKey, localizedDescription: missingStreetDescription)
        addressErrorByType(type, input: address.street, errors: &errors, billingError: billingStreetError, shippingError: shippingStreetError)

        let missingCityDescription = NSLocalizedString("MissingCityDescription", comment: "PaymentContactError")
        let billingCityError = PKPaymentRequest.paymentBillingAddressInvalidError(withKey: CNPostalAddressCityKey, localizedDescription: missingCityDescription)
        let shippingCityError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressCityKey, localizedDescription: missingCityDescription)
        addressErrorByType(type, input: address.city, errors: &errors, billingError: billingCityError, shippingError: shippingCityError)

        let missingPostalcodeDescription = NSLocalizedString("MissingPostalcodeDescription", comment: "PaymentContactError")
        let billingPostalcodeError = PKPaymentRequest.paymentBillingAddressInvalidError(withKey: CNPostalAddressPostalCodeKey, localizedDescription: missingPostalcodeDescription)
        let shippingPostalcodeError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressPostalCodeKey, localizedDescription: missingPostalcodeDescription)
        addressErrorByType(type, input: address.postalCode, errors: &errors, billingError: billingPostalcodeError, shippingError: shippingPostalcodeError)

        let missingCountryDescriptioin = NSLocalizedString("MissingCountryDescription", comment: "PaymentContactError")
        let billingCountryError = PKPaymentRequest.paymentBillingAddressInvalidError(withKey: CNPostalAddressCountryKey, localizedDescription: missingCountryDescriptioin)
        let shippingCountryError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressCountryKey, localizedDescription: missingCountryDescriptioin)
        addressErrorByType(type, input: address.country, errors: &errors, billingError: billingCountryError, shippingError: shippingCountryError)

        return errors
    }

    static func performContactValidation(payment: PKPayment,
                                         type: ContactType,
                                         requiredContactFields: Set<PKContactField>) -> PKPaymentAuthorizationResult {

        let contact = (type == .billing) ? payment.billingContact : payment.shippingContact
        var errors = [Error]()
        
        if requiredContactFields.contains(.name), let contactNameError = validateContactName(contact?.name) {
            errors.append(contactNameError)
        }

        if requiredContactFields.contains(.emailAddress), let contactEmailError = validateContactEmail(contact?.emailAddress) {
            errors.append(contactEmailError)
        }

        if requiredContactFields.contains(.phoneNumber), let contactNumberError = validatePhoneNumber(contact?.phoneNumber) {
            errors.append(contactNumberError)
        }

        if requiredContactFields.contains(.postalAddress) {
            errors += validateAddress(contact?.postalAddress, type: type)
        }

        if errors.isEmpty {
            return PKPaymentAuthorizationResult(status: .success, errors: nil)
        } else {
            return PKPaymentAuthorizationResult(status: .failure, errors: errors)
        }
    }
}

extension String {
    var isValidEmail: Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}
