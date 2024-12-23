//
//  TVMCalculatorTests.swift
//  FinancialKit
//
//  Created by Behzad Dogahe on 12/22/24.
//

import Testing
@testable import FinancialKit

struct TVMCalculatorTests {
  
  @Test
  func testInterestRateForMortgage() throws {
    let interest = try FinancialKit.tvm.calculate(
      presentValue: 75000,
      futureValue: 0,
      numberOfPeriods: 360,
      payment: -425.84,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      unknownVariable: .interestRate
    )
    #expect(abs(interest - (5.50)) < 0.01)
  }
  
  @Test
  func testBeginningOfPeriodPaymentInterestRateForMortgage() throws {
    let interest = try FinancialKit.tvm.calculate(
      presentValue: 75000,
      futureValue: 0,
      numberOfPeriods: 360,
      payment: -425.84,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      isEndOfPeriodPayment: false,
      unknownVariable: .interestRate
    )
    print(interest)
    #expect(abs(interest - (5.54)) < 0.01)
  }
  
  @Test
  func testInterestRateForMortgageExample2() throws {
    let interest = try FinancialKit.tvm.calculate(
      presentValue: 649000,
      futureValue: 0,
      numberOfPeriods: 360,
      payment: -4000,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      unknownVariable: .interestRate
    )
    #expect(abs(interest - (6.259)) < 0.001)
  }
  
  @Test
  func testBeginningOfPeriodPaymentInterestRateForMortgageExample2() throws {
    let interest = try FinancialKit.tvm.calculate(
      presentValue: 649000,
      futureValue: 0,
      numberOfPeriods: 360,
      payment: -4000,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      isEndOfPeriodPayment: false,
      unknownVariable: .interestRate
    )
    #expect(abs(interest - (6.31)) < 0.001)
  }
  
  @Test
  func testPaymentForMortgage() throws {
    let payment = try FinancialKit.tvm.calculate(
      presentValue: 75000,
      futureValue: 0,
      interestRate: 5.5,
      numberOfPeriods: 360,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      unknownVariable: .payment
    )
    #expect(abs(payment - (-425.84)) < 0.01)
  }
  
  @Test
  func testQuarterlyPaymentForMortgage() throws {
    let payment = try FinancialKit.tvm.calculate(
      presentValue: 75000,
      futureValue: 0,
      interestRate: 5.5,
      numberOfPeriods: 120,
      paymentsPerYear: 4,
      compoundingPeriodsPerYear: 4,
      unknownVariable: .payment
    )
    #expect(abs(payment - (-1279.82)) < 0.01)
  }
  
  @Test
  func testFutureValueForSaving() throws {
    let future = try FinancialKit.tvm.calculate(
      presentValue: -5000,
      futureValue: 0,
      interestRate: 0.5,
      numberOfPeriods: 20,
      paymentsPerYear: 1,
      compoundingPeriodsPerYear: 1,
      unknownVariable: .futureValue
    )
    #expect(abs(future - (5524.48)) < 0.01)
  }
  
  @Test
  func testPresentValueForSaving() throws {
    let present = try FinancialKit.tvm.calculate(
      futureValue: 10000,
      interestRate: 0.5,
      numberOfPeriods: 20,
      paymentsPerYear: 1,
      compoundingPeriodsPerYear: 1,
      unknownVariable: .presentValue
    )
    #expect(abs(present - (-9050.63)) < 0.01)
  }
  
  @Test
  func testEndOfPeriodPaymentForMortgage() throws {
    let payment = try FinancialKit.tvm.calculate(
      presentValue: 649000,
      futureValue: 0,
      interestRate: 6.375,
      numberOfPeriods: 360,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      unknownVariable: .payment
    )
    #expect(abs(payment - (-4048.92)) < 0.01)
  }
  
  @Test
  func testBeginningOfPeriodPaymentForMortgage() throws {
    let payment = try FinancialKit.tvm.calculate(
      presentValue: 649000,
      futureValue: 0,
      interestRate: 6.375,
      numberOfPeriods: 360,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      isEndOfPeriodPayment: false,
      unknownVariable: .payment
    )
    #expect(abs(payment - (-4027.52)) < 0.01)
  }
  
  @Test
  func testPresentValueForAnnuities() throws {
    let present = try FinancialKit.tvm.calculate(
      futureValue: 0,
      interestRate: 10,
      numberOfPeriods: 10,
      payment: -20000,
      paymentsPerYear: 1,
      compoundingPeriodsPerYear: 1,
      unknownVariable: .presentValue
    )
    #expect(abs(present - (122891.34)) < 0.01)
  }
  
  @Test
  func testBeginningOfPeriodPaymentPresentValueForAnnuities() throws {
    let present = try FinancialKit.tvm.calculate(
      futureValue: 0,
      interestRate: 10,
      numberOfPeriods: 10,
      payment: -20000,
      paymentsPerYear: 1,
      compoundingPeriodsPerYear: 1,
      isEndOfPeriodPayment: false,
      unknownVariable: .presentValue
    )
    #expect(abs(present - (135180.48)) < 0.01)
  }
  
  @Test
  func testNumberOfPaymentsForMortgage() throws {
    let numberOfPayments = try FinancialKit.tvm.calculate(
      presentValue: 75000,
      futureValue: 0,
      interestRate: 5.5,
      payment: -500,
      paymentsPerYear: 12,
      compoundingPeriodsPerYear: 12,
      unknownVariable: .numberOfPeriods
    )
    print(numberOfPayments)
    #expect(abs(numberOfPayments - (254.36)) < 0.01)
  }
}
