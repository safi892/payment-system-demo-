Intern Assignment: Payment Gateway & Digital Wallet Integration Research + Prototype

## Objective

Research, evaluate, and implement a production-style digital wallet recharge system in a Flutter application using a Pakistani payment gateway.

The goal is to understand how businesses accept online payments, maintain wallet balances, verify transactions securely, and manage digital wallets.

---

# Phase 1 – Research

Research the following payment gateways:

* PayFast Pakistan
* JazzCash Merchant API
* Easypaisa Business API
* Safepay Pakistan

Prepare a comparison including:

* Company overview
* Supported payment methods
* Flutter compatibility
* API documentation quality
* Sandbox availability
* Merchant onboarding process
* Business registration requirements
* Settlement process
* Transaction verification
* Security
* Pricing/Transaction fees
* Advantages
* Disadvantages
* Best use cases

---

# Phase 2 – Choose the Best Solution

After research,

Recommend ONE gateway.

Explain:

* Why it is the best option.
* Why the remaining gateways were not selected.
* Where it is commonly used.
* Whether it is suitable for startups.
* Whether it can scale to large businesses.

---

# Phase 3 – Flutter Prototype

Develop a Flutter application.

## Authentication

* Login
* Registration
* Firebase Authentication

---

## Wallet Screen

Display

* Current Wallet Balance
* Recharge Wallet Button
* Recent Transactions

Example

Wallet Balance

PKR 0

Recharge Wallet

Transactions

+5000 Recharge

-100 Service Charge

+3000 Recharge

---

## Recharge Flow

Allow user to

Recharge

PKR 500

PKR 1000

PKR 5000

Custom Amount

After selecting amount

Open payment flow

On successful payment

Update wallet balance

Store transaction

---

## Transaction History

Every transaction must include

* Transaction ID
* Amount
* Type
* Date
* Status
* Payment Method

---

# Phase 4 – Firebase

Create Firestore collections.

Example structure

users

wallet_transactions

payments

Store

Current Balance

Transaction History

Payment Status

Recharge History

---

# Phase 5 – Backend

Research how payment verification works.

Understand

Webhook

Payment Callback

Server-side Verification

Signature Validation

Explain why verification must happen on the backend instead of the mobile app.

---

# Phase 6 – Security

Research

Why API Keys should never be inside Flutter.

How secure payment gateways work.

How replay attacks are prevented.

How duplicate payments are avoided.

How failed transactions are handled.

---

# Phase 7 – Production Architecture

Design architecture.

Flutter

↓

Backend

↓

Payment Gateway

↓

Webhook

↓

Firebase

↓

Wallet Updated

Explain each component.

---

# Phase 8 – Error Handling

Handle

Payment Failed

Internet Lost

Cancelled Payment

Duplicate Request

Verification Failed

Timeout

Invalid Amount

Server Error

---

# Phase 9 – Testing

Test

Successful Payment

Failed Payment

Cancelled Payment

Low Internet

Multiple Recharge Attempts

Duplicate Transaction

Refresh Wallet

App Restart

---

# Phase 10 – Documentation

Prepare complete documentation.

Include

Project Overview

Architecture Diagram

Database Structure

API Flow

Challenges

Problems Faced

Solutions

Production Improvements

Future Enhancements

Lessons Learned

---

# Deliverables

Each intern must submit:

* Flutter source code
* Firebase configuration
* Database structure
* Architecture diagram
* Research document (PDF)
* Complete setup guide
* Demo video (5–10 minutes)
* Final presentation explaining the implementation

---

# Evaluation Criteria

| Criteria               | Weight |
| ---------------------- | ------ |
| Research Quality       | 20%    |
| Flutter Implementation | 25%    |
| Firebase Integration   | 15%    |
| Code Quality           | 15%    |
| Security Understanding | 10%    |
| Documentation          | 10%    |
| Presentation           | 5%     |

---

Important Notes

* Do not copy code from existing projects. Use official documentation and write your own implementation.
* Use sandbox/testing environments where available.
* Follow clean architecture and write readable, maintainable code.
* Document all assumptions and design decisions.
* Focus on understanding the complete payment lifecycle rather than only making a payment screen work.

This assignment will give practical experience with payment gateway integration, wallet management, backend verification, Firebase, and production-grade application architecture without exposing any real client or company project.