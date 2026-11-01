import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
// usage: rmbg in.png out.png tolerance pockets(0/1)
let a = CommandLine.arguments
let inURL = URL(fileURLWithPath: a[1]), outURL = URL(fileURLWithPath: a[2])
let tol = Int(a[3]) ?? 30
let pockets = a.count > 4 && a[4] == "1"
let src = CGImageSourceCreateWithURL(inURL as CFURL, nil)!
let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
let w = img.width, h = img.height
var d = [UInt8](repeating: 0, count: w*h*4)
let ctx = CGContext(data: &d, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
// background colour clusters from the border
var buckets: [Int: (Int, Int, Int, Int)] = [:]
func addB(_ i: Int) { let r = Int(d[i]), g = Int(d[i+1]), b = Int(d[i+2]); let k = (r/24)<<16 | (g/24)<<8 | (b/24); let v = buckets[k] ?? (0,0,0,0); buckets[k] = (v.0+r, v.1+g, v.2+b, v.3+1) }
var nb = 0
for x in 0..<w { addB(x*4); addB(((h-1)*w+x)*4); nb += 2 }
for y in 0..<h { addB(y*w*4); addB((y*w+w-1)*4); nb += 2 }
let centers = buckets.values.filter { $0.3 * 100 / nb >= 8 }.map { ($0.0/$0.3, $0.1/$0.3, $0.2/$0.3) }
FileHandle.standardError.write("centers \(centers)\n".data(using: .utf8)!)
func dist(_ i: Int, _ c: (Int,Int,Int)) -> Int { max(abs(Int(d[i])-c.0), abs(Int(d[i+1])-c.1), abs(Int(d[i+2])-c.2)) }
let neutralOnly = a.count > 5 ? Int(a[5]) ?? -1 : -1
func isBg(_ p: Int) -> Bool { let i = p*4
  if neutralOnly >= 0 { let mx = max(d[i], d[i+1], d[i+2]), mn = min(d[i], d[i+1], d[i+2]); if Int(mx) - Int(mn) > neutralOnly { return false } }
  return centers.contains { dist(i, $0) <= tol } }
func nearest(_ p: Int) -> Int { let i = p*4; var best = 0, bd = 999; for (k, c) in centers.enumerated() { let dd = dist(i, c); if dd < bd { bd = dd; best = k } }; return best }
var removed = [Bool](repeating: false, count: w*h)
var stack: [Int] = []
func seed(_ p: Int) { if !removed[p] && isBg(p) { removed[p] = true; stack.append(p) } }
for x in 0..<w { seed(x); seed((h-1)*w+x) }
for y in 0..<h { seed(y*w); seed(y*w+w-1) }
func flood() { while let p = stack.popLast() { let x = p % w, y = p / w
  if x > 0 { seed(p-1) }; if x < w-1 { seed(p+1) }; if y > 0 { seed(p-w) }; if y < h-1 { seed(p+w) } } }
flood()
var pocketCount = 0
if pockets && centers.count >= 2 {
  // enclosed checkerboard pockets: bg-coloured components that mix both checker tones
  var seen = removed
  for p0 in 0..<(w*h) where !seen[p0] && isBg(p0) {
    var comp: [Int] = [p0]; seen[p0] = true; var idx = 0; var tones = [Int](repeating: 0, count: centers.count)
    while idx < comp.count { let p = comp[idx]; idx += 1; tones[nearest(p)] += 1; let x = p % w, y = p / w
      for q in [x > 0 ? p-1 : -1, x < w-1 ? p+1 : -1, y > 0 ? p-w : -1, y < h-1 ? p+w : -1] where q >= 0 && !seen[q] && isBg(q) { seen[q] = true; comp.append(q) } }
    let sorted = tones.sorted(by: >)
    if comp.count > 200 && sorted[1] * 100 / comp.count >= 20 { for p in comp { removed[p] = true }; pocketCount += 1 }
  }
}
// edge cleanup: neutral, light-ish pixels touching removed background
let loose = tol + 25
let minL = (centers.map { min($0.0, $0.1, $0.2) }.min() ?? 0) - 40
for _ in 0..<3 {
  var add: [Int] = []
  for p in 0..<(w*h) where !removed[p] {
    let x = p % w, y = p / w
    let touch = (x > 0 && removed[p-1]) || (x < w-1 && removed[p+1]) || (y > 0 && removed[p-w]) || (y < h-1 && removed[p+w])
    if !touch { continue }
    let i = p*4; let mx = Int(max(d[i], d[i+1], d[i+2])), mn = Int(min(d[i], d[i+1], d[i+2]))
    if mx - mn <= 12 && mn >= minL && centers.contains(where: { dist(i, $0) <= loose }) { add.append(p) }
  }
  if add.isEmpty { break }
  for p in add { removed[p] = true }
}
// tiny opaque specks floating in removed area
var seen2 = removed
for p0 in 0..<(w*h) where !seen2[p0] {
  var comp = [p0]; seen2[p0] = true; var idx = 0
  while idx < comp.count { let p = comp[idx]; idx += 1; let x = p % w, y = p / w
    for q in [x > 0 ? p-1 : -1, x < w-1 ? p+1 : -1, y > 0 ? p-w : -1, y < h-1 ? p+w : -1] where q >= 0 && !seen2[q] { seen2[q] = true; comp.append(q) } }
  if comp.count <= 60 { for p in comp { removed[p] = true } }
}
var n = 0
for p in 0..<(w*h) where removed[p] { d[p*4] = 0; d[p*4+1] = 0; d[p*4+2] = 0; d[p*4+3] = 0; n += 1 }
FileHandle.standardError.write("removed \(n*100/(w*h))% pockets \(pocketCount)\n".data(using: .utf8)!)
let out = ctx.makeImage()!
let dst = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dst, out, nil); CGImageDestinationFinalize(dst)
