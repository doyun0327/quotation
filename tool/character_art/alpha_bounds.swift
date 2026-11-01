import Foundation
import CoreGraphics
import ImageIO
let dir = CommandLine.arguments[1]
let files = try! FileManager.default.contentsOfDirectory(atPath: dir).filter { $0.hasSuffix(".png") }.sorted()
for f in files {
  let url = URL(fileURLWithPath: dir + "/" + f) as CFURL
  guard let src = CGImageSourceCreateWithURL(url, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { continue }
  let w = img.width, h = img.height
  var data = [UInt8](repeating: 0, count: w * h * 4)
  let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
  var minX = w, maxX = -1, minY = h, maxY = -1
  for y in 0..<h { for x in 0..<w where data[(y * w + x) * 4 + 3] > 24 {
    if x < minX { minX = x }; if x > maxX { maxX = x }; if y < minY { minY = y }; if y > maxY { maxY = y } } }
  // fractions of the image: left, right, top, bottom transparent margins (top = first row in memory)
  print(String(format: "%@\t%dx%d\tL %.3f R %.3f T %.3f B %.3f", f, w, h, Double(minX)/Double(w), Double(w-1-maxX)/Double(w), Double(minY)/Double(h), Double(h-1-maxY)/Double(h)))
}
