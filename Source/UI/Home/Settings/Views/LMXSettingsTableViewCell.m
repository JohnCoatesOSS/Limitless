//
//  LMXSettingTableViewCell.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "LMXSettingsTableViewCell.h"
#import "LMXSettingsItem.h"

@interface LMXSettingsTableViewCell ()

@property (nonatomic) UISwitch *cellSwitch;
@property (nonatomic) UITextField *cellInput;

@end

@implementation LMXSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self initialSetup];
    }
    
    return self;
    
}

// MARK: - Setup

- (void)initialSetup {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// MARK: - Lazy Properties

- (UISwitch *)cellSwitch {
    if (_cellSwitch) {
        return _cellSwitch;
    }
    _cellSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    _cellSwitch.onTintColor = [UIColor colorWithRed:0.68
                                              green:0.41 blue:0.99 alpha:1.00];
    [_cellSwitch addTarget:self
                    action:@selector(switchToggled:)
          forControlEvents:UIControlEventValueChanged];
    return _cellSwitch;
}

- (UITextField *)cellInput {
    if (_cellInput) {
        return _cellInput;
    }
    _cellInput = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    _cellInput.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _cellInput.textAlignment = NSTextAlignmentLeft;
    _cellInput.returnKeyType = UIReturnKeyDone;
    _cellInput.delegate = self;
    
    return _cellInput;

}

// MARK: - Updating

- (void)setItem:(LMXSettingsItem *)item {
    _item = item;
    self.textLabel.text = item.name;
    
    switch (item.type) {
        case LMXSettingToggle:
            self.accessoryView = self.cellSwitch;
            [self updateSwitchToCurrentSettingsValue];
            break;
        case LMXSettingUnsignedIntValue:
            self.accessoryView = self.cellInput;
            [self updateInputToCurrentSettingsValue];
            break;
    }
}

- (void)updateSwitchToCurrentSettingsValue {
    NSString *settingKey = self.item.key;
    BOOL isOn = [NSUserDefaults.standardUserDefaults boolForKey:settingKey];
    [self.cellSwitch setOn:isOn animated:FALSE];
}

- (void)updateInputToCurrentSettingsValue {
    id defaultValue = self.item.defaultValue;
    
    if ([defaultValue respondsToSelector:@selector(description)]) {
        self.cellInput.placeholder = [defaultValue description];
    }
    
    NSString *settingsKey = self.item.key;
    id currentValue = [LMXSettingsController userDefinedObjectForKey:settingsKey];
    if ([currentValue respondsToSelector:@selector(description)]) {
        self.cellInput.text = [currentValue description];
    }
}

// MARK: - Value Events

- (void)switchToggled:(UISwitch *)sender {
    NSString *settingKey = self.item.key;
    [LMXSettingsController setValueForKey:settingKey
                               withObject:@(sender.isOn)];
}

// MARK: - Input Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSCharacterSet *allowedCharacters;
    switch (self.item.type) {
        case LMXSettingUnsignedIntValue:
            allowedCharacters = NSCharacterSet.decimalDigitCharacterSet;
            break;
            
        case LMXSettingToggle:
            [NSException raise:@"Invalid Item Setting"
                        format:@"Text field is being used for cell that is not set to a text input type."];
            break;
    }
    
    if (allowedCharacters) {
        NSCharacterSet *bannedCharacters = allowedCharacters.invertedSet;
        NSRange rangeOfBannedCharacters = [string rangeOfCharacterFromSet:bannedCharacters];
        if (rangeOfBannedCharacters.location != NSNotFound) {
            return FALSE;
        }
    }
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self saveValueFromTextField:textField];
    return TRUE;
}

// MARK: - Save Text

- (void)saveValueFromTextField:(UITextField *)textField {
    NSString *settingKey = self.item.key;
    NSString *rawValue = textField.text;
    
    if (rawValue.length == 0) {
        [LMXSettingsController setValueForKey:settingKey withObject:nil];
        return;
    }
    
    switch (self.item.type) {
        case LMXSettingToggle:
            [NSException raise:@"Invalid Option" format:@"Can't save toggle setting from a text field."];
            break;
        case LMXSettingUnsignedIntValue:
            [LMXSettingsController setValueForKey:settingKey
                                       withObject:@(rawValue.integerValue)];
            
            break;
            
    }
}

@end
