//
//  LMXSourceCell.mm
//  Limitless
//
//  Created on 12/5/16.
//

#import "LMXSourceCell.h"
#import "APTSource.h"

@interface LMXSourceCell ()

@property UIView *textWrapper;
@property UILabel *titleLabel;
@property UILabel *subtitleLabel;

@property UIImageView *iconView;
@property UIActivityIndicatorView *activityIndicator;

@end

@implementation LMXSourceCell

// MARK: - Init

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier  {
    self = [super initWithStyle:style
                reuseIdentifier:reuseIdentifier];

    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self viewsSetup];
    }

    return self;
}

// MARK: - Setup

- (void)viewsSetup {
    [self iconViewSetup];
    [self textWrapperSetup];
    [self activityIndicatorSetup];
}

- (void)iconViewSetup {
    _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_iconView];
    
    _iconView.translatesAutoresizingMaskIntoConstraints = false;
    
    CGFloat iconSize = 29;
    [_iconView.widthAnchor constraintEqualToConstant:iconSize].active = TRUE;
    [_iconView.heightAnchor constraintEqualToAnchor:_iconView.widthAnchor].active = TRUE;
    [_iconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = TRUE;
    [_iconView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor
                                         constant:11].active = TRUE;
}

- (void)textWrapperSetup {
    _textWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_textWrapper];
    
    _textWrapper.translatesAutoresizingMaskIntoConstraints = false;
    [_textWrapper.leftAnchor constraintEqualToAnchor:_iconView.rightAnchor constant:12].active = TRUE;
    [_textWrapper.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = TRUE;
    
    [self titleLabelSetup];
    [self subtitleLabelSetup];
}

- (void)titleLabelSetup {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = LMXTheme.cellFontImportant;
    _titleLabel.textColor = LMXTheme.cellColorLabelImportant;
    [self.textWrapper addSubview:_titleLabel];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    [_titleLabel.leftAnchor constraintEqualToAnchor:_textWrapper.leftAnchor].active = TRUE;
    [_titleLabel.topAnchor constraintEqualToAnchor:_textWrapper.topAnchor].active = TRUE;
    [_textWrapper.rightAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.rightAnchor];
}

- (void)subtitleLabelSetup {
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.font = LMXTheme.cellFontUnimportant;
    _subtitleLabel.textColor = LMXTheme.cellColorLabelUnimportant;
    [_textWrapper addSubview:_subtitleLabel];
    
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = false;
    [_subtitleLabel.leftAnchor constraintEqualToAnchor:_textWrapper.leftAnchor].active = TRUE;
    [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2].active = TRUE;
    [_subtitleLabel.bottomAnchor constraintEqualToAnchor:_textWrapper.bottomAnchor].active = TRUE;
    [_textWrapper.rightAnchor constraintGreaterThanOrEqualToAnchor:_subtitleLabel.rightAnchor];
}

- (void)activityIndicatorSetup {
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [self.contentView addSubview:_activityIndicator];
    
    [_activityIndicator.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-4].active = TRUE;
    [_activityIndicator.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = TRUE;
    [_activityIndicator sizeToFit];
}

// MARK: - Property Setters

- (void)setSource:(APTSource *)source {
    if (!source) {
        return;
    }
    
    _source = source;
    _allSources = FALSE;
    
    self.titleLabel.text = source.name;
    self.subtitleLabel.text = source.uri.absoluteString;
    
    if (source.iconURL) {
        [self requestIconImage:source.iconURL];
    }
    
    self.isLoading = FALSE;
}

- (void)setAllSources:(BOOL)allSources {
    _allSources = allSources;
    
    if (allSources) {
        _source = nil;
    }
    
    self.titleLabel.text = NSLocalizedString(@"ALL_SOURCES", "");
    self.subtitleLabel.text = @"";
    self.iconView.image = [UIImage imageNamed:@"folder.png"];
    self.isLoading = FALSE;
}

- (void)setIsLoading:(BOOL)isLoading {
    if (self.activityIndicator.isAnimating == isLoading) {
        return;
    }
    
    if (isLoading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    [self setNeedsLayout];
}

// MARK: - Hydration

- (void)requestIconImage:(NSURL *)iconURL {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task = [session dataTaskWithURL:iconURL
                                        completionHandler:^(NSData * _Nullable data,
                                                         NSURLResponse * _Nullable response,
                                                         NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error retrieving icon URL %@: %@", iconURL, error);
            return;
        }
        
        UIImage *iconImage = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.iconView.image = iconImage;
            [self setNeedsLayout];
        });
    }];
    
    [task resume];
}

@end
