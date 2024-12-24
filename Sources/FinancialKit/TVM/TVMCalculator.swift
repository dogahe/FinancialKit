//
//  TVMCalculator.swift
//  FinancialKit
//
//  Created by Behzad Dogahe on 12/22/24.
//

import Foundation

@objc(TVMVariable)
public enum TVMVariable: Int {
  case presentValue = 0
  case futureValue = 1
  case interestRate = 2
  case numberOfPeriods = 3
  case payment = 4
}

enum TVMError: Error {
  case invalidInput
  case unknownVariable
}


public struct TVMCalculator {
  // MARK: - Calculation Functions
  
  public static func calculate(
    presentValue: Double? = nil,
    futureValue: Double? = nil,
    interestRate: Double? = nil,
    numberOfPeriods: Double? = nil,
    payment: Double? = nil,
    paymentsPerYear: Int = 1,
    compoundingPeriodsPerYear: Int = 1,
    isEndOfPeriodPayment: Bool = true,
    unknownVariable: TVMVariable
  ) throws -> Double {
    
    try validateInputs(presentValue: presentValue,
                       futureValue: futureValue,
                       interestRate: interestRate,
                       numberOfPeriods: numberOfPeriods,
                       payment: payment,
                       paymentsPerYear: paymentsPerYear,
                       compoundingPeriodsPerYear: compoundingPeriodsPerYear,
                       unknownVariable: unknownVariable)
    
    switch unknownVariable {
    case .presentValue:
      return try calculatePresentValue(futureValue: futureValue!, interestRate: interestRate!, numberOfPeriods: numberOfPeriods!, payment: payment ?? 0, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    case .futureValue:
      return try calculateFutureValue(presentValue: presentValue!, interestRate: interestRate!, numberOfPeriods: numberOfPeriods!, payment: payment ?? 0, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    case .interestRate:
      return try calculateInterestRate(presentValue: presentValue!, futureValue: futureValue!, numberOfPeriods: numberOfPeriods!, payment: payment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    case .numberOfPeriods:
      return try calculateNumberOfPeriods(presentValue: presentValue!, futureValue: futureValue!, interestRate: interestRate!, payment: payment ?? 0, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    case .payment:
      return try calculatePayment(presentValue: presentValue!, futureValue: futureValue!, interestRate: interestRate!, numberOfPeriods: numberOfPeriods!, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    }
  }
  
  // MARK: - Private Calculation Helper Functions
  
  private static func iTVM(interestRate: Double,
                           paymentsPerYear: Int,
                           compoundingPeriodsPerYear: Int) -> Double {
    return exp(log(0.01 * interestRate / Double(compoundingPeriodsPerYear) + 1) * Double(compoundingPeriodsPerYear) / Double(paymentsPerYear)) - 1
  }
  
  private static func gI(interestRate: Double,
                         paymentsPerYear: Int,
                         compoundingPeriodsPerYear: Int,
                         isEndOfPeriodPayment: Bool) -> Double {
    return 1 + iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear) * (isEndOfPeriodPayment ? 0 : 1)
  }
  
  private static func calculatePresentValue(futureValue: Double, interestRate: Double, numberOfPeriods: Double, payment: Double, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, isEndOfPeriodPayment: Bool) throws -> Double {
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    var present: Double
    if rate == 0 {
      present = -(futureValue + payment * numberOfPeriods)
    } else {
      let g = gI(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      present = (payment * g / rate - futureValue) * 1 / pow(1 + rate, numberOfPeriods) - payment * g / rate
    }
    if abs(present) < 0.0000001 {
      present = 0
    }
    return present
  }
    
  private static func calculateInterestRate(presentValue: Double, futureValue: Double, numberOfPeriods: Double, payment: Double? = nil, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, isEndOfPeriodPayment: Bool, tolerance: Double = 0.00001, maxIterations: Int = 1000) throws -> Double {

      let periods = numberOfPeriods
      let paymentPerPeriod = payment

      var rateLow = 0.0
      var rateHigh = 1.0
      var rateGuess = 0.1 // Initial guess

      for _ in 0..<maxIterations {
          var fValue: Double
          var fDerivative: Double

          if let pmt = paymentPerPeriod {
              // Annuity case
              // Calculate g based on the current rate guess
              let g = gI(interestRate: rateGuess * 100 * Double(compoundingPeriodsPerYear), paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)

              // Use g in both fValue and fDerivative calculations
              fValue = presentValue * pow(1 + rateGuess, periods) + pmt * (pow(1 + rateGuess, periods) - 1) / rateGuess * g - futureValue
              fDerivative = presentValue * periods * pow(1 + rateGuess, periods - 1) + pmt * g * (periods * pow(1 + rateGuess, periods - 1) * rateGuess - (pow(1 + rateGuess, periods) - 1)) / pow(rateGuess, 2)

          } else {
              // Lump sum case
              fValue = presentValue * pow(1 + rateGuess, periods) - futureValue
              fDerivative = presentValue * periods * pow(1 + rateGuess, periods - 1)
          }

          let nextRateGuess = rateGuess - fValue / fDerivative

          if abs(nextRateGuess - rateGuess) < tolerance {
              return nextRateGuess * 100 * Double(compoundingPeriodsPerYear)
          }

          if fValue > 0 {
              rateHigh = rateGuess
          } else {
              rateLow = rateGuess
          }

          rateGuess = (rateLow + rateHigh) / 2.0
      }

      throw TVMError.invalidInput
  }
  
  private static func calculateNumberOfPeriods(presentValue: Double, futureValue: Double, interestRate: Double, payment: Double, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, isEndOfPeriodPayment: Bool) throws -> Double {
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    var numberOfPeriods: Double
    if rate == 0 {
      numberOfPeriods = -(presentValue + futureValue) / payment
    } else {
      let g = gI(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      numberOfPeriods = log((payment * g - futureValue * rate)/(payment * g + presentValue * rate))/log(1 + rate)
    }
    return numberOfPeriods
  }
  
  private static func calculatePayment(presentValue: Double, futureValue: Double, interestRate: Double, numberOfPeriods: Double, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, isEndOfPeriodPayment: Bool) throws -> Double {
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    var payment: Double
    if rate == 0 {
      payment = -(presentValue + futureValue) / numberOfPeriods
    } else {
      let g = gI(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      payment = -rate/g * (presentValue + (presentValue + futureValue)/(pow(1 + rate, numberOfPeriods) - 1))
    }
    if abs(payment) < 0.0000001 {
      payment = 0
    }
    return payment
  }
  
  private static func calculateFutureValue(presentValue: Double, interestRate: Double, numberOfPeriods: Double, payment: Double, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, isEndOfPeriodPayment: Bool) throws -> Double {
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    var future: Double
    if rate == 0 {
      future = -(presentValue + payment * numberOfPeriods)
    } else {
      let g = gI(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      future = (payment * g / rate) - pow(1 + rate, numberOfPeriods) * (presentValue + (payment * g) / rate)
    }
    if abs(future) < 0.0000001 {
      future = 0
    }
    return future
  }
  
  // MARK: - Input Validation
  
  private static func validateInputs(presentValue: Double?, futureValue: Double?, interestRate: Double?, numberOfPeriods: Double?, payment: Double?, paymentsPerYear: Int, compoundingPeriodsPerYear: Int, unknownVariable: TVMVariable) throws {
    
    // Ensure all variables except possibly payment are non-nil
    if unknownVariable != .presentValue && presentValue == nil {
      throw TVMError.invalidInput
    }
    if unknownVariable != .futureValue && futureValue == nil {
      throw TVMError.invalidInput
    }
    if unknownVariable != .interestRate && interestRate == nil {
      throw TVMError.invalidInput
    }
    if unknownVariable != .numberOfPeriods && numberOfPeriods == nil {
      throw TVMError.invalidInput
    }
    // Payment can be nil if unknownVariable is not .payment
    if unknownVariable != .payment && payment == nil {
      // This is fine, it's a lump-sum scenario
    } else if unknownVariable != .payment && payment != nil {
      // This is fine, it's an annuity scenario
    }
    
    // Validate payments and compounding periods
    guard paymentsPerYear > 0, compoundingPeriodsPerYear > 0 else {
      throw TVMError.invalidInput
    }
    
    // Further specific constraints based on the unknown variable
    switch unknownVariable {
    case .presentValue:
      if let np = numberOfPeriods, let ir = interestRate, np < 0 || ir < -100 {
        throw TVMError.invalidInput
      }
    case .futureValue:
      if let np = numberOfPeriods, let ir = interestRate, np < 0 || ir < -100 {
        throw TVMError.invalidInput
      }
    case .interestRate:
      if let np = numberOfPeriods, np <= 0 {
        throw TVMError.invalidInput
      }
    case .numberOfPeriods:
      if let ir = interestRate, ir < -100 {
        throw TVMError.invalidInput
      }
    case .payment:
      if let np = numberOfPeriods, let ir = interestRate, np < 0 || ir < -100 {
        throw TVMError.invalidInput
      }
    }
  }
}
