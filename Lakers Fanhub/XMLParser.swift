//
//  XMLParser.swift
//  Lakers Fanhub
//
//  Created by Li Yin on 4/6/16.
//  Copyright © 2016 Li Yin. All rights reserved.
//

import Foundation
@objc protocol XMLParserDelegate{
    func parseWasFinished()
}

class XMLParser: NSObject, NSXMLParserDelegate {
    
    var parsedDataArray = [[String:String]]()
    var currentDataDic = [String:String]()
    var attributesDic = [String:String]()
    var currentElement = ""
    var foundCharacters = ""
    
    var delegate: XMLParserDelegate?
    
    func parseWithURL(rssURL: NSURL){
        
        guard let parser = NSXMLParser(contentsOfURL: rssURL) else {
            print("error when parser rssURL")
            return}
        parser.delegate = self
        parser.parse()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
         currentElement = elementName
         attributesDic = attributeDict
         if currentElement == "link" && attributesDic["rel"] == "alternate"{
            foundCharacters += attributesDic["href"]!
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if (currentElement == "name" || (currentElement == "title" && attributesDic["type"] != "text") || currentElement == "published"){
            foundCharacters += string
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if !foundCharacters.isEmpty{
            
//            if elementName == "name"{
//                foundCharacters = (foundCharacters as NSString).substringToIndex(3)
//            }
        
            currentDataDic[currentElement] = foundCharacters
            
            
            if currentElement == "published"{
                parsedDataArray.append(currentDataDic)
            }
            foundCharacters = ""
            currentElement = ""
            attributesDic = [String:String]()
            
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        delegate?.parseWasFinished()
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print(parseError.description)
    }
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) {
        print(validationError.description)
    }
}











