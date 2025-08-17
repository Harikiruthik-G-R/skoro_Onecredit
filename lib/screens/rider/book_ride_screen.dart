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
import '../../widgets/custom_text_field.dart';
import '../../models/ride_model.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  VehicleType _selectedVehicleType = VehicleType.car;
  double _estimatedFare = 0.0;
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentLocation();
    });
  }

  Future<void> _initializeCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null &&
        locationProvider.currentAddress != null) {
      _pickupLocation = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
      _pickupController.text = locationProvider.currentAddress!;
      _updateMap();
    }
  }

  void _updateMap() {
    setState(() {
      _markers.clear();

      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (_dropLocation != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('drop'),
            position: _dropLocation!,
            infoWindow: InfoWindow(title: 'Drop Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    });

    if (_pickupLocation != null && _dropLocation != null) {
      _calculateFare();
      _fitMarkersOnMap();
    } else if (_pickupLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLocation!, zoom: 15.0),
        ),
      );
    }
  }

  void _calculateFare() {
    if (_pickupLocation != null && _dropLocation != null) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      _distance = locationProvider.calculateDistance(
        _pickupLocation!,
        _dropLocation!,
      );

      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      _estimatedFare = rideProvider.calculateFare(
        _distance,
        _selectedVehicleType,
      );

      setState(() {});
    }
  }

  void _fitMarkersOnMap() {
    if (_mapController != null &&
        _pickupLocation != null &&
        _dropLocation != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _pickupLocation!.latitude < _dropLocation!.latitude
              ? _pickupLocation!.latitude
              : _dropLocation!.latitude,
          _pickupLocation!.longitude < _dropLocation!.longitude
              ? _pickupLocation!.longitude
              : _dropLocation!.longitude,
        ),
        northeast: LatLng(
          _pickupLocation!.latitude > _dropLocation!.latitude
              ? _pickupLocation!.latitude
              : _dropLocation!.latitude,
          _pickupLocation!.longitude > _dropLocation!.longitude
              ? _pickupLocation!.longitude
              : _dropLocation!.longitude,
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Ride'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/rider-home'),
        ),
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _pickupLocation ?? LatLng(28.6139, 77.2090),
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Booking Form Section
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(20.w),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Fields
                    CustomTextField(
                      controller: _pickupController,
                      label: 'Pickup Location',
                      prefixIcon: Icons.my_location,
                      readOnly: true,
                      onTap: () async {
                        final result = await _selectLocationOnMap('pickup');
                        if (result != null) {
                          _pickupLocation = result;
                          final address = await Provider.of<LocationProvider>(
                            context,
                            listen: false,
                          ).getAddressFromCoordinates(result);
                          _pickupController.text =
                              address ?? 'Unknown location';
                          _updateMap();
                        }
                      },
                    ),

                    SizedBox(height: 16.h),

                    CustomTextField(
                      controller: _dropController,
                      label: 'Drop Location',
                      prefixIcon: Icons.location_on,
                      readOnly: true,
                      onTap: () async {
                        final result = await _selectLocationOnMap('drop');
                        if (result != null) {
                          _dropLocation = result;
                          final address = await Provider.of<LocationProvider>(
                            context,
                            listen: false,
                          ).getAddressFromCoordinates(result);
                          _dropController.text = address ?? 'Unknown location';
                          _updateMap();
                        }
                      },
                    ),

                    if (_distance > 0) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            SizedBox(width: 8.w),
                            Text(
                              'Distance: ${(_distance / 1000).toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Vehicle Type Selection
                    Text(
                      'Choose Vehicle Type',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildVehicleTypeCard(
                            VehicleType.auto,
                            'Auto',
                            Icons.directions_car,
                            '₹30 base + ₹12/km',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildVehicleTypeCard(
                            VehicleType.car,
                            'Car',
                            Icons.car_rental,
                            '₹50 base + ₹15/km',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildVehicleTypeCard(
                            VehicleType.van,
                            'Van',
                            Icons.airport_shuttle,
                            '₹80 base + ₹20/km',
                          ),
                        ),
                      ],
                    ),

                    if (_estimatedFare > 0) ...[
                      SizedBox(height: 20.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Estimated Fare',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '₹${_estimatedFare.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Book Ride Button
                    Consumer<RideProvider>(
                      builder: (context, rideProvider, child) {
                        return CustomButton(
                          text: 'Book Ride',
                          onPressed: _canBookRide() && !rideProvider.isLoading
                              ? _bookRide
                              : null,
                          isLoading: rideProvider.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeCard(
    VehicleType type,
    String name,
    IconData icon,
    String pricing,
  ) {
    final isSelected = _selectedVehicleType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
        _calculateFare();
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? AppColors.primary : AppColors.grey600,
            ),
            SizedBox(height: 4.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              pricing,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _canBookRide() {
    return _pickupLocation != null &&
        _dropLocation != null &&
        _pickupController.text.isNotEmpty &&
        _dropController.text.isNotEmpty;
  }

  Future<void> _bookRide() async {
    if (!_canBookRide()) return;

    final authProvider = Provider.of<SimpleAuthProvider>(
      context,
      listen: false,
    );
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    final user = authProvider.currentUser!;

    final success = await rideProvider.requestRide(
      rider: user,
      pickupLocation: _pickupLocation!,
      dropLocation: _dropLocation!,
      pickupAddress: _pickupController.text,
      dropAddress: _dropController.text,
      vehicleType: _selectedVehicleType,
      distance: _distance,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride requested successfully! Finding a driver...'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/rider-home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.errorMessage ?? 'Failed to book ride'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<LatLng?> _selectLocationOnMap(String type) async {
    return showDialog<LatLng>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${type == 'pickup' ? 'Pickup' : 'Drop'} Location'),
        content: Container(
          height: 300.h,
          width: double.maxFinite,
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {},
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? LatLng(28.6139, 77.2090),
              zoom: 15.0,
            ),
            onTap: (LatLng location) {
              Navigator.pop(context, location);
            },
            markers: {
              Marker(
                markerId: MarkerId('selected'),
                position: _pickupLocation ?? LatLng(28.6139, 77.2090),
              ),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }
}
