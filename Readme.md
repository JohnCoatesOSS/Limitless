## Limitless

![header](https://raw.githubusercontent.com/JohnCoatesOSS/Limitless/develop/Documentation/images/readmeHeader.png)

[![Gitter](https://badges.gitter.im/JohnCoatesOSS/Limitless.svg)](https://gitter.im/JohnCoatesOSS/Limitless?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Build Status](https://travis-ci.org/JohnCoatesOSS/Limitless.svg?branch=develop)](https://travis-ci.org/JohnCoatesOSS/Limitless)

![preview](https://raw.githubusercontent.com/JohnCoatesOSS/Limitless/develop/preview.png)

#### What is this project?
What if Cydia, the popular jailbreak alternative to the App Store, didn't have to support iOS 2.0? What if it could use the latest iOS features? Limitless is a project aimed to be a vision of what Cydia can be if it's unrestricted. With a heavy focus on contributing to Cydia, new features will be open to be backported.

#### Why is this project needed?
Many coders find it hard to get up and running with contributing to Cydia. This project is meant to make it easier for someone to get started with contributing. The goal is to have an Xcode project anyone can easily run and understand.

#### How will the changes be implemented into Cydia?
No promises on that front, that's solely up to Saurik's discretion as he is the creator and maintainer of Cydia. The goal is to first implement a feature in Limitless, then submit for consideration to Saurik, and if given the go-ahead we'll backport to Cydia's constraints.

#### Design Goals

- Bring in features requested by the community.
- Develop a vision for the future of the jailbreak community, and execute based on that vision.
- Clean up the Cydia codebase.
- Backport features for Cydia that make sense to be integrated.

#### Community
- **Want to join the project?** [Join the chat on Gitter.](https://gitter.im/JohnCoatesOSS/Limitless) Looking for coders, designers, feature managers, anyone that wants to help.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoatesOSS/Limitless/issues/new). Tell us why this feature would be useful, and why you and others would want it.

#### Why is it called Limitless?
There are a lot of limitations to writing code for Cydia. Because it needs to support iOS 2.0+, new features can't be written taking advantage of Auto Layout, Storyboards, and all the hundreds of new APIs that have cropped up in the recent years. With Limitless the plan is to have none of these limitations. We'll implement features while targeting the latest jailbreak release, and with a popular style guide. Once approved to be backported, a feature will be re-written with a style guide that matches Cydia's current style, and with APIs that will maintain full compatibility with all iOS versions.

#### [Cydia Backporting Style Guide](./Documentation/BackportingStyleGuide.md)

### Compiling, Running
Make sure Xcode's command line tools are installed by running `xcode-select --install` in Terminal

Open XcodeProject/Cydia.xcodeproj
