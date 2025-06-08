import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  List<Map<String, dynamic>> _selectedLocations = [];
  bool _isLoading = true;
  FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCityData();
    _loadSelectedLocations();
    _searchFocusNode.addListener(_handleFocusChange);
  }

  Future<void> _loadCityData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/city_data.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _allCities = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading city data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('selected_locations');

    if (locationsJson != null) {
      final List<dynamic> locations = json.decode(locationsJson);
      setState(() {
        _selectedLocations = List<Map<String, dynamic>>.from(locations);
      });
    }
  }

  Future<void> _saveSelectedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'selected_locations',
      json.encode(_selectedLocations),
    );
  }

  void _handleFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _filterCities(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCities = [];
      });
      _removeOverlay();
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredCities = _allCities.where((city) {
        final cityName = city['city']?.toString().toLowerCase() ?? '';
        final countryName = city['country']?.toString().toLowerCase() ?? '';
        return cityName.contains(lowerCaseQuery) ||
            countryName.contains(lowerCaseQuery);
      }).toList();
    });

    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox? searchBox =
        _searchContainerKey.currentContext?.findRenderObject() as RenderBox?;

    if (searchBox == null) return;

    final position = searchBox.localToGlobal(Offset.zero);
    final size = searchBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 8,
        left: position.dx,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filteredCities.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No locations found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return ListTile(
                        title: Text(city['city']),
                        subtitle: Text(city['country']),
                        onTap: () {
                          _addSelectedLocation(city);
                          _removeOverlay();
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _addSelectedLocation(Map<String, dynamic> location) {
    if (!_selectedLocations.any((loc) => loc['city'] == location['city'])) {
      setState(() {
        _selectedLocations.add(location);
        _saveSelectedLocations();
        _searchController.clear();
        _filteredCities = [];
      });
      _removeOverlay();
      _searchFocusNode.unfocus(); // Close keyboard and remove focus
    }
  }

  void _removeSelectedLocation(int index) {
    setState(() {
      _selectedLocations.removeAt(index);
      _saveSelectedLocations();
    });
  }

  @override
  void dispose() {
    _removeOverlay(); // Clear overlay if it exists
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4732F),
            Color(0xFFFBB13A),
            Color(0xFFFBB13A),
            Color(0xFFF4732F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _selectedLocations),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Box with GlobalKey
                Container(
                  key: _searchContainerKey,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterCities('');
                                _removeOverlay();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filterCities,
                    onTap: () {
                      if (_searchController.text.isNotEmpty) {
                        _showOverlay();
                      }
                      FocusScope.of(context).requestFocus(_searchFocusNode);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Locations
                Expanded(
                  child: _selectedLocations.isEmpty
                      ? const Center(
                          child: Text(
                            'No locations added yet',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _selectedLocations.length,
                          itemBuilder: (context, index) {
                            final location = _selectedLocations[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Circular minus icon button
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF4732F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                          size: 16,
                                        ),
                                        onPressed: () =>
                                            _removeSelectedLocation(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${location['city']}, ${location['country']}',
                                        style: const TextStyle(
                                          fontSize: 21,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
