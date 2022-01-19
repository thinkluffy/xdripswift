//
//  Trc.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/18.
//  Copyright © 2022 thinkyeah. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public class Trc: RemoteConfigProvider {

    private static let log = Log(type: Trc.self)

    private let trcApi: TrcApi

    private var versionTag: String = ""
    private var content: JSON?

    public var useChinaUrl: Bool {
        get {
            trcApi.useChinaUrl
        }
        set {
            trcApi.useChinaUrl = newValue
        }
    }

    public init(trcId: String) {
        trcApi = TrcApi(trcId: trcId)
    }

    public var versionId: Int {
        int(forKey: "com_VersionId") ?? 0
    }

    public func refresh(completion: ((_ refreshed: Bool) -> Void)?) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.loadTrcResultFromFile()

            let params = TrcApi.RequestParams(
                    lastConfigId: self.versionTag,
                    productCode: self.trcApi.trcId,
                    appVersionCode: iOS.appVersionCode,
                    userRandomNumber: UserDefaults.standard.userRandomNumber,
                    region: iOS.region ?? "cn",
                    language: iOS.language(),
                    osVersion: iOS.systemVersion
            )

            self.trcApi.request(withParams: params) { result in
                self.content = result.content
                completion?(true)

                DispatchQueue.global(qos: .background).async {
                    self.saveTrcResultToFile(trcResult: result)
                }

            } onFailure: {
                Trc.log.e("Fail to request trcApi")
                completion?(false)

            } onNoChange: {
                Trc.log.i("Request trcApi responds no change, versionTag: \(self.versionTag)")
                completion?(false)
            }
        }
    }

    public func int(forKey key: String) -> Int? {
        if let ret = content?[key].int {
            return ret
        }
        return nil
    }

    public func bool(forKey key: String) -> Bool? {
        if let ret = content?[key].bool {
            return ret
        }
        return nil
    }

    public func string(forKey key: String) -> String? {
        if let ret = content?[key].string {
            return ret
        }
        return nil
    }

    public func json(forKey key: String) -> JSON? {
        if let contentCache = content, contentCache[key].exists() {
            return contentCache[key]
        }
        return nil
    }

    private var trcFileURL: URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                in: .userDomainMask).first else {
            Trc.log.e("Fail to get documentDirectory")
            return nil
        }

        return documentDirectory.appendingPathComponent("trc.json")
    }
    
    private func loadTrcResultFromFile() {
        guard let trcJsonFile = trcFileURL else {
            Trc.log.e("Fail to get trcJsonFile")
            return
        }

        do {
            let rawString = try String(contentsOf: trcJsonFile, encoding: .utf8)
            let json = JSON(parseJSON: rawString)

            if let versionTag = json["version_tag"].string, json["content"].exists() {
                self.versionTag = versionTag
                self.content = json["content"]
                Trc.log.d("Load trc result from file")

            } else {
                Trc.log.e("Fail to load trc result from file, unexpected file content, rawString: \(rawString)")
            }

        } catch let error {
            Trc.log.e("Fail to load trc result from file, \(error.localizedDescription)")
        }
    }

    private func saveTrcResultToFile(trcResult: TrcApi.TrcResult) {
        let json: JSON = [
            "version_tag": trcResult.versionTag,
            "content": trcResult.content
        ]

        guard let rawString = json.rawString() else {
            Trc.log.e("Fail to get rawString of json")
            return
        }
        
        guard let trcJsonFile = trcFileURL else {
            Trc.log.e("Fail to get trcJsonFile")
            return
        }

        do {
            try rawString.write(to: trcJsonFile,
                    atomically: true,
                    encoding: .utf8)
        } catch let error {
            Trc.log.e("Fail to save trc result to file, \(error.localizedDescription)")
        }
    }
}

fileprivate class TrcApi {

    private static let log = Log(type: TrcApi.self)

    private static let urlBaseGlobal = "https://trc.thinkyeah.com/api/v1/config"
    private static let urlBaseChina = "https://trc.doviapps.com/api/v1/config"

    // Request Keys
    private static let requestKeyProductCode = "product_code"
    private static let requestKeyAppVersionCode = "app_version_code"

    private static let requestKeyLanguage = "language"
    private static let requestKeyRegion = "region"

    private static let requestKeyUserRandomNumber = "user_random_number"
    private static let requestKeyLastConfigId = "last_config_id"
    private static let requestKeyOSVersion = "os_version"

    fileprivate var useChinaUrl = false

    fileprivate struct RequestParams {
        let lastConfigId: String?

        let productCode: String
        let appVersionCode: Int

        let userRandomNumber: Int

        let region: String
        let language: String

        let osVersion: String
    }

    fileprivate struct TrcResult {
        let versionTag: String
        let content: JSON
    }

    fileprivate let trcId: String

    fileprivate init(trcId: String) {
        self.trcId = trcId
    }

    fileprivate func request(withParams params: RequestParams,
                             onSuccess successCallback: @escaping (_ result: TrcResult) -> Void,
                             onFailure failureCallback: @escaping () -> Void,
                             onNoChange noChangeCallback: @escaping () -> Void) {

        let urlParams = [
            TrcApi.requestKeyProductCode: params.productCode,
            TrcApi.requestKeyAppVersionCode: String(params.appVersionCode),
            TrcApi.requestKeyLanguage: params.language,
            TrcApi.requestKeyRegion: params.region,
            TrcApi.requestKeyUserRandomNumber: String(params.userRandomNumber),
            TrcApi.requestKeyLastConfigId: params.lastConfigId ?? "",
            TrcApi.requestKeyOSVersion: params.osVersion
        ]

        AF.request((useChinaUrl ? TrcApi.urlBaseChina : TrcApi.urlBaseGlobal) + "/" + trcId, parameters: urlParams)
                .responseJSON {
                    response in

                    if response.response?.statusCode == 304 {
                        noChangeCallback()
                        return
                    }

                    switch response.result {
                    case .success:
                        guard let data = response.data else {
                            TrcApi.log.e("Fail to get response.data")
                            failureCallback()
                            return
                        }

                        do {
                            let json = try JSON(data: data)

                            if let versionTag = json["version_tag"].string, json["config"].exists() {
                                successCallback(TrcResult(versionTag: versionTag, content: json["config"]))

                            } else {
                                TrcApi.log.e("Unexpected response data, \(json)")
                                failureCallback()
                            }

                        } catch let error {
                            TrcApi.log.e("JSON Error, request: \(response.request!), data: \(data), error: \(error)")
                            failureCallback()
                        }

                    case let .failure(error):
                        TrcApi.log.e(error.errorDescription ?? "Unknown error")
                        failureCallback()
                    }
                }
    }
}
