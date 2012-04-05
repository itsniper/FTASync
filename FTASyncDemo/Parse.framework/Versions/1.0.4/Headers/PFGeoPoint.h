//
//  PFGeoPoint.h
//  Parse
//
//  Created by Henele Adams on 12/1/11.
//  Copyright (c) 2011 Parse, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 Object which may be used to embed a latitude / longitude point as the value for a key in a PFObject.
 PFObjects with a PFGeoPoint field may be queried in a geospatial manner using PFQuery's whereKey:nearGeoPoint:.
 
 This is also used as a point specifier for whereKey:nearGeoPoint: queries.
 
 Currently, object classes may only have one key associated with a GeoPoint type.
 */

@interface PFGeoPoint : NSObject<NSCopying> {
    double latitude;
    double longitude;
}

/// Latitude of point in degrees.  Valid range (-90.0, 90.0).
@property (nonatomic) double latitude;
/// Longitude of point in degrees.  Valid range (-180.0, 180.0).
@property (nonatomic) double longitude;

/*!
 Create a PFGeoPoint object.  Latitude and longitude are set to 0.0.
 @result Returns a new PFGeoPoint.
 */
+ (PFGeoPoint *)geoPoint;

/*!
 Creates a new PFGeoPoint object with the specified latitude and longitude.
 @param latitude Latitude of point in degrees.
 @param longitude Longitude of point in degrees.
 @result New point object with specified latitude and longitude.
 */
+ (PFGeoPoint *)geoPointWithLatitude:(double)latitude longitude:(double)longitude;

/*!
 Set latitude.
 @param newLatitude New latitude of point.  Valid range (-90.0, 90.0).
 */
- (void)setLatitude:(double)newLatitude;

/*!
 Get latitude.
 @result Latitude of point.
 */
- (double)latitude;

/*!
  Set longitude.
  @param newLongitude New longitude of point.  Valid range (-180.0, 180.0).
 */
- (void)setLongitude:(double)newLongitude;
/*!
  Get longitude.
  @result Longitude of point.
 */
- (double)longitude;

/*!
 Get distance in radians from this point to specified point.
 @param point PFGeoPoint location of other point.
 @result distance in radians
 */
- (double)distanceInRadiansTo:(PFGeoPoint*)point;

/*!
 Get distance in miles from this point to specified point.
 @param point PFGeoPoint location of other point.
 @result distance in miles
 */
- (double)distanceInMilesTo:(PFGeoPoint*)point;

/*!
 Get distance in kilometers from this point to specified point.
 @param point PFGeoPoint location of other point.
 @result distance in kilometers
 */
- (double)distanceInKilometersTo:(PFGeoPoint*)point;


@end
