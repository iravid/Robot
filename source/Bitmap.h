//
//  Bitmap.h
//  Robot
//
//  Created by Itamar Ravid on 16/8/14.
//
//

#ifndef __Robot__Bitmap__
#define __Robot__Bitmap__

#include <string>


// A wrapper for Bitmaps. Handles loading of image files using stb_image.h.
class Bitmap {
public:
    // Represents channels per pixel and channel order. Each channel is an unsigned char.
    enum Format {
        Format_Grayscale = 1, /* One channel - grayscale */
        Format_GrayscaleAlpha, /* Grayscale and alpha */
        Format_RGB, /* Red/green/blue */
        Format_RGBA /* Red/green/blue/alpha */
    };
    
    // Creates a new Bitmap
    Bitmap(unsigned width, unsigned height, Format format, const unsigned char *pixels = nullptr);
    ~Bitmap();
    
    // Loads a bitmap from a file
    static Bitmap bitmapFromFile(std::string path);
    
    unsigned width() const;
    unsigned height() const;
    Format format() const;
    
    // Returns a pointer to the raw pixel data. The pixels are saved in a column-major format.
    unsigned char *pixelBuffer() const;
    
    // Returns a pointer to the pixel in the specified coordinates.
    unsigned char *getPixel(unsigned column, unsigned row) const;
    
    // Sets the pixel at the specified coordinates.
    void setPixel(unsigned column, unsigned row, const unsigned char *pixel);
    
    // Flips image vertically.
    void flipVertically();
    
    // Rotates image 90 deg. counter-clockwise.
    void rotate90CounterClockwise();
    
    /*
     Copies a rectangular area from the given source bitmap into this bitmap.
     
     If srcCol, srcRow, width, and height are all zero, the entire source
     bitmap will be copied (full width and height).
     
     If the source bitmap has a different format to the destination bitmap,
     the pixels will be converted to match the destination format.
     
     Will throw and exception if the source and destination bitmaps are the
     same, and the source and destination rectangles overlap. If you want to
     copy a bitmap onto itself, then make a copy of the bitmap first.
     */
    void copyRectFromBitmap(const Bitmap& src,
                            unsigned srcCol,
                            unsigned srcRow,
                            unsigned destCol,
                            unsigned destRow,
                            unsigned width,
                            unsigned height);
    
    // Copy constructor
    Bitmap(const Bitmap& other);
    
    // Assignment operator
    Bitmap& operator = (const Bitmap& other);
    
private:
    Format _format;
    unsigned _width;
    unsigned _height;
    unsigned char* _pixels;
    
    void _set(unsigned width, unsigned height, Format format, const unsigned char* pixels);
    static void _getPixelOffset(unsigned col, unsigned row, unsigned width, unsigned height, Format format);
};

#endif /* defined(__Robot__Bitmap__) */
