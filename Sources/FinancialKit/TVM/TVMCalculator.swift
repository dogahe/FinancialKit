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

  
  public struct AmortizationSchedule {
    let principalPayments: [Double]
    let interestPayments: [Double]
    let balances: [Double]
    
    public init(principalPayments: [Double], interestPayments: [Double], balances: [Double]) {
      self.principalPayments = principalPayments
      self.interestPayments = interestPayments
      self.balances = balances
    }
  }
  
  // MARK: - Calculation Functions
  
  public static func calculate(
    presentValue: Double = 0,
    futureValue: Double = 0,
    interestRate: Double = 0,
    numberOfPeriods: Double = 0,
    payment: Double = 0,
    paymentsPerYear: Int = 1,
    compoundingPeriodsPerYear: Int = 1,
    isEndOfPeriodPayment: Bool = true,
    p1: Int = 1,
    p2: Int = 1,
    unknownVariable: TVMVariable
  ) throws -> (result: Double, balance: Double, principal: Double, interest: Double, amortizationSchedule: AmortizationSchedule) {
    
    try validateInputs(presentValue: presentValue,
                       futureValue: futureValue,
                       interestRate: interestRate,
                       numberOfPeriods: numberOfPeriods,
                       payment: payment,
                       paymentsPerYear: paymentsPerYear,
                       compoundingPeriodsPerYear: compoundingPeriodsPerYear,
                       unknownVariable: unknownVariable)
    
    var amortizationSchedule: AmortizationSchedule
    var balance: Double = 0
    var principal: Double = 0
    var interest: Double = 0
    var result: Double = 0.0
    
    var myPresentValue = presentValue
    var myInterestRate = interestRate
    var myNumberOfPeriods = numberOfPeriods
    var myPayment = payment
    
    
    switch unknownVariable {
    case .presentValue:
      result = try calculatePresentValue(futureValue: futureValue, interestRate: interestRate, numberOfPeriods: numberOfPeriods, payment: payment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      myPresentValue = result
    case .futureValue:
      result = try calculateFutureValue(presentValue: presentValue, interestRate: interestRate, numberOfPeriods: numberOfPeriods, payment: payment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    case .interestRate:
      result = try calculateInterestRate(presentValue: presentValue, futureValue: futureValue, numberOfPeriods: numberOfPeriods, payment: payment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      myInterestRate = result
    case .numberOfPeriods:
      result = try calculateNumberOfPeriods(presentValue: presentValue, futureValue: futureValue, interestRate: interestRate, payment: payment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      myNumberOfPeriods = result
    case .payment:
      result = try calculatePayment(presentValue: presentValue, futureValue: futureValue, interestRate: interestRate, numberOfPeriods: numberOfPeriods, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
      myPayment = result
    }
    
    amortizationSchedule = calculateAmortizationSchedule(presentValue: myPresentValue, interestRate: myInterestRate, numberOfPeriods: myNumberOfPeriods, payment: myPayment, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    
    (balance, principal, interest) = calculateAmortization(presentValue: myPresentValue, interestRate: myInterestRate, numberOfPeriods: myNumberOfPeriods, payment: myPayment, p1: p1, p2: p2, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear, isEndOfPeriodPayment: isEndOfPeriodPayment)
    return (result, balance, principal, interest, amortizationSchedule)
  }
  
  // MARK: - Private Calculation Helper Functions
  
  private static func round(_ value: Double, withNDecimals decimals: Int) -> Double {
    let multiplier = pow(10, Double(decimals))
    return (value * multiplier).rounded() / multiplier
  }
  
  public static func calculateAmortizationSchedule(
    presentValue: Double,
    interestRate: Double,
    numberOfPeriods: Double,
    payment: Double,
    paymentsPerYear: Int,
    compoundingPeriodsPerYear: Int,
    isEndOfPeriodPayment: Bool
  ) -> AmortizationSchedule {
    let decimalPoints = 2
    var myBalance = round(presentValue, withNDecimals: decimalPoints)
    let initialPrincipal = myBalance
    var myInterest: Double
    let myPayment: Double = round(payment, withNDecimals: decimalPoints)
    
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    
    var balances: [Double] = []
    var principalPayments: [Double] = []
    var principalCumulativePayments: [Double] = []
    var interestPayments: [Double] = []
    
    var m = 1
    var lastPrincipalCumulative: Double = 0
    while m <= Int(numberOfPeriods) {
      myInterest = -rate * myBalance
      myInterest = round(myInterest, withNDecimals: 12)
      myInterest = round(myInterest, withNDecimals: decimalPoints)
      myBalance = myBalance - myInterest + myPayment
      m += 1
      balances.append(myBalance)
      let cumulativePrincipal = myBalance - initialPrincipal
      principalCumulativePayments.append(cumulativePrincipal)
      let principal = cumulativePrincipal - lastPrincipalCumulative
      principalPayments.append(principal)
      let interest = myPayment - principal
      interestPayments.append(interest)
      lastPrincipalCumulative = cumulativePrincipal
    }
    let amortizationSchedule = AmortizationSchedule(principalPayments: principalPayments, interestPayments: interestPayments, balances: balances)
    return amortizationSchedule
  }
  
  private static func calculateAmortization(presentValue: Double,
                                            interestRate: Double,
                                            numberOfPeriods: Double,
                                            payment: Double,
                                            p1: Int,
                                            p2: Int,
                                            paymentsPerYear: Int,
                                            compoundingPeriodsPerYear: Int,
                                            isEndOfPeriodPayment: Bool) -> (Double, Double, Double) {
    let decimalPoints = 2
    var myBalance = round(presentValue, withNDecimals: decimalPoints)
    var principal = myBalance
    var myInterest: Double
    let myPayment: Double = round(payment, withNDecimals: decimalPoints)
    
    let rate = iTVM(interestRate: interestRate, paymentsPerYear: paymentsPerYear, compoundingPeriodsPerYear: compoundingPeriodsPerYear)
    
    var m = 1
    while m <= p2 {
      myInterest = -rate * myBalance
      myInterest = round(myInterest, withNDecimals: 12)
      myInterest = round(myInterest, withNDecimals: decimalPoints)
      myBalance = myBalance - myInterest + myPayment
      if p1 != 1 {
        if m + 1 == p1 {
          principal = myBalance
        }
      }
      m += 1
    }
    let balance = myBalance
    principal = myBalance - principal
    let interest = Double(p2 - p1 + 1) * myPayment - principal
    
    return (balance, principal, interest)
  }
  
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
