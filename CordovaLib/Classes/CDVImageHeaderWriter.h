//
//  CDVImageHeaderWriter.h
//  CordovaLib
//
//  Created by Lorin Beer on 2012-10-02.
//
//

#import <Foundation/Foundation.h>

@interface CDVImageHeaderWriter : NSObject {
    NSDictionary * SubIFDTagFormatDict;
    NSDictionary * IFD0TagFormatDict;
}

- (void) readExifMetaData : (NSData*) imgdata;
- (void) insertExifMetaData : (NSData*) imgdata: (NSDictionary*) exifdata;
- (void) locateExifMetaData : (NSData*) imgdata;
/**
 * creates an IFD field
 * Bytes 0-1 Tag code
 * Bytes 2-3 Data type
 * Bytes 4-7 Count, number of elements of the given data type
 * Bytes 8-11 Value/Offset
 */

- (NSString*) createExifAPP1 : (NSDictionary*) datadict;

- (void) createExifDataString : (NSDictionary*) datadict;

- (NSString*) createDataElement : (NSString*) element
              withElementData: (NSString*) data
              withExternalDataBlock: (NSDictionary*) memblock;

- (NSString*) decimalToUnsignedRational: (NSNumber *) numb
         outputNumerator: (NSNumber *) num
         outputDenominator: (NSNumber*) deno;


- (NSString*) hexStringFromData : (NSData*) data;

- (NSNumber*) numericFromHexString : (NSString *) hexstring;

@end
