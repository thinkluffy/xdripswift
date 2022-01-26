//
//  RemoteConfigProvider.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2022/1/19.
//  Copyright © 2022 zDrip. All rights reserved.
//

import SwiftyJSON

public protocol RemoteConfigProvider {

    var versionId: Int { get }

    func refresh(completion: ((_ refreshed: Bool) -> Void)?)

    func int(forKey key: String) -> Int?

    func bool(forKey key: String) -> Bool?

    func string(forKey key: String) -> String?

    func json(forKey key: String) -> JSON?

}
