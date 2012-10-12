//
//  CDVImageHeaderWriter.m
//  CordovaLib
//
//  Created by Lorin Beer on 2012-10-02.
//
//

#import "CDVImageHeaderWriter.h"
#include "ExifData.h"

#define IntWrap(x) [NSNumber numberWithInt:x]

#define TAGINF(tagno, typecode, components) [NSArray arrayWithObjects: tagno, typecode, components, nil]


const uint mJpegId = 0xffd8; // JPEG format marker
const uint mExifMarker = 0xffe1; // APP1 jpeg header marker
const uint mExif = 0x45786966; // ASCII 'Exif', first characters of valid exif header after size
const uint mMotorallaByteAlign = 0x4d4d; // 'MM', motorola byte align, msb first or 'sane'
const uint mIntelByteAlgin = 0x4949; // 'II', Intel byte align, lsb first or 'batshit crazy reverso world'
const uint mTiffLength = 0x2a; // after byte align bits, next to bits are 0x002a(MM) or 0x2a00(II), tiff version number


@implementation CDVImageHeaderWriter

- (id) init {

    // supported tags for exif IFD
    IFD0TagFormatDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                  //      TAGINF(@"010e", [NSNumber numberWithInt:EDT_ASCII_STRING], @0), @"ImageDescription",
                        TAGINF(@"0132", [NSNumber numberWithInt:EDT_ASCII_STRING], @20), @"DateTime",
                        TAGINF(@"010f", [NSNumber numberWithInt:EDT_ASCII_STRING], @0), @"Make",
                        TAGINF(@"0110", [NSNumber numberWithInt:EDT_ASCII_STRING], @0), @"Model",
                        TAGINF(@"0131", [NSNumber numberWithInt:EDT_ASCII_STRING], @0), @"Software",
                        TAGINF(@"011a", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"XResolution",
                        TAGINF(@"011b", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"YResolution",
                         /*
                        TAGINF(@"0112", [NSNumber numberWithInt:EDT_USHORT], @1), @"Orientation",
                        TAGINF(@"0128", [NSNumber numberWithInt:EDT_USHORT], @1), @"ResolutionUnit",
                        TAGINF(@"013e", [NSNumber numberWithInt:EDT_URATIONAL], @2), @"WhitePoint",
                        TAGINF(@"013f", [NSNumber numberWithInt:EDT_URATIONAL], @6), @"PrimaryChromaticities",
                        TAGINF(@"0211", [NSNumber numberWithInt:EDT_URATIONAL], @3), @"YCbCrCoefficients",
                        TAGINF(@"0213", [NSNumber numberWithInt:EDT_USHORT], @1), @"YCbCrPositioning",
                        TAGINF(@"0214", [NSNumber numberWithInt:EDT_URATIONAL], @6), @"ReferenceBlackWhite",
                        TAGINF(@"8298", [NSNumber numberWithInt:EDT_URATIONAL], @0), @"Copyright",
                        TAGINF(@"8769", [NSNumber numberWithInt:EDT_ULONG], @1), @"ExifOffset",
                        */
                        nil];

    // supported tages for exif subIFD
    SubIFDTagFormatDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                        TAGINF(@"829a", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"ExposureTime",
                        TAGINF(@"829d", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"FNumber",
                        TAGINF(@"8822", [NSNumber numberWithInt:EDT_USHORT], @1), @"ExposureProgram",
                        TAGINF(@"8827", [NSNumber numberWithInt:EDT_USHORT], @2), @"ISOSpeedRatings",
                          // TAGINF(@"9000", [NSNumber numberWithInt:], @), @"ExifVersion",
                          TAGINF(@"9004",[NSNumber numberWithInt:EDT_ASCII_STRING],@20), @"DateTimeDigitized",
                          TAGINF(@"9003",[NSNumber numberWithInt:EDT_ASCII_STRING],@20), @"DateTimeOriginal",
                          TAGINF(@"9207", [NSNumber numberWithInt:EDT_USHORT], @1), @"MeteringMode",
                          TAGINF(@"9209", [NSNumber numberWithInt:EDT_USHORT], @1), @"Flash",
                          TAGINF(@"920a", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"FocalLength",
                          TAGINF(@"920a", [NSNumber numberWithInt:EDT_URATIONAL], @1), @"FocalLength",
                //      TAGINF(@"9202",[NSNumber numberWithInt:EDT_URATIONAL],@1), @"ApertureValue",
                //      TAGINF(@"9203",[NSNumber numberWithInt:EDT_SRATIONAL],@1), @"BrightnessValue",
                         TAGINF(@"a001",[NSNumber numberWithInt:EDT_USHORT],@1), @"ColorSpace",
                         TAGINF(@"8822", [NSNumber numberWithInt:EDT_USHORT], @1), @"ExposureProgram",
        //              @"PixelXDimension", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a002", nil],
        //              @"PixelYDimension", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a003", nil],
        //              @"SceneType", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a301", nil],
        //              @"SensingMethod", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a217", nil],
        //              @"Sharpness", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a40A", nil],
                    // TAGINF(@"9201", [NSNumber numberWithInt:EDT_SRATIONAL], @1), @"ShutterSpeedValue",
        //              @"WhiteBalance", [[NSDictionary alloc] initWithObjectsAndKeys: @"code", @"a403", nil],
                      nil];
    return self;
}

/**
 *
 */
- (NSString*) createExifAPP1 : (NSDictionary*) datadict {
    NSString * app1;
    NSString * exif;
    // FFE1 is the APP1 Marker
    NSString * app1marker = @"ffe1";
    // SSSS size, to be determined
    // EXIF ascii characters followed by 2bytes of zeros
    NSString * exifmarker = @"457869660000";
    // Tiff header: 4d4d is motorolla byte align (big endian), 002a is hex for 422
    NSString * tiffheader = @"4d4d002a";
    //first IFD offset from the Tiff header to IFD0. Since we are writing it, we know it's address 0x08
    NSString * ifd0offset = @"00000008";
    
    exif = [self createExifIFDFromDict: [datadict objectForKey:@"{TIFF}"] withFormatDict: IFD0TagFormatDict];
    
    NSLog(@"%@",exif);
    
  /*  app1 = [[NSString alloc] initWithFormat:@"%@%04x%@%@%@%@",
                app1marker,
                ([exif length]/2)+16,
                exifmarker,
                tiffheader,
                ifd0offset,
                exif];
    
    NSLog(@"%@",app1);*/
    
    /*
     * constructing app1 segment:
     * 2 byte marker: ffe1
     * 2 byte size  : app1 size
     */
    app1 = [[NSString alloc] initWithFormat: @"%@%04x%@%@%@%@",
            app1marker,
            16+[exif length]/2,
            exifmarker,
            tiffheader,
            ifd0offset,
            exif];
    NSLog(@"%@",app1);
    return app1;
    
}

/**
 * returns hex string representing a valid exif information file directory constructed from the datadict and formatdict
 * datadict exif data entries encode into ifd
 * formatdict specifies format of data entries and allowed entries in this ifd
 */
- (NSString*) createExifIFDFromDict : (NSDictionary*) datadict withFormatDict : (NSDictionary*) formatdict {
    NSArray * datakeys = [datadict allKeys];
    NSArray * knownkeys = [IFD0TagFormatDict allKeys]; // only keys in knowkeys are considered for entry in this IFD
    NSMutableArray * ifdblock = [[NSMutableArray alloc] initWithCapacity: [datadict count]];
    NSMutableArray * ifddatablock = [[NSMutableArray alloc] initWithCapacity: [datadict count]];
    
    for (int i = 0; i < [datakeys count]; i++) {
        NSString * key = [datakeys objectAtIndex:i];
        if ([knownkeys indexOfObject: key] != NSNotFound) {
            // create new IFD entry
            NSString * entry = [self  createIFDElement: key
                                      withFormatDict: formatdict
                                      withElementData: [datadict objectForKey:key]];
            
            NSString * data = [self createIFDElementDataWithFormat: [formatdict objectForKey:key]
                                                   withData: [datadict objectForKey:key]];
            NSLog(@"%@",entry);
            if (entry) {
                [ifdblock addObject:entry];
                if(!data) {
                    [ifdblock addObject:@""];
                } else {
                    [ifddatablock addObject:data];
                }
            }
        }
    }
    //[ifdblock addObject: [[NSString alloc] initWithFormat:@"8769%@%@", @"0004",@"00000001"]];
    NSMutableString * exifstr = [[NSMutableString alloc] initWithCapacity: [ifdblock count] * 24];
    NSMutableString * dbstr = [[NSMutableString alloc] initWithCapacity: 100];
    // TIFF Header: 2 bytes byte align, 2 bytes  hex 42, 4 bytes IFD0 address, 12 bytes for every entry into ifd0
    
    int addr = 10+12*[ifddatablock count];//;8 + (12 * ([ifdblock count]+1));
    for (int i = 0; i < [ifdblock count]; i++) {

        NSString * entry = [ifdblock objectAtIndex:i];
        NSString * data = [ifddatablock objectAtIndex:i];
        
        NSLog(@"entry: %@ entry:%@", entry, data);
        NSLog(@"%d",addr);
        // check if the data fits into 4 bytes
        if( [data length] <= 8) {
            // concatenate the entry and the (4byte) data entry into the final IFD entry and append to exif ifd string
            NSLog(@"%@   %@", entry, data);
            [exifstr appendFormat : @"%@%@", entry, data];
        } else {
            [exifstr appendFormat : @"%@%08x", entry, addr];
            [dbstr appendFormat: @"%@", data]; 
            addr+= [data length] / 2;
        }
    }
    
    return [[NSString alloc] initWithFormat: @"%04x%@%@%@",
            [ifdblock count],
            exifstr,
            dbstr,
            @"00000000"
            ];
}


/**
 * Creates an exif formatted exif information file directory entry
 */
- (NSString*) createIFDElement: (NSString*) elementName withFormatDict : (NSDictionary*) formatdict withElementData : (NSString*) data  {
    NSArray * fielddata = [formatdict objectForKey: elementName];// format data of desired field
    NSLog(@"%@", [data description]);
    if (fielddata) {
        // format string @"%@%@%@%@", tag number, data format, components, value
        NSNumber * dataformat = [fielddata objectAtIndex:1];
        NSNumber * components = [fielddata objectAtIndex:2];
        if([components intValue] == 0) {
            components = [NSNumber numberWithInt: [data length] * DataTypeToWidth[[dataformat intValue]-1]];            
        }

        return [[NSString alloc] initWithFormat: @"%@%@%08x",
                                                [fielddata objectAtIndex:0], // the field code
                                                [self formatWithLeadingZeroes: @4 :dataformat], // the data type code
                                                [components intValue]]; // number of components
    }
    return NULL;
}

/*

- (void) createTagDataHelper: (NSString *) tagname withTagCode: (NSInteger) tagcode {
    NSMutableString * datastr = [NSMutableString alloc];
    [datastr appendFormat: @"%@, tagcode", tagname];
}
*/



/**
 * formatIFHElementData
 * formats the Information File Directory Data to exif format
 * @return formatted data string
 */
- (NSString*) createIFDElementDataWithFormat: (NSArray*) dataformat withData: (NSString*) data {
    NSMutableString * datastr = NULL;
    NSNumber * formatcode = [dataformat objectAtIndex:1];
    NSNumber * componentcount = [dataformat objectAtIndex:2];
            
    switch ([formatcode intValue]) {
        case EDT_UBYTE:
            break;
        case EDT_ASCII_STRING:
            datastr = [[NSMutableString alloc] init];
            for (int i = 0; i < [data length]; i++) {
                [datastr appendFormat:@"%02x",[data characterAtIndex:i]];
            }
            if ([datastr length] < 8) {
                NSString * format = [NSString stringWithFormat:@"%%0%dd", 8 - [datastr length]];
                [datastr appendFormat:format,0];
            }
            return datastr;
        case EDT_USHORT:
            return [[NSString alloc] initWithFormat : @"%@%@",
                    [self formattedHexStringFromDecimalNumber: [NSNumber numberWithInt: [data intValue]] withPlaces: @4],
                    @"00000000"];
        case EDT_ULONG:
            return @"00000000";
         //   numb = [NSNumber numberWithUnsignedLong:[data intValue]];
          //  return [NSString stringWithFormat : @"%lx", [numb longValue]];
        case EDT_URATIONAL:
            //int * numb = null;
           // [self decimalToUnsignedRational: [NSNumber numberWithDouble:[data doubleValue]]
        //                    outputNumerator: numerator
        //                  outputDenominator: denominator];
          //  long l = [numerator longValue];
         //   l = [denominator longValue];
            return @"0000000100000001";
        case EDT_SBYTE:
            
            break;
        case EDT_UNDEFINED:
            
            break;     // 8 bits
        case EDT_SSHORT:
            
            break;
        case EDT_SLONG:
            
            break;          // 32bit signed integer (2's complement)
        case EDT_SRATIONAL:
            
            break;     // 2 SLONGS, first long is numerator, second is denominator
        case EDT_SINGLEFLOAT:
            
            break;
        case EDT_DOUBLEFLOAT:
            
            break;
    }
    return datastr;
}


//======================================================================================================================

//======================================================================================================================

/**
 * creates a formatted little endian hex string from a number and width specifier
 */
- (NSString*) formattedHexStringFromDecimalNumber: (NSNumber*) numb withPlaces: (NSNumber*) width {
    NSMutableString * str = [[NSMutableString alloc] initWithCapacity:[width intValue]];
    NSString * formatstr = [[NSString alloc] initWithFormat: @"%%%@%dx", @"0", [width intValue]];
    [str appendFormat:formatstr, [numb intValue]];
    return str;
}

- (NSString*) formatWithLeadingZeroes: (NSNumber *) places: (NSNumber *) numb {
    
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
   // NSString * formatstr = [@"" stringByPaddingToLength:places withsString: @"0" ];
    NSString *formatstr = [@"" stringByPaddingToLength:[places unsignedIntegerValue] withString:@"0" startingAtIndex:0];
    [formatter setPositiveFormat:formatstr];
    
    return [formatter stringFromNumber:numb];
}

// approximate a decimal with a rational by method of continued fraction
- (void) decimalToRational: (NSNumber *) numb: (NSNumber *) numerator: (NSNumber*) denominator {
    numerator = [NSNumber numberWithLong: 1];
    denominator = [NSNumber numberWithLong: 1];
}

// approximate a decimal with an unsigned rational by method of continued fraction
- (void) decimalToUnsignedRational: (NSNumber *) numb outputNumerator: (NSNumber *) num outputDenominator: (NSNumber*) deno {
    num = [NSNumber numberWithUnsignedLong: 1];
    deno = [NSNumber numberWithUnsignedLong: 1];

    //calculate initial values
    int term = [numb intValue]; 
    double recip = 1 / [numb doubleValue];
    double error = [numb doubleValue] - term;

    // calculate inverse
    // split 

}

- (void) continuedFraction: (double) val {
    int rightside, leftside;
    [self splitDouble: val rightSide: &rightside leftSide: &leftside];
}

// split a floating point number into two integer values representing the left and right side of the decimal
- (void) splitDouble: (double) val rightSide: (int*) rightside leftSide: (int*) leftside {
    *rightside = val; // convert numb to int representation, which truncates the decimal portion
    double de = val - *rightside;
    int digits = [[NSString stringWithFormat:@"%f", de] length] - 2;
    *leftside =  de * pow(10,digits);;
}


//
- (NSString*) hexStringFromData : (NSData*) data {
    //overflow detection
    const unsigned char *dataBuffer = [data bytes];
    return [[NSString alloc] initWithFormat: @"%02x%02x",
                                        (unsigned char)dataBuffer[0],
                                        (unsigned char)dataBuffer[1]];
}

// convert a hex string to a number
- (NSNumber*) numericFromHexString : (NSString *) hexstring {
    NSScanner * scan = NULL;
    unsigned int numbuf= 0;
    
    scan = [NSScanner scannerWithString:hexstring];
    [scan scanHexInt:&numbuf];
    return [NSNumber numberWithInt:numbuf];
}

@end