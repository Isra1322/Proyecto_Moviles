import 'package:flutter/material.dart';
import '../../infrastructure/datasources/remote/address_service.dart';
import '../../infrastructure/models/address_model.dart';
import 'auth_provider.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _addressService;

  AddressProvider(this._addressService);

  ViewStatus _status = ViewStatus.initial;
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  String? _errorMessage;

  ViewStatus get status => _status;
  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ViewStatus.loading;

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _addressService.getAddresses();
      if (_addresses.isNotEmpty) {
        if (_selectedAddress == null || !_addresses.any((a) => a.id == _selectedAddress!.id)) {
          _selectedAddress = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
        } else {
          // Actualizar la instancia de _selectedAddress con la de la lista más reciente
          _selectedAddress = _addresses.firstWhere((a) => a.id == _selectedAddress!.id);
        }
      } else {
        _selectedAddress = null;
      }
      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<AddressModel?> createAddress({
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newAddress = await _addressService.createAddress(
        title: title,
        street: street,
        city: city,
        stateOrProvince: stateOrProvince,
        postalCode: postalCode,
        reference: reference,
        phone: phone,
        isDefault: isDefault,
      );

      if (newAddress.isDefault) {
        _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
      }

      _addresses.insert(0, newAddress);
      _selectedAddress = newAddress;
      _status = ViewStatus.success;
      notifyListeners();
      return newAddress;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<AddressModel?> updateAddress({
    required String id,
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _addressService.updateAddress(
        id: id,
        title: title,
        street: street,
        city: city,
        stateOrProvince: stateOrProvince,
        postalCode: postalCode,
        reference: reference,
        phone: phone,
        isDefault: isDefault,
      );

      final index = _addresses.indexWhere((a) => a.id == id);
      if (index != -1) {
        if (updated.isDefault) {
          _addresses = _addresses.map((a) => a.id == id ? updated : a.copyWith(isDefault: false)).toList();
        } else {
          _addresses[index] = updated;
        }
      }

      if (_selectedAddress?.id == id) {
        _selectedAddress = updated;
      }

      _status = ViewStatus.success;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final success = await _addressService.deleteAddress(id);
      if (success) {
        final wasDeletedDefault = _addresses.any((a) => a.id == id && a.isDefault);
        _addresses.removeWhere((a) => a.id == id);

        if (wasDeletedDefault && _addresses.isNotEmpty) {
          _addresses[0] = _addresses[0].copyWith(isDefault: true);
        }

        if (_selectedAddress?.id == id) {
          _selectedAddress = _addresses.isNotEmpty
              ? _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first)
              : null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDefaultAddress(String id) async {
    try {
      final updated = await _addressService.setDefaultAddress(id);
      _addresses = _addresses.map((a) => a.id == id ? updated : a.copyWith(isDefault: false)).toList();
      _selectedAddress = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    _status = ViewStatus.initial;
    _addresses = [];
    _selectedAddress = null;
    _errorMessage = null;
    notifyListeners();
  }
}
