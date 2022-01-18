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

public class Trc {

    private static let log = Log(type: Trc.self)

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

    public var useChinaUrl = false

    public struct RequestParams {
        let lastConfigId: String?

        let productCode: String
        let appVersionCode: Int

        let userRandomNumber: Int

        let region: String
        let language: String

        let osVersion: String
    }

    public struct TrcResult {
        let versionTag: String
        let content: JSON
    }

    private let trcId: String
    
    public init(trcId: String) {
        self.trcId = trcId
    }
    
    public func request(withParams params: RequestParams,
                        onSuccess successCallback: @escaping (_ result: TrcResult) -> Void,
                        onFailure failureCallback: @escaping () -> Void,
                        onNoChange noChangeCallback: @escaping () -> Void) {

        let urlParams = [
            Trc.requestKeyProductCode: params.productCode,
            Trc.requestKeyAppVersionCode: String(params.appVersionCode),
            Trc.requestKeyLanguage: params.language,
            Trc.requestKeyRegion: params.region,
            Trc.requestKeyUserRandomNumber: String(params.userRandomNumber),
            Trc.requestKeyLastConfigId: params.lastConfigId ?? "",
            Trc.requestKeyOSVersion: params.osVersion
        ]

        AF.request((useChinaUrl ? Trc.urlBaseChina : Trc.urlBaseGlobal) + "/" + trcId, parameters: urlParams)
                .responseJSON {
                    response in

                    if response.response?.statusCode == 304 {
                        noChangeCallback()
                        return
                    }
                    
                    switch response.result {
                    case .success:
                        guard let data = response.data else {
                            Trc.log.e("Fail to get response.data")
                            failureCallback()
                            return
                        }

                        do {
                            let json = try JSON(data: data)
                            
                            if let versionTag = json["version_tag"].string, json["config"].exists() {
                                successCallback(TrcResult(versionTag: versionTag, content: json["config"]))
                                
                            } else {
                                Trc.log.e("Unexpected response data, \(json)")
                                failureCallback()
                            }
                            
                        } catch let error {
                            Trc.log.e("JSON Error, request: \(response.request!), data: \(data), error: \(error)")
                            failureCallback()
                        }

                    case let .failure(error):
                        Trc.log.e(error.errorDescription ?? "Unknown error")
                        failureCallback()
                    }
                }
    }
}
