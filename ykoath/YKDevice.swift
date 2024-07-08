//
//  YKDevice.swift
//  ykoath
//
//  Created on 22.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import CryptoTokenKit

enum YKDeviceError: Error {
    case noSlot,
        noDevice,
        appSelectFailed,
        wrongInput,
        invalidDevice,
        validationNotEnabled,
        unexpected
}

class YKDevice {
    private let card: TKSmartCard
    private let queue: DispatchQueue

    private var inSession = false
    private var devParameters: YKSelect.Response? = nil

    var identifier: String? {
        return devParameters?.identifier
    }

    var isValidationEnabled: Bool? {
        return devParameters?.isRequiresValidation
    }

    private init(_ card: TKSmartCard) {
        self.card = card
        self.card.isSensitive = true
        self.queue = DispatchQueue(label: String(format: "net.dflab.ykdevice.%i", card.hash))
    }

    deinit {
        if inSession {
            card.endSession()
            inSession = false
            devParameters = nil
        }
    }

    func put(_ credential: YKCredential, completion handler: @escaping(Error?)->Void) {
        let data = YKPut.Request(credential)?.data
        genericRequest(data, completion: handler)
    }

    func delete(_ credential: YKCredential, completion handler: @escaping(Error?)->Void) {
        let data = YKDelete.Request(credential)?.data
        self.genericRequest(data, completion: handler)
    }

    func derive(_ password: String) -> YKDerivedKey? {
        guard let parameters = self.devParameters else {
            return nil
        }

        return YKDerivedKey(salt: parameters.name, password: password)
    }

    func resetDevice(completion handler: @escaping (Error?)->Void) {
        let data = YKReset.Request(resetDevice: true)?.data
        self.genericRequest(data, completion: handler)
    }

    func cleanKey(completion handler: @escaping (Error?)->Void) {
        let data = YKSetCode.Request(removeCode: true)?.data
        self.genericRequest(data, completion: handler)
    }

    func setKey(_ key: YKDerivedKey, completion handler: @escaping (Error?)->Void) {
        self.inSession { (error) in
            if let error = error {
                handler(error)
                return
            }

            guard let params = self.devParameters else {
                handler(YKDeviceError.noDevice)
                return
            }

            let algo = params.algorithm ?? YKAlgorithm.HMACSHA1

            let data = YKSetCode.Request(key, algo: algo).data
            self.genericRequest(data, completion: handler)
        }
    }

    func validate(_ key: YKDerivedKey, completion handler: @escaping(Error?)->Void) {
        self.inSession { (error) in
            if let error = error {
                handler(error)
                return
            }
            guard let parameters = self.devParameters else {
                handler(YKDeviceError.unexpected)
                return
            }

            guard let challenge = parameters.challenge,
                let algo = parameters.algorithm else {
                    handler(YKDeviceError.validationNotEnabled)
                    return
            }

            let unlockReq = YKValidate.Request(challenge: challenge, key: key, algo: algo)

            self.card.transmit(unlockReq.data, reply: { (data, error) in
                guard let data = data else {
                    handler(error ?? YKDeviceError.unexpected)
                    return
                }
                let reply = APDUResponse(data)

                if reply.success {
                    guard let deviceReply = reply.consume(dataForTag: 0x75),
                              deviceReply == unlockReq.expectedReply
                        else {
                            handler(YKDeviceError.invalidDevice)
                            return
                    }
                    handler(nil)
                } else {
                    handler(reply.error ?? YKDeviceError.unexpected)
                }
            })
            
        }
    }

    func calculateAll(_ handler: @escaping ([YKCredential]?, Error?)->Void) {
        self.inSession { (error) in
            if let error = error {
                handler(nil, error)
                return
            }

            let calcReq = YKCalculateAll.Request().data
            self.card.transmit(calcReq) { (d, e) in
                guard let data = d else {
                    handler(nil, e ?? YKDeviceError.unexpected)
                    return
                }

                let resp = APDUResponse(data)

                self.queue.suspend()
                self.collectMultipart(resp, { (collectedResponse, e1) in
                    self.queue.resume()
                    guard let collectedResponse = collectedResponse else {
                        handler(nil, e1 ?? YKDeviceError.unexpected)
                        return
                    }

                    let calculated = YKCalculateAll.Response(collectedResponse)

                    if let err = calculated.error {
                        handler(nil, err)
                    } else {
                        handler(calculated.codes, nil)
                    }
                })
            }
        }
    }

