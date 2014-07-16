//
//  OTRAccountTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 11/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRAccountTableViewCell.h"

#import "OTRAccount.h"
#import "OTRProtocolManager.h"
#import "OTRProtocol.h"

#import "Strings.h"
#import "OTRLog.h"

#import "OTRImages.h"

@interface OTRAccountTableViewCell ()
@property (nonatomic, strong) NSString *accountUniqueIdentifier;
@property (nonatomic, strong) NSObject<OTRProtocol> *protocol;

@end

@implementation OTRAccountTableViewCell

- (id)initWithReuseIdentifier:(NSString *)identifier
{
    return [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
}

- (void)setAccount:(OTRAccount *)account
{
    [self.protocol removeObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus))];
    self.accountUniqueIdentifier = account.uniqueId;
    
    self.textLabel.text = account.username;
    if (account.displayName.length){
        self.textLabel.text = account.displayName;
    }
    
    
    self.imageView.image = [account accountImage];
    
    if( account.accountType == OTRAccountTypeFacebook)
    {
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.cornerRadius = 10.0;
    }
    
    OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
    self.protocol = [[OTRProtocolManager sharedInstance].protocolManagers objectForKey:account.uniqueId];
    if (self.protocol) {
        [self.protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus)) options:NSKeyValueObservingOptionNew context:NULL];
        [self setConnectedText:self.protocol.connectionStatus];
    }
    else {
        [protocolManager addObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers)) options:NSKeyValueObservingOptionNew context:NULL];
        [self setConnectedText:OTRProtocolConnectionStatusDisconnected];
    }
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(connectionStatus))]) {
        OTRProtocolConnectionStatus connectionStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        [self setConnectedText:connectionStatus];
    }
    else if ([keyPath isEqualToString:NSStringFromSelector(@selector(protocolManagers))]) {
        self.protocol = [[OTRProtocolManager sharedInstance].protocolManagers objectForKey:self.accountUniqueIdentifier];
        if (self.protocol) {
            [self setConnectedText:self.protocol.connectionStatus];
            [self.protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus)) options:NSKeyValueObservingOptionNew context:NULL];
            [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers))];
        }
    }
    
}

- (void)setConnectedText:(OTRProtocolConnectionStatus)connectionStatus {
    if (connectionStatus == OTRProtocolConnectionStatusConnected) {
        self.detailTextLabel.text = CONNECTED_STRING;
    }
    else if (connectionStatus == OTRProtocolConnectionStatusConnecting)
    {
        self.detailTextLabel.text = CONNECTING_STRING;
    }
    else {
        self.detailTextLabel.text = nil;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)dealloc {
    [self.protocol removeObserver:self forKeyPath:NSStringFromSelector(@selector(connectionStatus))];
    @try {
        [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers))];
    }
    @catch (NSException *exception) {
        DDLogError(@"Error removing Observer: %@",exception);
    }
    
}

@end