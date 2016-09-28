# 🆕 📱 📷 😀

New iPhone Camera Hack!

---
## 自己紹介

**@temoki**

![profile](SlideImages/profile.jpg)

* PL : エンジニア = 7 : 3
* iOS : Android = 9 : 1
* カメラ/写真 アプリ
* 雰囲気メガネ アプリ

---
## 新しい 📱 買いましたか？

---
## 📱 7 Plus + 艶々 JET BLACK

* 9月9日 16:01 予約受付開始
* 9月9日 16:07 予約できました
* 9月30日 いまだ処理中... 😭

---
## 今回の 📱 の個人的な目玉は...

---

## もちろんデュアルカメラ！
 二つのカメラが一つになって撮影します。

* より明るくなった広角カメラ F1.8 (28mm相当)
* 新しく加わった望遠カメラ F2.8 (56mm相当)

---
## デュアルで何が嬉しいのか？

* 📱 初の光学ズーム 2x
  * 👉 ~~デジタルズームと合わせて10x~~ (嬉しくない)
* 二つのセンサー情報をフル活用したシーン認識
  * 👉 最適な写真を撮影
* ポートレートモード *※* での被写界深度エフェクト
  * 👉 一眼レフカメラのようなボケを表現

*※ パブリックベータ配信中の iOS 10.1 から利用可能*

---
## そして色再現

* 広色域キャプチャー
  * 👉 従来の sRGB より広い色空間の P3 で撮影
* 広色域ディスプレイ
  * 👉 True Tone ディスプレイで P3 色空間を再現

---
## 過去最強と言わざるをえない！

---
## 📱 ➓ 📷 🅰🅿♊️️

iOS 10 Camera API

---
## Camera API Diff

* **Dual Camera & Camera Discovery**
* **New Photo Capture API**
  * **RAW Photo**
  * Live Photos
* Wide Color

---
## Dual Camera & Camera Discovery

---
## Dual Camera & Camera Discovery

* `AVCaptureDeviceDiscoverySession` - *NEW!*

```swift
let discoverySession = AVCaptureDeviceDiscoverySession(
                        deviceTypes: [.builtInDuoCamera],
                        mediaType: AVMediaTypeVideo,
                        position: .back)

let devices: [AVCaptureDevice]? = discoverySession?.devices
```

---
## Dual Camera & Camera Discovery

* `AVCaptureDeviceType` - *NEW!*
  * `.builtInWideAngleCamera`
  * `.builtInTelephotoCamera`
  * `.builtInDuoCamera`

---
## 同時キャプチャーできる！？

できたら被写界深度エフェクトみたいに

視差から立体認識してゴニョゴニョ...

---
## できません 😭

---
## `.builtInDuoCamera`

* 二つのカメラで最適化された一枚の写真だけが出力される
* 撮影に細かいコントロールはできない (お任せ)
* 後述の RAW フォーマット撮影も不可能

---
## `.builtInWideAngleCamera` & `.builtInTelephotoCamera`

```swift
let captureSession = AVCaptureSession()
captureSession.addInput(wideAngleCameraDevice)
captureSession.addInput(telephotoCameraDevice)
```
👇 **Terminating app due to uncaught exception !!!**

>  Multiple audio/video AVCaptureInputs are not currently supported'

---
## New Photo Capture API

---

## New Photo Capture API

* `AVCaptureStillImageOutput` - *Deprecated*
* `AVCapturePhotoOutput` - *NEW!*
  * **RAW Photo Capture**
  * Live Photo Capture

---
## RAW って？

* イメージセンサーから得られた未加工のデータ
* このデータから下記 **現像** 処理を経て保存される
  * デモザイクという色付け処理
  * 色・明るさなどの自動レタッチ処理
  * JPEG 等のフォーマットに圧縮

---
## JPEG と RAW

* JPEG
  * プロ (=) が焼き上げたケーキのようなもの
  * 再加工には限界がある
  * 誰でも・お手軽・コンパクト
* RAW
  * ケーキの材料一式のようなもの
  * 後からいくらでも加工ができる
  * 技術要・大変・大きい

---
## RAW 撮影ができるデバイス

* iPhone 7, 7 Plus
* iPhone 6s, 6s Plus
* iPhone SE
* iPad Pro 9.7 inch

※ ただしバックカメラのみ

---
## RAW 撮影ができるアプリ

* ❌ 標準カメラアプリ
* 🆗 Adobe Lightroom アプリ、など

---
## RAW 撮影ができる API

* ❌ `UIImagePickerController`
* 🆗 `AVFoundation`, `AVCapturePhotoOutput`

---
## `AVCapturePhotoOutput` で RAW 撮影

```swift
let rawFormat = photoOutput.availableRawPhotoPixelFormatTypes.first!.uint32Value
let settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
photoOutput.capturePhoto(with: settings, delegate: self)
```

---
## `AVCapturePhotoCaptureDelegate`

```swift
func capture(_ captureOutput: AVCapturePhotoOutput,
      didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?,
      previewPhotoSampleBuffer: CMSampleBuffer?,
      resolvedSettings: AVCaptureResolvedPhotoSettings,
      bracketSettings: AVCaptureBracketedStillImageSettings?,
      error: Error?) {

}
```

`rawSampleBuffer` から RAW データにアクセス可能

---
## RAW データをそのまま触る

```swift
// CVPixelBuffer
let pixelBuffer = CMSampleBufferGetImageBuffer(rawSampleBuffer!)
```

`CVPixelBuffer` にバイトデータとして含まれる

---
## RAW データを保存する

* Adobe DNG フォーマットで保存
* DNG は Adobe が標準化を目指す RAW のフォーマット
* **D** igital - **N** e **G** ative

```swift
let dngData: Data? = AVCapturePhotoOutput.dngPhotoDataRepresentation(
                      forRawSampleBuffer: rawSampleBuffer!,
                      previewPhotoSampleBuffer: previewPhotoSampleBuffer)
```

---
## RAW データを読み込む

* Core Image を使って CIImage を生成可能

```swift
let image: CIImage? = CIFilter(imageURL: fileURL, options: nil)?.outputImage
```

---
## RAW データを現像する

---
To be continued.