    func calculate(_ cred: YKCredential, handler: @escaping (YKCredential?, Error?) -> Void) {

        guard let reqData = YKCalculate.Request(label: cred.ykLabel) else {
            handler(nil, YKDeviceError.wrongInput)
            return
        }

        self.inSession { (error) in
            if let error = error {
                handler(nil, error)
                return
            }

            self.card.transmit(reqData.data, reply: { (d, e) in
                guard let data = d else {
                    handler(nil, e ?? YKDeviceError.unexpected)
                    return
                }

                let rawResp = APDUResponse(data)
                let resp = YKCalculate.Response(rawResp)

                guard let c = resp.code,
                      let cLen = resp.codeLen else {
                        handler(nil, resp.error ?? YKDeviceError.unexpected)
                        return
                }

                let result = YKCredential(cred, rawCode: c, codeLen: cLen)
                handler(result, nil)
            })
        }
    }

    private func collectMultipart(_ resp: APDUResponse, _ handler: @escaping (APDUResponse?, Error?)->Void) {
        guard resp.needsMoreData else {
            handler(resp, nil)
            return
        }

        let req = APDU(.sendRemaining, p1: 0x00, p2: 0x00, data: Data())
        card.transmit(req.packetData, reply: { (data, error) in
            guard let data = data else {
                handler(nil, error ?? YKDeviceError.unexpected)
                return
            }

            resp.append(data)
            self.collectMultipart(resp, handler)
        })
    }

    // starts session and selects application
    private func inSession(_ handler: @escaping (Error?)->Void ) {
        self.queue.async {
            guard self.card.isValid else {
                handler(YKDeviceError.noDevice)
                return
            }

            guard !self.inSession else {
                handler(nil)
                return
            }

            self.queue.suspend()
            self.beginSession(handler)
        }
    }

    private func beginSession(_ handler: @escaping (Error?) -> Void) {
        self.card.beginSession { (isSuccess, err) in
            if let err = err {
                handler(err)
                self.queue.resume()
                return
            }

            guard isSuccess else {
                handler(YKDeviceError.unexpected)
                self.queue.resume()
                return
            }

            let req = YKSelect.Request().data
            self.card.transmit(req, reply: { (data, error) in

                guard let data = data else {
                    handler(error ?? YKDeviceError.unexpected)
                    self.card.endSession()
                    self.queue.resume()
                    return
                }
                guard let reply = YKSelect.Response(data) else {
                    handler(YKDeviceError.appSelectFailed)
                    self.card.endSession()
                    self.queue.resume()
                    return
                }

                self.queue.async {
                    self.devParameters = reply
                    self.inSession = true
                    handler(nil)
                }
                self.queue.resume()
            })
        }
    }

    func endSession() {
        self.queue.async {
            if self.inSession {
                self.card.endSession()
                self.devParameters = nil
                self.inSession = false
            }
        }
    }

    //should always be performed in session!
    private func genericRequest(_ data: Data?, completion handler: @escaping (Error?)->Void) {

        guard let data = data else {
            handler(YKDeviceError.wrongInput)
            return
        }

        self.inSession { (error) in
            if let error = error {
                handler(error)
                return
            }

            self.card.transmit(data, reply: { (data, error) in
                guard let data = data else {
                    handler(error ?? YKDeviceError.unexpected)
                    return
                }

                let response = APDUResponse(data)
                if response.success {
                    handler(nil)
                } else {
                    handler(response.error ?? YKDeviceError.unexpected)
                }
            })
        }
    }
}

fileprivate weak var _instance: YKDevice? = nil
extension YKDevice {
    class func first(completion handler: @escaping (YKDevice?, Error?)->Void) {

        if let inst = _instance, inst.card.isValid  {
            inst.inSession { (error) in
                if error == nil {
                    handler(inst, nil)
                } else {
                    _instance = nil
                    first(completion: handler)
                }
            }
            return
        }

        guard let manager = TKSmartCardSlotManager.default else {
            handler(nil, YKDeviceError.noSlot)
            return
        }

        for name in manager.slotNames {
            if name.lowercased().contains("yubikey") {
                manager.getSlot(withName: name) { (slot) in
                    guard let slot = slot else {
                        handler(nil, YKDeviceError.noSlot)
                        return
                    }

                    guard let card = slot.makeSmartCard() else {
                        handler(nil, YKDeviceError.noDevice)
                        return
                    }

                    let dev = YKDevice(card)

                    dev.inSession({ (error) in
                        if let error = error {
                            handler(nil, error)
                        } else {
                            _instance = dev
                            handler(dev, nil)
                        }
                    })
                }

                return
            }
        }

        // if we're here - nothing is found
        handler(nil, YKDeviceError.noSlot)
    }
}
