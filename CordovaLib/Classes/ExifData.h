//
//  ExifData.h
//  CordovaLib
//
//  Created by Lorin Beer on 2012-10-04.
//
//

#ifndef CordovaLib_ExifData_h
#define CordovaLib_ExifData_h

typedef enum exifDataTypes {
    EDT_UBYTE = 1,      // 8 bit unsigned integer
    EDT_ASCII_STRING,   // 8 bits containing 7 bit ASCII code, null terminated
    EDT_USHORT,         // 16 bit unsigned integer
    EDT_ULONG,          // 32 bit unsigned integer
    EDT_URATIONAL,      // 2 longs, first is numerator and second is denominator
    EDT_SBYTE,
    EDT_UNDEFINED,      // 8 bits
    EDT_SSHORT,
    EDT_SLONG,          // 32bit signed integer (2's complement)
    EDT_SRATIONAL,      // 2 SLONGS, first long is numerator, second is denominator
    EDT_SINGLEFLOAT,
    EDT_DOUBLEFLOAT
} ExifDataTypes;

typedef enum formatFields {
    FF_CODE = 0,
    FF_TYPE,
    FF_COUNT
} FormatFields;

static const int DataTypeToWidth[] = {1,1,2,4,8,1,1,2,4,8,4,8};

#endif
