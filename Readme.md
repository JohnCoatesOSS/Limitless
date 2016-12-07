## Limitless

![header](https://raw.githubusercontent.com/JohnCoatesOSS/Limitless/develop/Documentation/images/readmeHeader.png)

[![Gitter](https://img.shields.io/badge/chat-on%20gitter-46BC99.svg?style=flat-square)](https://gitter.im/JohnCoatesOSS/Limitless?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Build Status](https://img.shields.io/travis/JohnCoatesOSS/Limitless.svg?style=flat-square)](https://travis-ci.org/JohnCoatesOSS/Limitless)

![preview](https://raw.githubusercontent.com/JohnCoatesOSS/Limitless/develop/Documentation/images/preview.png)

#### What is this project?
What if Cydia, the popular jailbreak alternative to the App Store, didn't have to support iOS 2.0? What if it could use the latest iOS features? Limitless is a project aimed to be a vision of what Cydia can be if it's unrestricted. With a heavy focus on contributing to Cydia, new features will be open to be backported. This project is meant to further Cydia, and is not meant to be a competitor.

#### Why is this project needed?
Many in the jailbreak community are interested in contributing to Cydia. This has been proven to be very difficult. Coders find it hard to get Cydia to even compile, much less run on the iOS simulator. Designers fail to get any traction. We alleviate these issues. All contributors are welcome with open arms, and we welcome all discussions regarding features or direction of the project.

#### How will the changes be implemented into Cydia?
No promises on that front, that's solely up to Saurik's discretion as he is the creator and maintainer of Cydia. The goal is to first implement a feature in Limitless, then submit for consideration to Saurik, and if given the go-ahead we'll backport to Cydia's constraints.

#### Design Goals

- Bring in features requested by the community.
- Develop a vision for the future of the jailbreak community, and execute based on that vision.
- Clean up the Cydia codebase.
- Backport features for Cydia that make sense to be integrated.

#### Contributors & Community
We're an open, transparent, community-driven project, always looking to welcome new contributors.
- **Designer?**  Take a look at open [design issues](https://github.com/johncoatesoss/limitless/issues?q=is%3Aopen+is%3Aissue+label%3Adesign) to find something you can help out on.
- **Coder?**  Take a look at [coder wanted issues](https://github.com/JohnCoatesOSS/Limitless/issues?utf8=%E2%9C%93&q=is%3Aissue%20label%3A%22coder%20wanted%22%20) to find something you can help out on.
- **Want to chat with other collaborators?** [Join the chat on Gitter.](https://gitter.im/JohnCoatesOSS/Limitless) Looking for coders, designers, feature managers, anyone that wants to help.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoatesOSS/Limitless/issues/new). Tell us why this feature would be useful, and why you and others would want it.

#### Why is it called Limitless?
There are a lot of limitations to writing code for Cydia. Because it needs to support iOS 2.0+, new features can't easily be written taking advantage of Automatic Reference Counting (ARC), Auto Layout, and all the hundreds of new APIs that have been made available in the recent years. With Limitless the plan is to have none of these limitations. We'll implement features while targeting the latest jailbreak release, and with a popular code style guide. Once approved to be backported, a feature will be re-written with a style guide that matches Cydia's current style, and with APIs that will maintain full compatibility with all iOS versions.

### Compiling, Running

Open Limitless.xcodeproj in Xcode 8.1, and run.  

If you want to run on your device, make sure your Team setting is configured in the Limitless target's General configuration tab.
