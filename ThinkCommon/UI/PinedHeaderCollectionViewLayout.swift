//
//  PinedHeaderCollectionViewLayout.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/30.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class PinedHeaderCollectionViewLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)
        
        layoutAttributes?.forEach({ (attribute) in
            if attribute.representedElementKind == UICollectionView.elementKindSectionHeader &&
                attribute.indexPath.section == 0 {
                guard let collectionView = collectionView else {
                    return
                }
                
                let contentOffsetY = collectionView.contentOffset.y
                if contentOffsetY < 0 {
                    let width = collectionView.frame.width
                    attribute.frame = CGRect(x: 0, y: contentOffsetY, width: width, height: attribute.frame.height)
                }
            }
        })
        return layoutAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
