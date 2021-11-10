//
//  StretchyHeaderCollectionViewLayout.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/4/21.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit

class StretchyHeaderCollectionViewLayout: UICollectionViewFlowLayout {
    
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
                    let height = attribute.frame.height - contentOffsetY
                    attribute.frame = CGRect(x: 0, y: contentOffsetY, width: width, height: height)
                }
            }
        })
        return layoutAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
