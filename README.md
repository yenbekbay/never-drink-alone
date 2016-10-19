<img src=".github/hero.png" alt="Never Drink Alone logo" height="70">

Never Drink Alone is an iOS app that gives you a chance to meet interesting people in your city. It sends you one meeting proposal a day and you can either accept it or reject it.

<img src=".github/screenshots.jpg" width="520">

## Stack

Never Drink Alone iOS app is written in Objective-C using the MVVM architecture. It's built with [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), [AFNetworking](https://github.com/AFNetworking/AFNetworking), [Firebase](https://firebase.google.com/docs/ios/setup) and [Parse SDK](https://github.com/ParsePlatform/Parse-SDK-iOS-OSX).

Never Drink Alone backend is built on top of Parse BaaS. Unfortunately, Parse [was shut down](http://blog.parse.com/announcements/moving-on/), so this setup is not going to be functional.
You can however use the source code for you learning purposes or modify it to build a backend on [Parse Server](https://github.com/ParsePlatform/parse-server).

## Setup

1. Clone the repo:
```console
$ git clone https://github.com/yenbekbay/never-drink-alone
$ cd never-drink-alone
```

2. Install iOS app dependencies from [CocoaPods](http://cocoapods.org/#install):
```console
$ (cd ios && bundle install && pod install)
```

3. Configure the secret values for the iOS app:
```console
$ cp ios/NeverDrinkAlone/Secrets-Example.h ios/NeverDrinkAlone/Secrets.h
$ open ios/NeverDrinkAlone/Secrets.h
# Paste your values
```

4. Open the Xcode workspace at `ios/NeverDrinkAlone.xcworkspace` and run the app.

## License

[MIT License](./LICENSE) © Ayan Yenbekbay
