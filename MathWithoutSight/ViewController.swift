//
//  ViewController.swift
//  MathWithoutSight
//
//  Created by Maggie Gard on 6/20/18.
//  Copyright © 2018 Creighton University. All rights reserved.
//

import UIKit
import iosMath
import AVFoundation

class ViewController: UIViewController {
    
    // Link to main view controller
    @IBOutlet weak var mainView: UIView!
    
    // Initialize global variables
    var speechString: String!
    var expressionList: Array<String>!
    var initialList: Array<Any>!
    var visualLabel = MTMathUILabel()
    // Text sent to visual label
    let mathText = "\\pm x=\\frac{-b\\pm\\sqrt{b^2-4ac}}{-2a}"
//    let mathText = "x=\\frac{-2}{b}"
//    let mathText = "\\frac{-a}{\\sqrt{-c}}+2-4"
//    let mathText = "\\sqrt-d"
//    let mathText = "-a-b^{-cd}"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handles swipe gestures upon loading app
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        // Creates visuals and splits MTMathList
        initialize()
    }
    
    func initialize() {
        expressionList = createOtherLabels(nextMathText: mathText)
        createLabel()
        expressionList = parseOtherLabels()
        print(expressionList)
        speechString = sendToSynthesizer(expressionList: expressionList)
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        
        if (sender.direction == .left) {
            print("Swipe Left")
        }
        
        if (sender.direction == .right) {
            print("Swipe Right")
            // Inititalizes speech upon swiping right
            speechSynthesizer(audioText: speechString)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Gets screen width
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    // Gets screen height
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    
    func speechSynthesizer(audioText: String) {
        // Initialize full expression utterance
        let utterance = AVSpeechUtterance(string: audioText)
        // Choose voice of synthesizer
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        
        // Creates synthesizer and feeds utterance
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    // Creates visual label on screen
    func createLabel() {
        // Sizes iosMath visual label
        visualLabel.fontSize = screenHeight * 0.1
        visualLabel.sizeToFit()
        // Adds label to view
        mainView.addSubview(visualLabel)
        visualLabel.center = self.view.center
        // If VoiceOver was on, the LaTeX would be read
        visualLabel.accessibilityValue = mathText
        // Turns VoiceOver off for the visual label
        visualLabel.isAccessibilityElement = false
    }
    
    func createOtherLabels(nextMathText: String) -> Array<String> {
        visualLabel = MTMathUILabel()
        visualLabel.latex = nextMathText
        var newExpressionList = [String]()
        newExpressionList = parseExpression(visualLabel: visualLabel)
        return newExpressionList
    }
    
    // Called when further parsing is needed within the initial list of atoms
    func parseExpression(visualLabel: MTMathUILabel) -> Array<String> {
        let nextParsedList = visualLabel.mathList?.atoms
        print(nextParsedList ?? " ")
        var expressionListSend = [String]()
        for expression in nextParsedList! {
            // Expressions are turned into strings
            var expressionString = "\(expression)"
            // Descriptions are removed from atoms
            let mathString = cutString(expressionString: &expressionString)
            // Atoms without descriptions are appended to expressionList
            expressionListSend.append(mathString)
        }
        return expressionListSend
    }
    
    // Cuts the atom string descriptors so only math is left
    func cutString(expressionString: inout String) -> String {
        // If the atom is described as Open then the first 6 characters of the atom are removed
        if (expressionString[expressionString.startIndex] == "O" && expressionString[expressionString.index(after: expressionString.startIndex)] == "p") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 6)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as Close or Inner then the first 7 characters of the atom are removed. Accent is included in this group because the atom doesn't add a space after the colon.
        else if (expressionString[expressionString.startIndex] == "C" || expressionString[expressionString.startIndex] == "I" || expressionString[expressionString.startIndex] == "A") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 7)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as a Number then the first 8 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "N") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 8)
            expressionString.removeSubrange(cutRange)
        }
            // If the atom is described as a Radical then the first 9 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "R" && expressionString[expressionString.index(after: expressionString.startIndex)] == "a") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 9)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as a Variable, Fraction, Relation, Ordinary, or Overline then the first 10 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "V" || expressionString[expressionString.startIndex] == "R" || expressionString[expressionString.startIndex] == "F" || expressionString[expressionString.startIndex] == "O") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 10)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as Underline then the first 11 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "U" && expressionString[expressionString.index(after: expressionString.startIndex)] == "n" && expressionString[expressionString.index(expressionString.startIndex, offsetBy: 2)] == "d") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 11)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as Punctuation or a Placeholder then the first 13 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "P") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 13)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as a Large Operator or Unary Operator then the first 16 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "L" || expressionString[expressionString.startIndex] == "U") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 16)
            expressionString.removeSubrange(cutRange)
        }
        // If the atom is described as a Binary Operator then the first 17 characters of the atom are removed
        else if (expressionString[expressionString.startIndex] == "B") {
            let cutRange = expressionString.startIndex ..< expressionString.index(expressionString.startIndex, offsetBy: 17)
            expressionString.removeSubrange(cutRange)
        }
        return expressionString
    }
    
    // Creates string from expressionList and sends it to speechSynthesizer
    func sendToSynthesizer(expressionList: Array<String>) -> String {
        return expressionList.joined(separator: " ")
    }
    
    // Parses atoms from the initial list
    func parseOtherLabels() -> Array<String> {
        var nextExpressionList: Array<String>!
        var initialLength: Int = 1
        var endLength: Int = 0
        // Loop continues parsing until it does a pass where no atoms are expanded, signaling that the expression is fully parsed
        while initialLength != endLength {
            var i: Int = 0
            initialLength = expressionList.count
            // Goes through list one atom at a time
            for expression in expressionList {
                // If the expression (atom) is longer than one character, it should be parsed
                if expression.count != 1 {
                    // Checks if atom is /atop or /sqrt and cuts LaTeX out of expression before sending it to parser
                    if (expression[expression.index(after: expression.startIndex)] == "a" || expression[expression.index(after: expression.startIndex)] == "s") {
                        let cutRange = expression.startIndex ..< expression.index(expression.startIndex, offsetBy: 5)
                        var addExpression = expression
                        addExpression.removeSubrange(cutRange)
                        sendToParser(addExpression: addExpression, i: i)
                    }
                    // Removes carrot and splits atom allowing it to be parsed on next pass
                    else if (expression[expression.index(after: expression.startIndex)] == "^"){
                        nextExpressionList = expression.components(separatedBy: "^")
                        expressionList.remove(at: i)
                        expressionList.insert(contentsOf: nextExpressionList, at: i)
                    }
                    // Anything larger than 1 character is parsed
                    else {
                        let addExpression = expression
                        sendToParser(addExpression: addExpression, i: i)
                    }
                }
                // MAYBE TRY TO SPLIT BY MINUS SIGN HERE??? WILL MAKE THE LIST LONGER SO IT WILL LOOP AGAIN. NEED SOME WAY TO INDEX WHERE THE MINUS SIGN WAS TAKEN OUT AND PUT IT BACK IN AS A BINARY OPERATOR. WHY IS IT TAKING OUT THE MINUS SIGNS I DONT KNOW BUT ITS REALLY ANNOYING AND I HAVE NO CLUE HOW TO FIX IT AND I REALLY HOPE THERES AND EASIER WAY THAN JUST HARD CODING THE WHOLE PARSER FROM THE START BECAUSE THAT WOULD BE REALLY TIME CONSUMING AND WOULD REQUIRE A LOT OF SKILL THAT I DONT REALLY HAVE YET AND WOULD NEED TO GAIN BECAUSE SWIFT IS A WEIRD LANGUAGE AND XCODE CAN BE REALLY ANNOYING AT TIMES WITH ITS FATAL ERRORS AND WARNING MESSAGES THAT SEEM REALLY DESCRIPTIVE BUT ACTUALLY HIDE HOW THE REAL PROBLEM IS 200 LINES OF CODE DOWN BURIED IN A TINY FUNCTION YOU FORGOT WAS THERE AND CANT REMEMBER ITS PURPOSE BUT IT TURNS OUT IT CONNECTS EVERYTHING ELSE IN THE PROGRAM SO NOW YOUVE CREATED 4 MORE ERRORS BY FIXING THE FIRST ERROR...HI IT'S JESSIE ;)
                i += 1
            }
            endLength = expressionList.count
        }
        return expressionList
    }
    
    // Called from function checking for atoms that still need to be parsed. Modifies expressionList with newly parsed atoms
    func sendToParser(addExpression: String, i: Int) {
        var nextExpressionList: Array<String>!
        nextExpressionList = createOtherLabels(nextMathText: addExpression)
        expressionList.remove(at: i)
        expressionList.insert(contentsOf: nextExpressionList, at: i)
    }
    //This checks for minuses
    func checkForMinuses(
}