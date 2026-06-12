import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/storage/trusted_devices_repository.dart';

// 1. Device Name Provider
class DeviceNameNotifier extends StateNotifier<String> {
  final SettingsRepository _settingsRepository;

  DeviceNameNotifier(this._settingsRepository) : super('') {
    state = _settingsRepository.getDeviceName();
  }

  Future<void> update(String name) async {
    await _settingsRepository.setDeviceName(name);
    state = name;
  }
}

final deviceNameProvider = StateNotifierProvider<DeviceNameNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return DeviceNameNotifier(repo);
});

// 2. Theme Mode Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settingsRepository;

  ThemeModeNotifier(this._settingsRepository) : super(ThemeMode.dark) {
    _init();
  }

  void _init() {
    final modeStr = _settingsRepository.getThemeMode();
    state = modeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await _settingsRepository.setThemeMode('light');
    } else {
      state = ThemeMode.dark;
      await _settingsRepository.setThemeMode('dark');
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repo);
});

// 3. Download Path Provider
class DownloadPathNotifier extends StateNotifier<String> {
  final SettingsRepository _settingsRepository;

  DownloadPathNotifier(this._settingsRepository) : super('') {
    _init();
  }

  Future<void> _init() async {
    state = await _settingsRepository.getDownloadPath();
  }

  Future<void> update(String path) async {
    await _settingsRepository.setDownloadPath(path);
    state = path;
  }
}

final downloadPathProvider = StateNotifierProvider<DownloadPathNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return DownloadPathNotifier(repo);
});

// 4. Auto Accept Provider
class AutoAcceptNotifier extends StateNotifier<bool> {
  final SettingsRepository _settingsRepository;

  AutoAcceptNotifier(this._settingsRepository) : super(false) {
    state = _settingsRepository.getAutoAccept();
  }

  Future<void> update(bool val) async {
    await _settingsRepository.setAutoAccept(val);
    state = val;
  }
}

final autoAcceptProvider = StateNotifierProvider<AutoAcceptNotifier, bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return AutoAcceptNotifier(repo);
});

// 5. Trusted Devices List Provider
class TrustedDevicesNotifier extends StateNotifier<List<TrustedDeviceInfo>> {
  final TrustedDevicesRepository _repository;

  TrustedDevicesNotifier(this._repository) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repository.getTrustedDevices();
  }

  Future<void> removeDevice(String deviceId) async {
    await _repository.removeTrustedDevice(deviceId);
    refresh();
  }
}

final trustedDevicesListProvider =
    StateNotifierProvider<TrustedDevicesNotifier, List<TrustedDeviceInfo>>((ref) {
  final repo = ref.watch(trustedDevicesRepositoryProvider);
  return TrustedDevicesNotifier(repo);
});
