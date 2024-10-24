import 'dart:async';
import 'dart:developer';
//import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
//import 'package:logging/logging.dart';


class HeartBpmService
{
  final CentralManager _manager;
  //late final StreamSubscription _stateChangedSubscription;
  late final StreamSubscription _discoveredSubscription;

  final String _deviceName = "Polar Sense D8C5F924";
  final String _heartRateServiceUuid = "0000180d-0000-1000-8000-00805f9b34fb".toLowerCase(); // 0x180d "180D"
  final String _heartRateMeasurementUuid = "00002a37-0000-1000-8000-00805f9b34fb".toLowerCase(); // 0x2A37 "2A37"
  
  Peripheral? _peripheral;
  GATTCharacteristic? _heartRateCharacteristic;

  bool _connected = false;
  bool _discovering = false;
  Completer<bool> _connectingResult = Completer<bool>();

  int _lastBpm = 0;
  
  HeartBpmService()
    : _manager = CentralManager()
  {
    _discoveredSubscription = _manager.discovered.listen((eventArgs) {
      final peripheral = eventArgs.peripheral;
      if (eventArgs.advertisement.name == _deviceName && !_connected)
      {
        _peripheral = peripheral;
        stopDiscovery();

        _manager.connect(peripheral);
      }
    });

    _manager.connectionStateChanged.listen((eventArgs) {
      if (eventArgs.peripheral != _peripheral) {
        return;
      }
      if (eventArgs.state == ConnectionState.connected) {
        _discoverHeartRateService();
      } else {
        if (_connected)
        {
          _connected = false;
          log("FIND ME disconnected from $_deviceName");
        }
        _connectingResult.complete(false);
        _connectingResult = Completer<bool>();
      }
    });

  }

  Future<void> _discoverHeartRateService() async {
    final services = await _manager.discoverGATT(_peripheral!);
    for (var service in services) {
      var serviceUuid = service.uuid.toString().toLowerCase();
      if (serviceUuid == _heartRateServiceUuid) {
        final characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          var characteristicUuid = characteristic.uuid.toString().toLowerCase();
          if (characteristicUuid == _heartRateMeasurementUuid) {
            _heartRateCharacteristic = characteristic;
            _subscribeToHeartRateNotifications();
            break;
          }
        }
      }
    }
  }

  void _subscribeToHeartRateNotifications() {
    if (_heartRateCharacteristic != null) {
      _manager.setCharacteristicNotifyState(
        _peripheral!,
        _heartRateCharacteristic!,
        state: true,
      );
      _manager.characteristicNotified.listen((eventArgs) {
        if (eventArgs.characteristic == _heartRateCharacteristic) {
          _processHeartRateData(eventArgs.value);
        }
      });
    }
  }

  void _processHeartRateData(Uint8List data) {
    if (!_connected)
    {
      _connected = true;
      _connectingResult.complete(true);
      _connectingResult = Completer<bool>();

      log("FIND ME connected to $_deviceName");
    }

    bool isShort = (data[0] & 0x01) == 0;
    int bpm = isShort ? data[1] : (data[2] << 8) | data[1];
    //log("Heart Rate: $bpm bpm");

    _lastBpm = bpm;
  }

  Future<bool> connect() async {
    if (_connected) {
      return true;
    }

    if (_discovering) {
      return _connectingResult.future;
    }

    _discovering = true;
    _connected = false;

    Future.delayed(const Duration(seconds: 20), (){
      if (!_connected) {
        _connectingResult.complete(false);
        _connectingResult = Completer<bool>();
        stopDiscovery();
      }
    });

    await _manager.startDiscovery();

    return _connectingResult.future;
  }

  Future<void> stopDiscovery() async {
    if (!_discovering) {
      return;
    }

    await _manager.stopDiscovery();
    _discovering = false;
  }

  int getBpm()
  {
    if (!_connected)
    {
      return - 1;
    }
    
    return _lastBpm;
  }
}