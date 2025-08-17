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
  bool _isOnline = false;

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
                    bottom: 300.h,
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
    if (rideProvider.currentRide != null) {
      return _buildCurrentRideCard(rideProvider.currentRide!, user);
    } else {
      return _buildAvailableRides(rideProvider, user);
    }
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
      height: 300.h,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Rides',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<RideModel>>(
              stream: rideProvider.getAvailableRidesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final ride = snapshot.data![index];
                    return _buildRideCard(ride, rideProvider, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideModel ride, RideProvider rideProvider, user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    ride.riderName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getVehicleTypeColor(ride.vehicleType),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    ride.vehicleType.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.my_location, size: 16.sp, color: AppColors.success),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    ride.pickupAddress,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 16.sp, color: AppColors.error),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    ride.dropAddress,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${ride.fare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                CustomButton(
                  text: 'Accept',
                  width: 100.w,
                  height: 36.h,
                  onPressed: () => _acceptRide(ride, rideProvider, user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRideCard(RideModel ride, user) {
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
                Provider.of<SimpleAuthProvider>(context, listen: false).signOut();
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
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);

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
}
