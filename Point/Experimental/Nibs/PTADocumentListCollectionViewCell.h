//
//  PTADocumentListCollectionViewCell.h
//  Point
//
//  Created by Mikey Lintz on 8/31/14.
//  Copyright (c) 2014 Mikey Lintz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PTADocumentListCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastModifiedLabel;

@end
