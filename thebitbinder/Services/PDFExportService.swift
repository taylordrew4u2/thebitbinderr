//
//  PDFExportService.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import UIKit
import PDFKit

class PDFExportService {
    
    static func exportJokesToPDF(jokes: [Joke], fileName: String = "BitBinder_Jokes") -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "The BitBinder",
            kCGPDFContextAuthor: "The BitBinder App",
            kCGPDFContextTitle: fileName
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsURL.appendingPathComponent("\(fileName).pdf")
        
        do {
            try renderer.writePDF(to: pdfURL) { context in
                let margin: CGFloat = 72.0 // 1 inch margin
                let contentWidth = pageWidth - (2 * margin)
                var yPosition: CGFloat = margin
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
                
                let jokeNumberAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                
                let jokeContentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                
                // Start first page
                context.beginPage()
                
                // Draw title
                let title = "The BitBinder - Jokes"
                let titleSize = title.size(withAttributes: titleAttributes)
                title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
                yPosition += titleSize.height + 30
                
                // Draw jokes
                for (index, joke) in jokes.enumerated() {
                    let jokeNumber = "\(index + 1). \(joke.title)"
                    let jokeNumberSize = jokeNumber.boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: jokeNumberAttributes,
                        context: nil
                    ).size
                    
                    // Check if we need a new page
                    if yPosition + jokeNumberSize.height > pageHeight - margin {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    // Draw joke number/title
                    jokeNumber.draw(
                        in: CGRect(x: margin, y: yPosition, width: contentWidth, height: jokeNumberSize.height),
                        withAttributes: jokeNumberAttributes
                    )
                    yPosition += jokeNumberSize.height + 10
                    
                    // Draw joke content
                    let jokeContentSize = joke.content.boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: jokeContentAttributes,
                        context: nil
                    ).size
                    
                    // Check if we need a new page for content
                    if yPosition + jokeContentSize.height > pageHeight - margin {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    joke.content.draw(
                        in: CGRect(x: margin, y: yPosition, width: contentWidth, height: jokeContentSize.height),
                        withAttributes: jokeContentAttributes
                    )
                    yPosition += jokeContentSize.height + 30
                }
            }
            
            return pdfURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }
}
