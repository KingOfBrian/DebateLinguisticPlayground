//: Please build the scheme 'BonMotPlayground' first
import XCPlayground
import Foundation
import BonMot
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true


let options: NSLinguisticTagger.Options = [.omitWhitespace, .joinNames, .omitOther]
let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "en"), options: Int(options.rawValue))

// return an array of tuples containing the type or linguistic class and the range
public func tagRanges(for content: String) -> [(tag: String, range: NSRange)] {
    tagger.string = content

    let range = NSRange(location: 0, length: content.utf16.count)

    var types: [(String, NSRange)] = Array()

    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in

        types.append((tag, tokenRange))
    }
    return types
}
// This function investigates the end of sentences. It will return ranges of the last Verb -> punctuation. It will include the preceeding pronoun if available.
public func interestingRanges(for content: String) -> [NSRange] {
    let ranges = tagRanges(for: content).reversed()
    // Iterate in pairs
    let paired = zip(ranges.dropLast(), ranges.dropFirst())

    var interestingRanges: [NSRange] = Array()
    var interestEndCursor : Int?
    let terminatingTags = [NSLinguisticTagPunctuation, NSLinguisticTagSentenceTerminator, NSLinguisticTagDash]
    for (current, preceeding) in paired {
        let isTerminator = terminatingTags.contains(current.tag)
        if interestEndCursor == nil && isTerminator && preceeding.tag == NSLinguisticTagNoun {
            interestEndCursor = current.range.location
        }
        else if let interestEnd = interestEndCursor {
            if current.tag == NSLinguisticTagVerb {
                let ending = preceeding.tag == NSLinguisticTagPronoun ? preceeding : current
                let interestStart = ending.range.location
                let range = NSRange(location: interestStart, length: interestEnd - interestStart)
                interestingRanges.append(range)
                interestEndCursor = nil
            }
            if isTerminator {
                interestEndCursor = nil
            }
        }
    }
    return interestingRanges.reversed()
}

let path = Bundle.main.path(forResource: "Debate", ofType: "xml")!
let data = try! Data(contentsOf: URL(fileURLWithPath: path))
let dataString = String(data: data, encoding: String.Encoding.utf8)!
var styler = SimpleXMLStyler(tagStyles: TagStyles(styles: ["p": BonMot()]))
styler.add(suffix: .text("\n"), forElement: "p")
let debate = try! NSMutableAttributedString(fromXML: dataString, styler: styler, options: [.allowUnregisteredElements])

let content = debate.string as NSString

//for range in interestingRanges(for: debate.string) {
//    print(content.substring(with: range))
//}

for range in interestingRanges(for: debate.string) {
    debate.addAttributes(BonMot(.textColor(.red)).attributes(), range: range)
}
debate
/*
let label = UITextView()
label.attributedText = debate
//label.playgroundLiveViewRepresentation()
print("Done")
PlaygroundPage.current.liveView = label
print("Done")
*/