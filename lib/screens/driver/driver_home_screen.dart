import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/ride_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/ride_model.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isOnline = true; // Start online by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentPosition != null) {
      _updateMapLocation(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
    }
  }

  void _updateMapLocation(double latitude, double longitude) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId('driver_location'),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude, longitude), zoom: 15.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<SimpleAuthProvider, LocationProvider, RideProvider>(
        builder:
            (context, authProvider, locationProvider, rideProvider, child) {
              final user = authProvider.currentUser;

              if (user == null) {
                return Center(child: CircularProgressIndicator());
              }

              return Stack(
                children: [
                  // Google Maps
                  GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      locationProvider.setMapController(controller);
                    },
                    initialCameraPosition: CameraPosition(
                      target: locationProvider.currentPosition != null
                          ? LatLng(
                              locationProvider.currentPosition!.latitude,
                              locationProvider.currentPosition!.longitude,
                            )
                          : LatLng(28.6139, 77.2090), // Default to Delhi
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Top App Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              // Profile Avatar
                              GestureDetector(
                                onTap: _showProfileMenu,
                                child: CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'D',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 12.w),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver: ${user.name}',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8.w,
                                          height: 8.h,
                                          decoration: BoxDecoration(
                                            color: _isOnline
                                                ? AppColors.success
                                                : AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          _isOnline ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: _isOnline
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Online/Offline Toggle
                              Switch(
                                value: _isOnline,
                                onChanged: (value) {
                                  setState(() {
                                    _isOnline = value;
                                  });
                                },
                                activeColor: AppColors.success,
                              ),

                              // Temporary cleanup button
                              IconButton(
                                onPressed: () async {
                                  final rideProvider =
                                      Provider.of<RideProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await rideProvider.cleanupTestRides();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Test rides cleaned up!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.cleaning_services,
                                  color: AppColors.error,
                                  size: 24.w,
                                ),
                                tooltip: 'Clean up test data',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Available Rides or Current Ride
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _isOnline
                          ? _buildOnlineContent(rideProvider, user)
                          : _buildOfflineContent(),
                    ),
                  ),

                  // My Location Button
                  Positioned(
                    bottom: 520.h, // Adjusted for increased container height
                    right: 16.w,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _getCurrentLocation,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.my_location, color: AppColors.primary),
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildOnlineContent(RideProvider rideProvider, user) {
    return StreamBuilder<RideModel?>(
      stream: rideProvider.getDriverCurrentRideStream(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildCurrentRideCard(snapshot.data!, user, rideProvider);
        } else {
          return _buildAvailableRides(rideProvider, user);
        }
      },
    );
  }

  Widget _buildOfflineContent() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.power_settings_new, size: 48.sp, color: AppColors.grey500),
          SizedBox(height: 16.h),
          Text(
            'You\'re Offline',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Turn on to start receiving ride requests',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildAvailableRides(RideProvider rideProvider, user) {
    return Container(
      height: 500.h, // Increased height to accommodate ride cards
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Rides',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.primary),
                onPressed: () {
                  // Force refresh the stream
                  setState(() {});
                },
              ),
            ],
          ),
          SizedBox(height: 12.h), // Reduced spacing
          Expanded(
            child: StreamBuilder<List<RideModel>>(
              stream: rideProvider.getAvailableRidesStream(),
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}');
                print('Has data: ${snapshot.hasData}');
                print('Data length: ${snapshot.data?.length ?? 0}');
                print('Error: ${snapshot.error}');

                // Show error if there's an issue
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48.sp, color: AppColors.error),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading rides',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show data if available
                if (snapshot.hasData) {
                  final rides = snapshot.data!;
                  print('UI: Rendering ${rides.length} rides');

                  // Show message when no rides are available
                  if (rides.isEmpty) {
                    print('UI: No rides to display - rides list is empty');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 48.sp,
                            color: AppColors.grey500,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No rides available',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Waiting for ride requests...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Refresh
                            },
                            child: Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show the list of available rides
                  print('UI: Building ListView with ${rides.length} rides');
                  print(
                    'UI: Container height is 500.h, available space for ListView',
                  );
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      physics:
                          BouncingScrollPhysics(), // Added physics for better scrolling
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        print(
                          'UI: Building ride card for ${ride.riderName} - ${ride.pickupAddress}',
                        );
                        print(
                          'UI: Ride card index: $index of ${rides.length - 1}',
                        );
                        return _buildRideCard(ride, rideProvider, user);
                      },
                    ),
                  );
                }

                // Show loading indicator only when there's no data yet
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading available rides...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride, RideProvider rideProvider, user) {
    print('UI: _buildRideCard called for ride ${ride.id} - ${ride.riderName}');

    try {
      // Calculate time since request
      final timeDiff = DateTime.now().difference(ride.requestedAt);
      final timeAgo = timeDiff.inMinutes < 1
          ? 'Just now'
          : '${timeDiff.inMinutes}m ago';

      print('UI: Time calculated for ${ride.riderName}: $timeAgo');

      // Calculate approximate distance from coordinates
      LocationProvider? locationProvider;
      double distance = 0.0;

      try {
        locationProvider = Provider.of<LocationProvider>(
          context,
          listen: false,
        );
        distance = locationProvider.calculateDistance(
          ride.pickupLocation,
          ride.dropLocation,
        );
        print(
          'UI: Distance calculated for ${ride.riderName}: ${(distance / 1000).toStringAsFixed(1)} km',
        );
      } catch (e) {
        print('UI: Error calculating distance for ${ride.riderName}: $e');
        distance = 5000.0; // Default 5km if calculation fails
      }

      print(
        'UI: Building card widget for ${ride.riderName} with fare ₹${ride.fare}',
      );

      return Card(
        margin: EdgeInsets.only(bottom: 12.h),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppColors.primary.withOpacity(0.02)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with rider name and vehicle type
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.riderName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getVehicleTypeColor(ride.vehicleType),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        ride.vehicleType
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Pickup location
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        ride.pickupAddress,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Dotted line
                Container(
                  margin: EdgeInsets.only(left: 4.w),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: 2.w,
                        height: 4.h,
                        margin: EdgeInsets.symmetric(vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.grey400,
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // Drop location
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        ride.dropAddress,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Distance and fare info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(distance / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Fare',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${ride.fare.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Accept Ride',
                    height: 44.h,
                    onPressed: () => _acceptRide(ride, rideProvider, user),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('UI: Error building ride card for ${ride.riderName}: $e');
      // Return a simple error widget if card building fails
      return Card(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text('Error loading ride card for ${ride.riderName}'),
        ),
      );
    }
  }

  Widget _buildCurrentRideCard(
    RideModel ride,
    user,
    RideProvider rideProvider,
  ) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Ride',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        ride.riderName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getRideStatusColor(ride.status),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getRideStatusText(ride.status),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text('Pickup: ${ride.pickupAddress}'),
                SizedBox(height: 4.h),
                Text('Drop: ${ride.dropAddress}'),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(
                      'Fare: ₹${ride.fare.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Spacer(),
                    // Cancel button for active rides
                    if (ride.status == RideStatus.accepted ||
                        ride.status == RideStatus.inProgress)
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ElevatedButton(
                          onPressed: () =>
                              _showDriverCancelDialog(ride, rideProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            minimumSize: Size(70.w, 36.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    if (ride.status == RideStatus.accepted)
                      CustomButton(
                        text: 'Start Trip',
                        width: 100.w,
                        height: 36.h,
                        onPressed: () =>
                            _updateRideStatus(ride.id, RideStatus.inProgress),
                      )
                    else if (ride.status == RideStatus.inProgress)
                      CustomButton(
                        text: 'Complete',
                        width: 100.w,
                        height: 36.h,
                        onPressed: () =>
                            _updateRideStatus(ride.id, RideStatus.completed),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getVehicleTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.auto:
        return AppColors.warning;
      case VehicleType.car:
        return AppColors.primary;
      case VehicleType.van:
        return AppColors.info;
    }
  }

  Color _getRideStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return AppColors.info;
      case RideStatus.driverArriving:
        return AppColors.warning;
      case RideStatus.inProgress:
        return AppColors.success;
      case RideStatus.completed:
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  String _getRideStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.driverArriving:
        return 'Arriving';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Future<void> _acceptRide(
    RideModel ride,
    RideProvider rideProvider,
    user,
  ) async {
    final success = await rideProvider.acceptRide(ride.id, user);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.errorMessage ?? 'Failed to accept ride'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateRideStatus(String rideId, RideStatus status) async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final success = await rideProvider.updateRideStatus(rideId, status);

    if (success) {
      String message = '';
      switch (status) {
        case RideStatus.inProgress:
          message = 'Trip started!';
          break;
        case RideStatus.completed:
          message = 'Trip completed!';
          break;
        default:
          message = 'Status updated!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );

      if (status == RideStatus.completed) {
        rideProvider.clearCurrentRide();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.errorMessage ?? 'Failed to update status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                _showRideHistory();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<SimpleAuthProvider>(
                  context,
                  listen: false,
                ).signOut();
                context.go('/user-type');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRideHistory() {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final authProvider = Provider.of<SimpleAuthProvider>(
      context,
      listen: false,
    );

    rideProvider.loadDriverRides(authProvider.currentUser!.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Text(
                'My Rides',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: Consumer<RideProvider>(
                  builder: (context, rideProvider, child) {
                    if (rideProvider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (rideProvider.driverRides.isEmpty) {
                      return Center(child: Text('No rides yet'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: rideProvider.driverRides.length,
                      itemBuilder: (context, index) {
                        final ride = rideProvider.driverRides[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8.h),
                          child: ListTile(
                            leading: Icon(Icons.local_taxi),
                            title: Text(
                              '${ride.riderName} • ${ride.dropAddress}',
                            ),
                            subtitle: Text(
                              '₹${ride.fare.toStringAsFixed(0)} • ${ride.requestedAt.day}/${ride.requestedAt.month}',
                            ),
                            trailing: Text(_getRideStatusText(ride.status)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverCancelDialog(RideModel ride, RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Ride'),
        content: Text(
          'Are you sure you want to cancel this ride? The rider will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await rideProvider.cancelRide(
                ride.id,
                'driver',
                reason: 'Cancelled by driver',
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ride cancelled successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      rideProvider.errorMessage ?? 'Failed to cancel ride',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
